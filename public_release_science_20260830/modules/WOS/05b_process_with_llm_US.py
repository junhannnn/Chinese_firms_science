import csv
import json
import re
import time
import os
from itertools import combinations
from pathlib import Path
from collections import defaultdict

import requests
from tqdm import tqdm
from concurrent.futures import ProcessPoolExecutor, as_completed

# ============================
# CONFIG
# ============================
CSV_PATH = "04_canonical_log_US.csv"
HOST = os.environ.get("OLLAMA_HOST", "http://localhost:11434")  # Ollama-compatible chat endpoint base
MODEL = "llama3.3:70b"

OUT_JSON = "05_affiliation_clusters_US.json"
OUT_RESULTS_CSV = "05_llm_results_US.csv"
OUT_PAIRS_CSV = "05_candidate_pairs_before_llm_US.csv"  # saved BEFORE LLM calls

# Parallelism for building the search DB (candidate pairs)
PAIR_BUILD_PROCESSES = max(16, os.cpu_count() or 24)  # use all cores
MAX_BUCKET_SIZE = 30000           # effectively disables sharding unless extreme

# LLM settings (comparisons are sequential)
MAX_RETRIES = 3
RETRY_BASE_SLEEP = 1.5
TEMPERATURE = 0.0

SYSTEM_PROMPT = "Reply with a single character: 0 or 1."
PROMPT_TMPL = (
    "Decide if A and B refer to the SAME COMPANY (regardless of departments, divisions, units, research centers).\n"
    "Treat variations like 'R & D', 'Research', 'Res', 'Global Epidemiology', 'Global Research', 'Labs', 'Center', 'Services', etc. as the SAME company.\n"
    "However, if the areas/industries are totally different (e.g., one is biosciences, another is networking/cloud), treat them as DIFFERENT companies.\n"
    "\nExamples:\n"
    "- Rockheed Martin R & D vs Rockheed Martin Research -> 1\n"
    "- Amgen Global Epidemiology vs Amgen Global Research -> 1\n"
    "- IBM vs International Business Machines -> 1\n"
    "- PSE&G vs Public Service Electric & Gas -> 1\n"
    "- Microsoft vs Amazon -> 0\n"
    "- Pfizer vs Johnson & Johnson -> 0\n"
    "- Cisco Biosci vs Cisco Network -> 0\n"
    "\nA='{a}'\nB='{b}'\nAnswer: 0 or 1 only."
)
PROMPT_TMPL = (
    "Decide if A and B refer to the SAME legal entity (i.e., the same officially registered organization, company, or institution; but not just related, subsidiary or similar in name).\n"
    "\nA='{a}'\nB='{b}'\nAnswer: 0 (No) or 1 (Yes) only."
)


STOP_TOKENS = {
    "and", "sci", "science", "scientific",
    "biotech", "bio", "biosci",
    "pharma", "pharmaceut", "pharmaceutical", "therapeut",
    "medical", "med", "medic", "therap",
    "health", "hlth",
    "systems", "syst", "serv", "services", "solutions", "solution", "solut",
    "res", "research", "technol", "tech", "technology",
    "center", "centre", "ctr", "division", "div", "department", "dept",
    "clinic", "hospital", "imaging", "trading",
    "inc", "corp", "co", "ltd", "plc", "llc"
}

# Only llm_results.csv uses CHECKPOINT_EVERY (batched writes)
CHECKPOINT_EVERY = 100

# Headword constraints
HEADWORD_MIN_LEN = 3  # avoid bucketing tiny headwords like "DB", "&", "A"

# ============================
# LLM CALL (expects '0' or '1')
# ============================
def ask_llm(a: str, b: str) -> int:
    url = f"{HOST}/api/chat"
    payload = {
        "model": MODEL,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": PROMPT_TMPL.format(a=a, b=b)},
        ],
        "stream": False,
        "options": {"temperature": TEMPERATURE},
    }
    r = requests.post(url, json=payload, timeout=120)
    r.raise_for_status()
    content = r.json().get("message", {}).get("content", "").strip()
    m = re.search(r"[01]", content)
    if not m:
        raise ValueError(f"Non-binary reply: {content!r}")
    return int(m.group(0))

