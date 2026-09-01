#!/usr/bin/env python3
import os
import time
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed

import ollama
import pandas as pd
from tqdm.auto import tqdm

# -------------------------------------------------------------------
# CONFIG
# -------------------------------------------------------------------
INPUT_PATH = "WOS_unique_orgs_firms.parquet"
OUTPUT_CSV = "WOS_unique_orgs_firms_filtered.csv"
MODEL = "llama3.3:70b"

# Public default: use a local Ollama server.
# Set OLLAMA_HOSTS to a comma-separated list of endpoint URLs for parallel hosts.
def _load_ollama_hosts():
    host_text = os.environ.get("OLLAMA_HOSTS", os.environ.get("OLLAMA_HOST", "http://localhost:11434"))
    cap = int(os.environ.get("OLLAMA_HOST_CAP", "4"))
    return [(f"ollama-{i}", url.strip(), cap) for i, url in enumerate(host_text.split(","), 1) if url.strip()]

HOST_CONFIGS = _load_ollama_hosts()

CHECKPOINT_EVERY = 1000
MAX_WORKERS = sum(cap for _, _, cap in HOST_CONFIGS)
RETRIES = 2
BACKOFF_BASE = 1.5
KEEP_ALIVE = "2h"
TEMPERATURE = 0.0

# -------------------------------------------------------------------
# SYSTEM PROMPT (HQ COUNTRY MATCH: 0/1)
# -------------------------------------------------------------------
SYSTEM_PROMPT = """
You are a classifier that receives an input string containing an organization name,
optionally followed by a location (affiliation). Examples:
- "Facebook"
- "Facebook Shanghai"
- "Siemens (Beijing)"
- "Huawei California"

Task:
Decide whether the affiliation (if present) is located in the SAME COUNTRY as the
organization's GLOBAL HEADQUARTERS.

Output rules:
- Return "0" if the location is clearly in a DIFFERENT COUNTRY than the headquarters.
- Return "1" in all other cases:
  - if the string appears to contain only the organization name (no clear location),
  - if the location appears to be in the same country as the headquarters,
  - or if you are uncertain.

Formatting rules:
- Output only a single character: "0" or "1".
- No words, explanations, punctuation, or extra text.

Examples:
- "Facebook" -> 1         (no explicit location, assume HQ or same country)
- "Huawei" -> 1           (no explicit location)
- "Facebook Shanghai" -> 0   (Meta/Facebook HQ in United States; Shanghai in China)
- "Huawei California" -> 0   (Huawei HQ in China; California in United States)
- "Siemens (Beijing)" -> 0   (Siemens HQ in Germany; Beijing in China)
- "Siemens Munich" -> 1      (Munich is in Germany)
""".strip()

# -------------------------------------------------------------------
# Host wrapper with semaphore
# -------------------------------------------------------------------
class Host:
    def __init__(self, name: str, url: str, cap: int):
        self.name = name
        self.client = ollama.Client(host=url)
        self.sem = threading.Semaphore(cap)
        self.inflight = 0
        self.lock = threading.Lock()

    def acquire(self):
        self.sem.acquire()
        with self.lock:
            self.inflight += 1

    def release(self):
        with self.lock:
            self.inflight -= 1
        self.sem.release()


def warmup_host(host: Host):
    try:
        host.client.chat(
            model=MODEL,
            messages=[{"role": "user", "content": "warmup"}],
            options={"temperature": 0, "num_predict": 8},
            keep_alive=KEEP_ALIVE,
        )
    except Exception:
        pass


# -------------------------------------------------------------------
# Core model call
# -------------------------------------------------------------------
def call_with_retries(fn, *args, **kwargs):
    last = None
    for attempt in range(RETRIES + 1):
        try:
            return fn(*args, **kwargs)
        except Exception as e:
            last = e
            if attempt < RETRIES:
                time.sleep(BACKOFF_BASE * (2 ** attempt))
    raise RuntimeError(f"Failed after retries: {last}")


