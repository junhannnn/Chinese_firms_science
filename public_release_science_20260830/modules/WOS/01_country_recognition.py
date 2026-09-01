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
INPUT_PATH = "WOS_unique_orgs.parquet"
OUTPUT_CSV = "01_WOS_unique_orgs_with_country.csv"
MODEL = "llama3.3:70b"

# Public default: use a local Ollama server.
# Set OLLAMA_HOSTS to a comma-separated list of endpoint URLs for parallel hosts.
def _load_ollama_hosts():
    host_text = os.environ.get("OLLAMA_HOSTS", os.environ.get("OLLAMA_HOST", "http://localhost:11434"))
    cap = int(os.environ.get("OLLAMA_HOST_CAP", "4"))
    return [(f"ollama-{i}", url.strip(), cap) for i, url in enumerate(host_text.split(","), 1) if url.strip()]

HOST_CONFIGS = _load_ollama_hosts()

CHECKPOINT_EVERY = 1000          # save every 1000 processed rows
MAX_WORKERS = sum(cap for _, _, cap in HOST_CONFIGS)
RETRIES = 2
BACKOFF_BASE = 1.5
KEEP_ALIVE = "2h"
TEMPERATURE = 0.0

# -------------------------------------------------------------------
# SYSTEM PROMPT
# -------------------------------------------------------------------
SYSTEM_PROMPT = """
You classify organization and affiliation text into a country.
Return only the ISO 3166-1 alpha-2 country code (two uppercase letters).

Rules:
- Output must contain exactly two uppercase letters.
- If the country cannot be determined, return "UN".
- Do not include explanations, punctuation, spaces, line breaks, or any other text.
- If multiple countries are mentioned, return the most relevant one only.
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


def call_ollama_country(host: Host, org: str) -> str:
    if org is None or (isinstance(org, float) and pd.isna(org)):
        return "UN"

    host.acquire()
    try:
        def _do_call():
            resp = host.client.chat(
                model=MODEL,
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {
                        "role": "user",
                        "content": f"Affiliation / organization:\n{org}\n\nCountry code:",
                    },
                ],
                options={"temperature": TEMPERATURE},
                keep_alive=KEEP_ALIVE,
            )
            return resp

        resp = call_with_retries(_do_call)
        content = (resp.get("message", {}).get("content") or "").strip()
        code = content.splitlines()[0].strip().upper()

        if len(code) == 2 and code.isalpha():
            return code
        return "UN"
    finally:
        host.release()


# -------------------------------------------------------------------
# Classification over a list of row indices
# -------------------------------------------------------------------
def classify_indices(df, indices, hosts, pbar):
    if "country" not in df.columns:
        df["country"] = pd.NA

    to_process = df.loc[indices]
    to_process = to_process[to_process["country"].isna()]

    if to_process.empty:
        return 0

    print(f"[INFO] Processing {len(to_process)} rows...")

    processed_count = 0

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = {}
        rows = list(to_process.iterrows())
        n_hosts = len(hosts)

        for i, (idx, row) in enumerate(rows):
            org = row["organization"]
            host = hosts[i % n_hosts]
            fut = executor.submit(call_ollama_country, host, org)
            futures[fut] = idx

        for fut in as_completed(futures):
            idx = futures[fut]
            try:
                code = fut.result()
            except Exception as e:
                print(f"[ERROR] Failed for index {idx}: {e}")
                code = "UN"
            df.at[idx, "country"] = code
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

    # resume support
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

    if "country" not in df.columns:
        df["country"] = pd.NA

    # warm hosts
    hosts = [Host(name, url, cap) for (name, url, cap) in HOST_CONFIGS]
    for h in hosts:
        print(f"[INFO] Warming up host {h.name} ({h.client._client.base_url})")
        warmup_host(h)

    # find missing rows
    mask = df["country"].isna()
    unprocessed = df.index[mask].tolist()
    total_missing = len(unprocessed)
    total_rows = len(df)

    print(f"[INFO] Total rows: {total_rows}")
    print(f"[INFO] Already processed: {total_rows - total_missing}")
    print(f"[INFO] Remaining: {total_missing}")

    if total_missing == 0:
        print("[DONE] Nothing to do.")
        return

    with tqdm(total=total_missing, desc="Classifying countries", unit="row") as pbar:
        for offset in range(0, total_missing, CHECKPOINT_EVERY):
            chunk = unprocessed[offset : offset + CHECKPOINT_EVERY]

            classify_indices(df, chunk, hosts, pbar)

            df.to_csv(OUTPUT_CSV, index=False)
            print(f"[INFO] Saved progress at {offset + len(chunk)} / {total_missing}")

    print("[DONE] All rows processed and saved.")


if __name__ == "__main__":
    main()