def ask_llm_retry(a: str, b: str) -> int:
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            return ask_llm(a, b)
        except Exception:
            if attempt == MAX_RETRIES:
                return 0  # conservative default
            time.sleep(RETRY_BASE_SLEEP * (2 ** (attempt - 1)))

# ============================
# UNION–FIND (DSU)
# ============================
class DSU:
    def __init__(self, n):
        self.p = list(range(n))
    def find(self, x):
        while self.p[x] != x:
            self.p[x] = self.p[self.p[x]]
            x = self.p[x]
        return x
    def union(self, x, y):
        rx, ry = self.find(x), self.find(y)
        if rx != ry:
            self.p[ry] = rx
            return True
        return False

# ============================
# IO
# ============================
def load_names(path):
    names = []
    with open(path, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            val = (row.get("canonical_affiliation") or "").strip()
            if val:
                names.append(val)
    # de-dup, keep order
    seen, uniq = set(), []
    for n in names:
        if n not in seen:
            seen.add(n)
            uniq.append(n)
    return uniq

def write_json(path, groups):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(groups, f, indent=2, ensure_ascii=False)

def save_pairs_csv(path, pairs, names):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["i", "j", "a", "b"])
        for i, j in pairs:
            w.writerow([i, j, names[i], names[j]])

# ============================
# CLEANERS
# ============================
SEP = re.compile(r"[^A-Za-z0-9]+")

def clean_tokens(s: str):
    if not s:
        return []
    s = SEP.sub(" ", s).strip().lower()
    toks = [t for t in s.split() if t and t not in STOP_TOKENS]
    # fuse consecutive one-letter tokens: ["r","&","d"] -> ["rd"]
    fused, buf = [], []
    for t in toks:
        if len(t) == 1:
            buf.append(t)
        else:
            if buf:
                fused.append("".join(buf)); buf = []
            fused.append(t)
    if buf:
        fused.append("".join(buf))
    return fused

def compact(tokens):             # join tokens w/o spaces
    return "".join(tokens)

def headword(tokens):            # first token (if any)
    return tokens[0] if tokens else ""

def initials_all(tokens):        # initials of all tokens
    return "".join(t[0] for t in tokens if t)

def initials_tail(tokens):
    if len(tokens) <= 1:
        return ""
    tail = tokens[1:]
    ini = "".join(t[0] for t in tail if t)
    return ini if len(ini) >= 2 else ""   # require ≥2 letters

# Strict acronym detector: 3–6 uppercase letters (spaces ignored)
def is_acronym(raw_name: str) -> bool:
    s = raw_name.replace(" ", "")
    return s.isalpha() and s.isupper() and 3 <= len(s) <= 6

def initials_variants(tokens):
    """
    Possible acronym candidates (uppercase) from tokens:
      - initials of all tokens
      - initials with the LAST token dropped
    Keep only 3–6 letters.
    """
    vars = set()
    if not tokens:
        return vars
    full = "".join(t[0] for t in tokens if t)
    if 3 <= len(full) <= 6:
        vars.add(full.upper())
    if len(tokens) > 1:
        drop_last = "".join(t[0] for t in tokens[:-1] if t)
        if 3 <= len(drop_last) <= 6:
            vars.add(drop_last.upper())
    return vars

# ============================
# MULTIPROCESS PAIR GENERATION
# ============================
def _pairs_from_index_list(idxs):
    if len(idxs) < 2:
        return []
    idxs = list(idxs)
    out = []
    for a in range(len(idxs) - 1):
        ia = idxs[a]
        for b in range(a + 1, len(idxs)):
            ib = idxs[b]
            out.append((ia, ib) if ia < ib else (ib, ia))
    return out

def _shard_if_large(idxs, comp):
    if len(idxs) <= MAX_BUCKET_SIZE:
        return [idxs]
    sub = defaultdict(list)
    for i in idxs:
        key = comp[i][:3]
        sub[key].append(i)
    return [lst for lst in sub.values() if len(lst) > 1]

