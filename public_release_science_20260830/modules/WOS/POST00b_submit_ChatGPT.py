# 09F_submit_batches.py
# ------------------------------------------------------------
# Runs every minute, clears screen, shows progress,
# skips API checks for completed batches, and stops when all done.
# ------------------------------------------------------------

import json, sys, time, os
from pathlib import Path
from tqdm.auto import tqdm
from openai import OpenAI

# ----------------------------
# CONFIG
# ----------------------------
OUTPUT_DIR = Path("../../proc_output/WOS/_CHAT")
BATCH_RECORD_PATH = OUTPUT_DIR / "batch_ids.json"
API_KEY_FILE = Path("../../config/openai_api_key.txt")
BATCH_DESC = "WOS_US_Orgs"
DRY_RUN = False
MAX_RUNNING_BATCHES = 2
SLEEP_SECONDS = 20

# ----------------------------
# HELPERS
# ----------------------------
def clear_screen():
    os.system("cls" if os.name == "nt" else "clear")

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

def load_records(path: Path) -> dict:
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return {d["file"]: d for d in data if "file" in d}
    except Exception:
        return {}

def save_records(records: dict, path: Path):
    with path.open("w", encoding="utf-8") as f:
        json.dump(list(records.values()), f, indent=2)

def _rc_get(rc, key, default=0):
    if rc is None:
        return default
    return rc.get(key, default) if isinstance(rc, dict) else getattr(rc, key, default)

def _summarize(updates):
    """Derive counts from the current record set (includes skipped-completed)."""
    running = sum(1 for r in updates if r.get("status") in ("validating", "running", "in_progress", "finalizing"))
    completed = sum(1 for r in updates if r.get("status") in ("completed", "succeeded"))
    failed = sum(1 for r in updates if r.get("status") in ("failed", "expired"))
    cancelled = sum(1 for r in updates if r.get("status") == "cancelled")
    return running, completed, failed, cancelled

# ----------------------------
# ONE CYCLE
# ----------------------------
def run_once():
    clear_screen()
    print("🕒 Checking and submitting batches...\n")

    existing = load_records(BATCH_RECORD_PATH)
    jsonl_files = sorted(OUTPUT_DIR.glob("batch_*.jsonl"))
    #print(len(jsonl_files))
    if not jsonl_files:
        print(f"No JSONL files found in {OUTPUT_DIR.resolve()} — stopping.")
        sys.exit(0)

    if DRY_RUN:
        print("🧪 DRY RUN MODE — No API calls will be made.\n")
        client = None
    else:
        api_key = load_api_key(API_KEY_FILE)
        client = OpenAI(api_key=api_key)

    pending_updates = []

    # --- Check statuses (skip completed/succeeded to save API calls) ---
    if not DRY_RUN and existing:
        print("[check] Checking batch statuses...\n")
        for rec in tqdm(list(existing.values()), desc="[check] batches", ncols=100):
            status = rec.get("status", "")
            if status in ("completed", "succeeded"):
                # ✅ Skip re-check; ensure progress marker is present.
                rec["progress_str"] = "completed"
                pending_updates.append(rec)
                continue

            b_id = rec.get("batch_id")
            if not b_id:
                pending_updates.append(rec)
                continue

            try:
                batch = client.batches.retrieve(b_id)
                rec["status"] = batch.status

                rc = getattr(batch, "request_counts", None)
                total = _rc_get(rc, "total")
                done = _rc_get(rc, "completed")
                failed_cnt = _rc_get(rc, "failed")
                processed = (done or 0) + (failed_cnt or 0)
                rec["request_counts"] = {
                    "total": total,
                    "completed": done,
                    "failed": failed_cnt,
                    "processed": processed,
                }

                if batch.status in ("validating", "running", "in_progress", "finalizing"):
                    rec["progress_str"] = f"{processed}/{total} ({done}✓, {failed_cnt}✗)"
                elif batch.status in ("completed", "succeeded"):
                    rec["progress_str"] = "completed"
                elif batch.status in ("failed", "expired"):
                    rec["progress_str"] = "failed"
                elif batch.status == "cancelled":
                    rec["progress_str"] = "cancelled"

                pending_updates.append(rec)
            except Exception as e:
                print(f"[error] Could not retrieve {b_id}: {e}")
                rec["status"] = "error"
                rec["progress_str"] = "error"
                pending_updates.append(rec)
    else:
        # DRY_RUN or no existing: just pass through
        pending_updates = list(existing.values())

    # --- Summary computed from ALL records ---
    running, completed, failed, cancelled = _summarize(pending_updates)

    print("\n=== Batch Summary ===")
    print(f"Running    : {running}")
    print(f"Completed  : {completed}")
    print(f"Failed     : {failed}")
    print(f"Cancelled  : {cancelled}")
    print("=====================\n")

    if running:
        for r in pending_updates:
            if r.get("status") in ("validating", "running", "in_progress", "finalizing"):
                prog = r.get("progress_str") or "n/a"
                print(f"▶ {r.get('file','?')}  {prog}")

    save_records({r["file"]: r for r in pending_updates}, BATCH_RECORD_PATH)

    # --- Decide next action ---
    next_file = next((p for p in jsonl_files if p.name not in existing), None)
    #print(next_file)

    # Stop condition: no running, no unsubmitted file, and all records terminal
    all_done = (
        next_file is None
        and running == 0
        and (all(r.get("status") in ("completed", "succeeded", "failed", "expired", "cancelled")
                for r in pending_updates) if pending_updates else True)
    )
    if all_done:
        print("\n🏁 All JSONL files uploaded and all batches finished.\n")
        sys.exit(0)

    if running >= MAX_RUNNING_BATCHES:
        print(f"\n🚫 Too many running batches ({running}). Waiting...")
        return

    if next_file is None:
        print("ℹ️ No new JSONL to submit. Waiting for batches to finish...")
        return

    print(f"\n[next] Preparing to upload {next_file.name}\n")

    if DRY_RUN:
        print(f"🧪 DRY RUN — would upload: {next_file.name}")
        return

    with open(next_file, "rb") as fh:
        upload = client.files.create(file=fh, purpose="batch")

    batch = client.batches.create(
        input_file_id=upload.id,
        endpoint="/v1/responses",
        completion_window="24h",
        metadata={"description": f"{BATCH_DESC} | {next_file.name}"},
    )

    print(f"[upload] {next_file.name} → batch_id={batch.id} ({batch.status})")

    # Record new submission
    existing[next_file.name] = {
        "file": next_file.name,
        "file_id": upload.id,
        "batch_id": batch.id,
        "status": batch.status,
        "progress_str": "submitted",
    }
    save_records(existing, BATCH_RECORD_PATH)
    print(f"\n✅ Submitted 1 batch and updated {BATCH_RECORD_PATH}\n")

# ----------------------------
# LOOP
# ----------------------------
if __name__ == "__main__":
    while True:
        try:
            run_once()
        except SystemExit:
            # Allow graceful termination when all done
            raise
        except Exception as e:
            print(f"\n[Error] {e}\n")
        print(f"\n💤 Sleeping {SLEEP_SECONDS} seconds...\n")
        time.sleep(SLEEP_SECONDS)
