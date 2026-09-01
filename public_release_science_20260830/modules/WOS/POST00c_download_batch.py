# 10F_download_outputs_only.py
# ------------------------------------------------------------
# Downloads ONLY the output JSONL for all finished batches.
# No error files, no meta JSON — avoids serialization pitfalls.
# ------------------------------------------------------------

import json, os, sys
from pathlib import Path
from tqdm.auto import tqdm
from openai import OpenAI

# ----------------------------
# CONFIG (align with submit script)
# ----------------------------
OUTPUT_DIR = Path("../../proc_output/WOS/_CHAT")
BATCH_RECORD_PATH = OUTPUT_DIR / "batch_ids.json"
API_KEY_FILE = Path("../../config/openai_api_key.txt")

# ----------------------------
# HELPERS
# ----------------------------
def load_api_key(path: Path) -> str:
    env_key = os.environ.get("OPENAI_API_KEY", "").strip()
    if env_key.startswith("sk-"):
        return env_key
    if not path.exists():
        print(f"\n❌ ERROR: API key file not found: {path.resolve()}")
        sys.exit(1)
    key = path.read_text(encoding="utf-8").strip()
    if not key.startswith("sk-"):
        print("❌ Invalid key format.")
        sys.exit(1)
    return key

def load_records(path: Path) -> list[dict]:
    if not path.exists():
        print(f"❌ No record file found at {path}.")
        sys.exit(1)
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return data if isinstance(data, list) else list(data.values())
    except Exception as e:
        print(f"❌ Could not parse {path}: {e}")
        sys.exit(1)

def ensure_dir(p: Path):
    p.parent.mkdir(parents=True, exist_ok=True)

def terminal_status(s: str) -> bool:
    return s in ("completed", "succeeded", "failed", "expired", "cancelled")

def is_success(s: str) -> bool:
    return s in ("completed", "succeeded")

def out_path(rec: dict, batch_id: str) -> Path:
    stub = Path(rec.get("file", f"batch_{batch_id}")).stem
    return OUTPUT_DIR / "completed" / f"{stub}_output.jsonl"

def stream_download(client: OpenAI, file_id: str, dest: Path):
    """No context manager: compatible with recent SDKs."""
    ensure_dir(dest)
    resp = client.files.content(file_id)
    if hasattr(resp, "stream_to_file"):
        resp.stream_to_file(dest)
        return
    try:
        data = resp.read()
        dest.write_bytes(data)
    except Exception:
        with open(dest, "wb") as f:
            it = getattr(resp, "iter_bytes", None)
            if callable(it):
                for chunk in it():
                    f.write(chunk)
            else:
                f.write(bytes(resp))

# ----------------------------
# MAIN
# ----------------------------
def main():
    api_key = load_api_key(API_KEY_FILE)
    client = OpenAI(api_key=api_key)

    records = load_records(BATCH_RECORD_PATH)
    finished = [r for r in records if terminal_status(str(r.get("status","")))]
    if not finished:
        print("ℹ️ No finished batches found.")
        return

    downloaded, skipped, warnings = 0, 0, 0
    print(f"📦 Finished batches: {len(finished)}")

    for rec in tqdm(finished, desc="[download] outputs", ncols=100):
        bid = rec.get("batch_id")
        if not bid:
            skipped += 1
            continue

        try:
            batch = client.batches.retrieve(bid)
        except Exception as e:
            print(f"\n[warn] Retrieve {bid} failed: {e}")
            warnings += 1
            continue

        status = batch.status or rec.get("status")
        if not is_success(status):
            # Only pull outputs for successful batches
            skipped += 1
            continue

        output_file_id = getattr(batch, "output_file_id", None)
        if not output_file_id:
            print(f"\n[warn] {bid} is {status} but has no output_file_id.")
            warnings += 1
            continue

        dest = out_path(rec, bid)
        if dest.exists():
            skipped += 1
            continue

        try:
            stream_download(client, output_file_id, dest)
            downloaded += 1
        except Exception as e:
            print(f"\n[error] Download {bid} → {dest.name}: {e}")
            warnings += 1

    print("\n=== Output Download Summary ===")
    print(f"Downloaded : {downloaded}")
    print(f"Skipped    : {skipped} (not successful or already exists)")
    print(f"Warnings   : {warnings}")
    print("================================\n")

if __name__ == "__main__":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    main()