def candidate_pairs_parallel(names, processes=PAIR_BUILD_PROCESSES):
    n = len(names)
    toks = [clean_tokens(s) for s in names]
    comp = [compact(t) for t in toks]
    ini_all = [initials_all(t) for t in toks]
    ini_tail = [initials_tail(t) for t in toks]
    head = [headword(t) for t in toks]

    # Build buckets (keep only multi-item lists), and ignore tiny headwords
    by_head, by_ini_tail = {}, {}
    def add(bucket, key, idx):
        bucket.setdefault(key, []).append(idx)
    for i in range(n):
        if len(head[i]) >= HEADWORD_MIN_LEN:
            add(by_head, head[i], i)
        if ini_tail[i]:
            add(by_ini_tail, ini_tail[i], i)

    def prune(bkt):
        return {k: v for k, v in bkt.items() if len(v) > 1}

    by_head = prune(by_head)
    by_ini_tail = prune(by_ini_tail)

    bucket_list = [
        ("headword", by_head),
        ("initials_tail", by_ini_tail),
    ]

    cand = set()
    for label, bucket in bucket_list:
        idx_lists = []
        for _, idxs in bucket.items():
            idx_lists.extend(_shard_if_large(idxs, comp))
        if not idx_lists:
            continue

        with ProcessPoolExecutor(max_workers=processes) as ex, tqdm(total=len(idx_lists), desc=f"Build pairs: {label}", unit="list", leave=False) as pbar:
            futures = [ex.submit(_pairs_from_index_list, lst) for lst in idx_lists]
            for fut in as_completed(futures):
                pairs = fut.result()
                cand.update(pairs)
                pbar.set_postfix_str(f"unique_pairs={len(cand)}")
                pbar.update(1)

    # SPECIAL: Acronym ↔ long-form (and acronym-headword) candidates
    acro_indices = [i for i, nm in enumerate(names) if is_acronym(nm)]
    by_initials = defaultdict(list)
    for i in range(n):
        for key in initials_variants(toks[i]):  # use full + drop-last variants
            by_initials[key].append(i)

    # (a) acronym ↔ long form via initials (variants)
    for i in acro_indices:
        acro = names[i].replace(" ", "")
        for j in by_initials.get(acro, []):
            if i == j:
                continue
            a, b = (i, j) if i < j else (j, i)
            cand.add((a, b))

    # (b) acronym ↔ names whose HEADWORD equals the acronym (e.g., 'IBM Corp', 'IBM Canada')
    for i in acro_indices:
        acro_lc = names[i].replace(" ", "").lower()
        for j, hj in enumerate(head):
            if i == j:
                continue
            if hj == acro_lc:
                a, b = (i, j) if i < j else (j, i)
                cand.add((a, b))

    # -------- Cheap filters (strict) --------

    # Unit/branch hints that imply NOT the same legal entity
    DIFF_HINTS = {
        "service","services","serv","research","res","center","centre","ctr",
        "division","div","department","dept","clinic","hospital","imaging","solutions",
        "solution","solut","lab","labs","laboratory","trading","canada","nz"
    }

    def has_meaningful_tail(t):
        return any(tok not in STOP_TOKENS for tok in t[1:])

    def auto_zero_by_tail(i, j):
        # Same headword but tails differ by unit/branch hints → skip
        if head[i] != head[j]:
            return False
        ti = set(toks[i][1:])
        tj = set(toks[j][1:])
        return bool((ti ^ tj) & DIFF_HINTS)

    kept = []

    def boundary_prefix(a_tokens, a_comp, b_tokens, b_comp):
        if not a_comp or not b_comp or not b_comp.startswith(a_comp):
            return False
        pref = ""
        for t in b_tokens:
            pref += t
            if len(pref) == len(a_comp):
                return True
        return False

    with tqdm(total=len(cand), desc="Filtering candidates", unit="pair", leave=False) as pbar:
        for i, j in cand:
            # Early rejections
            if auto_zero_by_tail(i, j):
                pbar.update(1); continue
            if head[i] == head[j] and not (has_meaningful_tail(toks[i]) or has_meaningful_tail(toks[j])):
                pbar.update(1); continue

            ci, cj = comp[i], comp[j]
            if not ci or not cj:
                pbar.update(1); continue

            # length ratio (now ≤ 3.0)
            la, lb = len(ci), len(cj)
            r = (la / lb) if la >= lb else (lb / la)
            if r > 3.0:
                pbar.update(1); continue

            same_head = (head[i] == head[j])

            # 1) token-boundary prefix
            if boundary_prefix(toks[i], ci, toks[j], cj) or boundary_prefix(toks[j], cj, toks[i], ci):
                kept.append((i, j)); pbar.update(1); continue

            # 2) suffix (only when headwords match)
            if same_head and (ci.endswith(cj) or cj.endswith(ci)):
                kept.append((i, j)); pbar.update(1); continue

            # 3) head-drop: ignore very short leading token on one side (≤3)
            if len(toks[i]) > 1 and len(toks[i][0]) <= 3 and ci[len(toks[i][0]):] == cj:
                kept.append((i, j)); pbar.update(1); continue
            if len(toks[j]) > 1 and len(toks[j][0]) <= 3 and cj[len(toks[j][0]):] == ci:
                kept.append((i, j)); pbar.update(1); continue

            # 4) merged-word (≥3+3)
            merged_hit = False
            for k in range(len(toks[i]) - 1):
                if len(toks[i][k]) >= 3 and len(toks[i][k+1]) >= 3:
                    if (toks[i][k] + toks[i][k+1]) in toks[j]:
                        kept.append((i, j)); merged_hit = True; break
            if not merged_hit:
                for k in range(len(toks[j]) - 1):
                    if len(toks[j][k]) >= 3 and len(toks[j][k+1]) >= 3:
                        if (toks[j][k] + toks[j][k+1]) in toks[i]:
                            kept.append((i, j)); merged_hit = True; break
            if merged_hit:
                pbar.update(1); continue

            # 5) ACRONYM-ONLY initials logic (with tail-drop variants)
            if is_acronym(names[i]):
                acro = names[i].replace(" ", "")
                if acro in initials_variants(toks[j]) or head[j] == acro.lower():
                    kept.append((i, j)); pbar.update(1); continue

            if is_acronym(names[j]):
                acro = names[j].replace(" ", "")
                if acro in initials_variants(toks[i]) or head[i] == acro.lower():
                    kept.append((i, j)); pbar.update(1); continue

            pbar.update(1)

    return kept  # unique i<j pairs

