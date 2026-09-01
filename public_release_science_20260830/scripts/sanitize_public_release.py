"""Structural preflight checks for the public release folder.

The script intentionally uses only the Python standard library so it can run in
a fresh checkout before the project environment is installed.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "docs" / "processed_data_manifest.csv"
DATA_ROOTS = ("proc_output", "stata_output")
TEXT_SUFFIXES = {
    ".do",
    ".ipynb",
    ".json",
    ".md",
    ".py",
    ".txt",
    ".yaml",
    ".yml",
}
SKIP_DIR_NAMES = {
    ".git",
    ".ipynb_checkpoints",
    "__pycache__",
}
FORBIDDEN_ARTIFACT_NAMES = {
    ".DS_Store",
    ".env",
    ".pytest_cache",
    ".ruff_cache",
    "__pycache__",
    ".ipynb_checkpoints",
}
ALLOWED_MISSING_REFERENCES = {
    "config/openai_api_key.txt",
    "proc_output/WOS/WOS_2010_2023.csv",
}
PRIVATE_PATH_PATTERNS = [
    re.compile(r"(?<![A-Za-z])[A-Za-z]:[\\/][^\s`'\"),]+"),
    re.compile(r"\\\\[^\\/\s]+[\\/][^\s`'\"),]+"),
    re.compile(r"/Users/[^/\s`'\"),]+"),
    re.compile(r"/home/[^/\s`'\"),]+"),
    re.compile(r"/Volumes/[^/\s`'\"),]+"),
    re.compile(r"\bMac_Sync\b"),
]
SECRET_PATTERNS = [
    re.compile(r"sk-[A-Za-z0-9_-]{20,}"),
    re.compile(r"(?i)(api[_-]?key|secret|password|token)\s*=\s*['\"][^'\"]+['\"]"),
]


@dataclass
class CheckResult:
    name: str
    ok: bool
    details: list[str]


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def iter_project_files() -> list[Path]:
    files: list[Path] = []
    for path in ROOT.rglob("*"):
        if any(part in SKIP_DIR_NAMES for part in path.relative_to(ROOT).parts):
            continue
        if path.is_file():
            files.append(path)
    return files


def iter_text_files() -> list[Path]:
    return [path for path in iter_project_files() if path.suffix.lower() in TEXT_SUFFIXES]


def iter_data_files() -> list[Path]:
    files: list[Path] = []
    for root_name in DATA_ROOTS:
        root = ROOT / root_name
        if not root.exists():
            continue
        for path in root.rglob("*"):
            if path.is_file() and path.name.lower() != "readme.md":
                files.append(path)
    return sorted(files)


def read_manifest() -> list[dict[str, str]]:
    with MANIFEST_PATH.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def check_manifest() -> CheckResult:
    if not MANIFEST_PATH.exists():
        return CheckResult("processed manifest", False, ["docs/processed_data_manifest.csv is missing"])

    rows = read_manifest()
    manifest = {row["relative_path"].replace("\\", "/"): row for row in rows}
    actual = {rel(path): path.stat().st_size for path in iter_data_files()}

    details: list[str] = []
    ok = True

    missing = sorted(set(manifest) - set(actual))
    extra = sorted(set(actual) - set(manifest))
    mismatched = []
    for key in sorted(set(manifest) & set(actual)):
        try:
            expected = int(manifest[key]["bytes"])
        except (KeyError, TypeError, ValueError):
            expected = -1
        if expected != actual[key]:
            mismatched.append(f"{key}: manifest={expected}, actual={actual[key]}")

    if missing:
        ok = False
        details.extend(f"missing data file: {item}" for item in missing)
    if extra:
        ok = False
        details.extend(f"data file not in manifest: {item}" for item in extra)
    if mismatched:
        ok = False
        details.extend(f"size mismatch: {item}" for item in mismatched)

    if ok:
        total = sum(actual.values())
        details.append(f"{len(rows)} manifest rows match {len(actual)} data files ({total / 1e9:.2f} GB)")
    return CheckResult("processed manifest", ok, details)


def check_notebooks() -> CheckResult:
    details: list[str] = []
    for notebook in sorted(ROOT.rglob("*.ipynb")):
        if any(part in SKIP_DIR_NAMES for part in notebook.relative_to(ROOT).parts):
            continue
        try:
            data = json.loads(notebook.read_text(encoding="utf-8"))
        except Exception as exc:  # noqa: BLE001
            details.append(f"{rel(notebook)}: cannot parse notebook JSON ({exc})")
            continue
        for index, cell in enumerate(data.get("cells", []), start=1):
            if cell.get("cell_type") != "code":
                continue
            if cell.get("execution_count") is not None:
                details.append(f"{rel(notebook)} cell {index}: execution_count is set")
            if cell.get("outputs"):
                details.append(f"{rel(notebook)} cell {index}: outputs are present")
    if details:
        return CheckResult("notebook output hygiene", False, details)
    return CheckResult("notebook output hygiene", True, ["no notebook outputs or execution counts found"])


def check_artifacts() -> CheckResult:
    details: list[str] = []
    for path in ROOT.rglob("*"):
        parts = path.relative_to(ROOT).parts
        if path.name in FORBIDDEN_ARTIFACT_NAMES or path.suffix.lower() in {".pyc", ".pyo"}:
            details.append(rel(path))
        if parts == ("config", "openai_api_key.txt"):
            details.append(rel(path))
    if details:
        return CheckResult("cache and credential artifacts", False, sorted(details))
    return CheckResult("cache and credential artifacts", True, ["no cache, checkpoint, compiled, or key files found"])


def check_private_text() -> CheckResult:
    details: list[str] = []
    self_path = Path(__file__).resolve()
    for path in iter_text_files():
        if path.resolve() == self_path:
            continue
        if path.suffix.lower() == ".ipynb":
            try:
                data = json.loads(path.read_text(encoding="utf-8"))
            except Exception as exc:  # noqa: BLE001
                details.append(f"{rel(path)}: cannot parse notebook JSON ({exc})")
                continue
            lines: list[tuple[int, str]] = []
            for cell in data.get("cells", []):
                source = cell.get("source", [])
                if isinstance(source, list):
                    source_text = "".join(source)
                else:
                    source_text = str(source)
                lines.extend(enumerate(source_text.splitlines(), start=1))
        else:
            lines = list(enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), start=1))

        for lineno, line in lines:
            for pattern in PRIVATE_PATH_PATTERNS + SECRET_PATTERNS:
                if pattern.search(line):
                    details.append(f"{rel(path)}:{lineno}: {line.strip()[:160]}")
    if details:
        return CheckResult("private path and secret scan", False, details)
    return CheckResult("private path and secret scan", True, ["no private path or secret-like text hits found"])


def check_document_references() -> CheckResult:
    path_like = re.compile(r"`([^`]+)`")
    details: list[str] = []
    scan_roots = [ROOT / "README.md", ROOT / "docs", ROOT / "scripts"]

    for item in scan_roots:
        files = [item] if item.is_file() else sorted(item.rglob("*"))
        for path in files:
            if not path.is_file() or path.suffix.lower() not in TEXT_SUFFIXES:
                continue
            for lineno, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), start=1):
                for match in path_like.finditer(line):
                    token = match.group(1).strip().strip(".,;:()[]")
                    if token.startswith(("http://", "https://")):
                        continue
                    for prefix in ("do ", "python ", "stata ", "cd "):
                        if token.lower().startswith(prefix):
                            token = token[len(prefix) :].strip()
                    if not any(sep in token for sep in ("/", "\\")) and not token.endswith((".md", ".txt", ".yml", ".yaml", ".py", ".do")):
                        continue
                    normalized = token.replace("\\", "/")
                    if "*" in normalized or "?" in normalized:
                        continue
                    if " " in normalized:
                        normalized = normalized.split()[0]
                    if normalized in ALLOWED_MISSING_REFERENCES:
                        continue
                    root_candidate = ROOT / normalized
                    local_candidate = path.parent / normalized
                    if not root_candidate.exists() and not local_candidate.exists():
                        details.append(f"{rel(path)}:{lineno}: missing reference `{token}`")

    if details:
        return CheckResult("documentation references", False, details)
    return CheckResult("documentation references", True, ["README/docs/scripts references resolve or are documented exclusions"])


def refresh_manifest() -> None:
    old_purpose: dict[str, str] = {}
    if MANIFEST_PATH.exists():
        for row in read_manifest():
            old_purpose[row.get("relative_path", "").replace("\\", "/")] = row.get("purpose", "")

    fieldnames = [
        "relative_path",
        "source_path",
        "bytes",
        "size_mb",
        "purpose",
        "source_last_write_time",
        "copied_last_write_time",
    ]
    rows = []
    for path in iter_data_files():
        rel_path = rel(path)
        mtime = datetime.fromtimestamp(path.stat().st_mtime).isoformat(timespec="seconds")
        rows.append(
            {
                "relative_path": rel_path,
                "source_path": rel_path,
                "bytes": str(path.stat().st_size),
                "size_mb": f"{path.stat().st_size / (1024 * 1024):.2f}".rstrip("0").rstrip("."),
                "purpose": old_purpose.get(rel_path) or "Included process-data file",
                "source_last_write_time": mtime,
                "copied_last_write_time": mtime,
            }
        )

    with MANIFEST_PATH.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, quoting=csv.QUOTE_ALL)
        writer.writeheader()
        writer.writerows(rows)


def run_checks() -> int:
    checks = [
        check_manifest(),
        check_notebooks(),
        check_artifacts(),
        check_private_text(),
        check_document_references(),
    ]
    failed = False
    for check in checks:
        status = "OK" if check.ok else "FAIL"
        print(f"[{status}] {check.name}")
        for detail in check.details[:30]:
            print("  - " + detail.encode("ascii", "replace").decode("ascii"))
        if len(check.details) > 30:
            print(f"  - ... {len(check.details) - 30} more")
        failed = failed or not check.ok
    return 1 if failed else 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="run structural public-release checks")
    parser.add_argument(
        "--refresh-processed-manifest",
        action="store_true",
        help="rebuild docs/processed_data_manifest.csv from proc_output/ and stata_output/",
    )
    args = parser.parse_args()

    if args.refresh_processed_manifest:
        refresh_manifest()
        print(f"refreshed {rel(MANIFEST_PATH)}")

    if args.check or not args.refresh_processed_manifest:
        return run_checks()
    return 0


if __name__ == "__main__":
    sys.exit(main())


