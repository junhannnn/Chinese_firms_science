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
INPUT_PATH = "02_WOS_unique_orgs_CN_US.parquet"
OUTPUT_CSV = "02_WOS_unique_orgs_with_type.csv"
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

# Allowed categories (for post-validation)
CATEGORIES = {
    "Education",
    "Funder",
    "Healthcare",
    "Finance",
    "Company",
    "Archive",
    "Nonprofit",
    "Government",
    "Facility",
    "Other",
}

# -------------------------------------------------------------------
# SYSTEM PROMPT (TYPE CLASSIFICATION)
# -------------------------------------------------------------------
SYSTEM_PROMPT = """
You classify organizations and affiliation text into one of the following categories.

Education: A university or research institution involved in providing education and educating/employing researchers.
Funder: An organization that awards research funds or provides in-kind support. National research funding agencies, private foundations, university foundations, corporate research funding units, and public-interest organizations that sponsor research.
Healthcare: A medical care facility such as a hospital or medical clinic. Excludes medical schools, which should be categorized as “Education”.
Finance: A financial institution such as a bank, insurance company, securities firm, or other financial services organization.
Company: A private for-profit corporate entity involved in conducting or sponsoring research.
Archive: An organization involved in stewarding research and cultural heritage materials. Includes libraries, museums, magazine, theater, gallery, church, publishing, and zoos.
Nonprofit: Nonprofit: Non-government, non-profit organizations that conduct or support research.
Government: An organization that is part of or operated by a national or regional government and that conducts or supports research.
Facility: A specialized facility where research takes place, such as a laboratory or telescope or observatory or dedicated research area.
Other: A category for any organization that does not fit the categories above.

Rules:
- Return only the category name, exactly as listed above.
- Do not output explanations, punctuation, spaces before/after, or any extra text.
- If you are unsure, choose the single best-fitting category. If it truly does not fit any, return "Other".
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


def call_ollama_type(host: Host, org: str) -> str:
    """Classify a single organization into a type."""
    if org is None or (isinstance(org, float) and pd.isna(org)):
        return "Other"

    host.acquire()
    try:
        def _do_call():
            resp = host.client.chat(
                model=MODEL,
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {
                        "role": "user",
                        "content": f"What is the category of: {org}",
                    },
                ],
                options={"temperature": TEMPERATURE},
                keep_alive=KEEP_ALIVE,
            )
            return resp

        resp = call_with_retries(_do_call)
        content = (resp.get("message", {}).get("content") or "").strip()
        label = content.splitlines()[0].strip()

        # Normalize and validate
        if label in CATEGORIES:
            return label

        # Try a forgiving normalization
        label_clean = label.strip().rstrip(".")
        if label_clean in CATEGORIES:
            return label_clean

        return "Other"
    finally:
        host.release()


# -------------------------------------------------------------------
# Classification over a list of row indices
# -------------------------------------------------------------------
def classify_indices(df, indices, hosts, pbar):
    if "type" not in df.columns:
        df["type"] = pd.NA

    to_process = df.loc[indices]
    to_process = to_process[to_process["type"].isna()]

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
            fut = executor.submit(call_ollama_type, host, org)
            futures[fut] = idx

        for fut in as_completed(futures):
            idx = futures[fut]
            try:
                label = fut.result()
            except Exception as e:
                print(f"[ERROR] Failed for index {idx}: {e}")
                label = "Other"
            df.at[idx, "type"] = label
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

    if "type" not in df.columns:
        df["type"] = pd.NA

    # warm hosts
    hosts = [Host(name, url, cap) for (name, url, cap) in HOST_CONFIGS]
    for h in hosts:
        print(f"[INFO] Warming up host {h.name} ({h.client._client.base_url})")
        warmup_host(h)

    # find missing rows
    mask = df["type"].isna()
    unprocessed = df.index[mask].tolist()
    total_missing = len(unprocessed)
    total_rows = len(df)

    print(f"[INFO] Total rows: {total_rows}")
    print(f"[INFO] Already processed: {total_rows - total_missing}")
    print(f"[INFO] Remaining: {total_missing}")

    if total_missing == 0:
        print("[DONE] Nothing to do.")
        return

    with tqdm(total=total_missing, desc="Classifying types", unit="row") as pbar:
        for offset in range(0, total_missing, CHECKPOINT_EVERY):
            chunk = unprocessed[offset: offset + CHECKPOINT_EVERY]

            classify_indices(df, chunk, hosts, pbar)

            df.to_csv(OUTPUT_CSV, index=False)
            print(f"[INFO] Saved progress at {offset + len(chunk)} / {total_missing}")

    print("[DONE] All rows processed and saved.")


if __name__ == "__main__":
    main()