# ============================
# MAIN
# ============================
def main():
    names = load_names(CSV_PATH)
    if not names:
        print("No canonical_affiliation values found.")
        return

    # Build candidate pairs in parallel
    pairs = candidate_pairs_parallel(names, processes=PAIR_BUILD_PROCESSES)
    print(f"Rows: {len(names)} | Candidate comparisons after pruning: {len(pairs)}")

    # Save the LLM search pairs to CSV BEFORE calling LLM
    save_pairs_csv(OUT_PAIRS_CSV, pairs, names)
    print(f"Saved candidate pairs to {OUT_PAIRS_CSV}")

    # Cluster with DSU using LLM decisions on RAW strings (sequential)
    dsu = DSU(len(names))
    merges = 0

    with open(OUT_RESULTS_CSV, "w", newline="", encoding="utf-8") as f_res:
        wres = csv.writer(f_res)
        wres.writerow(["i", "j", "a", "b", "same"])  # header
        buffer_rows = []

        for idx, (i, j) in enumerate(tqdm(pairs, desc="Comparing pairs (LLM)", unit="pair")):
            same = ask_llm_retry(names[i], names[j])
            buffer_rows.append([i, j, names[i], names[j], same])

            if same == 1 and dsu.union(i, j):
                merges += 1

            # Only LLM results use CHECKPOINT_EVERY (batched CSV write)
            if CHECKPOINT_EVERY and (idx + 1) % CHECKPOINT_EVERY == 0:
                wres.writerows(buffer_rows)
                f_res.flush()
                buffer_rows.clear()

        if buffer_rows:
            wres.writerows(buffer_rows)
            f_res.flush()

    # Build clusters → JSON list-of-lists
    groups = {}
    for i, name in enumerate(names):
        groups.setdefault(dsu.find(i), []).append(name)

    clusters = list(groups.values())
    write_json(OUT_JSON, clusters)
    print(f"Wrote {len(clusters)} groups -> {OUT_JSON}")

if __name__ == "__main__":
    main()
