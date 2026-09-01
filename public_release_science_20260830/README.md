# Geopolitical tensions with the U.S. accelerate Chinese firms’ leveraging of science

Code and selected analysis outputs for the Science paper.

## Contents

- `analytics/`: primarily Stata analysis code, plus supplementary notebooks.
- `modules/`: Python preprocessing and matching code, plus two CNKI Stata files.
- `stata_output/`: 24 analysis-ready data artifacts (15 `.dta` files and nine
  archives), totaling about 0.57 GB as stored.
- `figure_output/` and `table_output/`: selected final results.
- `docs/`: data inventories, scope, requirements, and release limitations.

Raw data, most upstream intermediates, and Python process outputs are not
included. See `docs/processed_data_manifest.csv` for the included files and
`docs/raw_data_inventory.md` for excluded inputs.

## Quick start

1. Install the Python packages listed in `requirements.txt`.
2. In Stata, run `do scripts/setup_stata_packages.do` once to install the
   required user-written commands.
3. Extract the Stata archives before use: extract the six `.dta.zip` files from
   the release root while preserving their stored paths; extract each of the
   three other `_cem.zip` files into its containing directory.
4. Use the analysis-ready files with the relevant code under `analytics/`.

Not every upstream or archival runner can execute from the bundled data alone.
See `docs/submission_readiness_review_20260626.md` for the supported boundary.
Full reconstruction requires the external inputs in
`docs/raw_data_inventory.md` and paths configured in `config/dataset.yml`.
Optional LLM-assisted steps require user-provided credentials or local services;
no API keys are included.

## Verification

Run `python scripts/sanitize_public_release.py --check` from the release root.
This structural check does not rerun the analyses or reconstruct raw data.

## Contact

Questions or suggestions: [junhan.wang@szu.edu.cn](mailto:junhan.wang@szu.edu.cn).
