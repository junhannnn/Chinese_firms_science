# Submission Readiness Review (updated 2026-09-01)

This note documents the current public-release boundary for this copied release
folder. It is a structural and portability review, not a rerun of the full raw
data pipeline or the Stata analyses.

## Current Public Boundary

- Public code is included under `modules/`, `analytics/`, and `scripts/`.
- Raw data are not included. The expected raw-data locations are documented in
  `raw_data_inventory.md`.
- The selected process-data layer is limited to 24 analysis-ready files under
  `stata_output/`, totaling about 1.11 GB in decimal units; it includes the
  CEM-matched listed-firm panels used by the CN patent-science, CNKI, and WOS
  analysis scripts, and several other large panels are bundled as `.dta.zip`
  files.
- No data files are currently included under `proc_output/`; that folder is a
  documented destination for regenerated Python process outputs.
- Selected final figures and tables remain bundled for comparison with the
  submitted-paper outputs. Stata logs are not included in this copy.

## Structural Checks

The current release-facing checks verify that:

- `docs/processed_data_manifest.csv` matches the live `stata_output/` and
  `proc_output/` data-file set.
- Notebook cells do not carry saved outputs or execution counts.
- Cache folders, notebook checkpoints, compiled Python artifacts, and local key
  files are absent.
- Public text and code do not contain private absolute paths such as local drive
  roots, user-home paths, or project mirror folders.
- README and documentation references resolve to files that are present, except
  for paths that are explicitly described as excluded or unpublished inputs.

Run the structural preflight with:

```powershell
python scripts/sanitize_public_release.py --check
```

If process-data files are intentionally added or removed, refresh the manifest
from the live tree with:

```powershell
python scripts/sanitize_public_release.py --refresh-processed-manifest
```

Then rerun the `--check` command.

## Reproduction Guidance

For reproduction from the public bundle, begin with the included
analysis-ready `stata_output/` files, after unzipping any bundled `.dta.zip`
files, and the Stata analysis code under
`analytics/`. Do not assume every archival or upstream `00_run_all*.do` file can
be run from the bundled data alone.

For full reconstruction from raw sources, obtain the raw data described in
`raw_data_inventory.md`, place them under the documented `dataset/` subfolders,
and run the relevant preprocessing notebooks and Stata cleaning scripts.

## Caveats

- This review does not certify that third-party raw data can be redistributed.
- This review does not rerun Stata, Python notebooks, or the full raw-data
  pipeline.
- Some optional archival or LLM-assisted scripts may require excluded raw data,
  local services, or user-provided credentials.