def call_ollama_hq_match(host: Host, org_str) -> str:
    """
    Classify a single 'organization [+ optional location]' string into:
    '1' = same HQ country / org-only / uncertain
    '0' = clear cross-country case.

    All entries are sent to the LLM (no local filtering).
    """
    # Normalize to string; treat missing as empty string (will go to model)
    if org_str is None or (isinstance(org_str, float) and pd.isna(org_str)):
        org_str = ""

    text = str(org_str)

    host.acquire()
    try:
        def _do_call():
            resp = host.client.chat(
                model=MODEL,
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {
                        "role": "user",
                        "content": f'Input: "{text}"\nOutput:',
                    },
                ],
                options={"temperature": TEMPERATURE},
                keep_alive=KEEP_ALIVE,
            )
            return resp

        resp = call_with_retries(_do_call)
        content = (resp.get("message", {}).get("content") or "").strip()

        if not content:
            # No answer → default to 1 (do not over-flag as cross-country)
            return "1"

        # First non-whitespace char
        first = content[0]
        if first in {"0", "1"}:
            return first

        # Or first line trimmed
        content_line = content.splitlines()[0].strip()
        if content_line in {"0", "1"}:
            return content_line

        # Any weird response → default to 1
        return "1"
    finally:
        host.release()


# -------------------------------------------------------------------
# Classification over a list of row indices
# -------------------------------------------------------------------
def classify_indices(df, indices, hosts, pbar):
    # Ensure output column exists
    if "hq_match" not in df.columns:
        df["hq_match"] = pd.NA

    to_process = df.loc[indices]
    to_process = to_process[to_process["hq_match"].isna()]

    if to_process.empty:
        return 0

    print(f"[INFO] Processing {len(to_process)} rows...")

    processed_count = 0

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = {}
        rows = list(to_process.iterrows())
        n_hosts = len(hosts)

        for i, (idx, row) in enumerate(rows):
            org_str = row["organization"]
            host = hosts[i % n_hosts]
            fut = executor.submit(call_ollama_hq_match, host, org_str)
            futures[fut] = idx

        for fut in as_completed(futures):
            idx = futures[fut]
            try:
                label = fut.result()
            except Exception as e:
                print(f"[ERROR] Failed for index {idx}: {e}")
                # On error, conservative: not flagged as cross-country
                label = "1"
            df.at[idx, "hq_match"] = label
            processed_count += 1
            pbar.update(1)

    return processed_count


# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------
def main():
    df = pd.read_parquet(INPUT_PATH)

    if "organization" not in df.columns:
        raise ValueError("Expected column 'organization' in parquet file.")

    # Resume support
    try:
        existing = pd.read_csv(OUTPUT_CSV)
        if len(existing) == len(df):
            print("[INFO] Resuming from existing CSV...")
            existing.index = df.index
            df = existing
        else:
            print("[WARN] CSV length mismatch. Ignoring saved file.")
    except FileNotFoundError:
        print("[INFO] No existing CSV. Starting fresh.")

    if "hq_match" not in df.columns:
        df["hq_match"] = pd.NA

    # Warm hosts
    hosts = [Host(name, url, cap) for (name, url, cap) in HOST_CONFIGS]
    for h in hosts:
        print(f"[INFO] Warming up host {h.name} ({h.client._client.base_url})")
        warmup_host(h)

    # Find missing rows
    mask = df["hq_match"].isna()
    unprocessed = df.index[mask].tolist()
    total_missing = len(unprocessed)
    total_rows = len(df)

    print(f"[INFO] Total rows: {total_rows}")
    print(f"[INFO] Already processed: {total_rows - total_missing}")
    print(f"[INFO] Remaining: {total_missing}")

    if total_missing == 0:
        print("[DONE] Nothing to do.")
        return

    with tqdm(total=total_missing, desc="Classifying HQ match", unit="row") as pbar:
        for offset in range(0, total_missing, CHECKPOINT_EVERY):
            chunk = unprocessed[offset: offset + CHECKPOINT_EVERY]

            classify_indices(df, chunk, hosts, pbar)

            df.to_csv(OUTPUT_CSV, index=False)
            print(f"[INFO] Saved progress at {offset + len(chunk)} / {total_missing}")

    print("[DONE] All rows processed and saved.")


if __name__ == "__main__":
    main()
