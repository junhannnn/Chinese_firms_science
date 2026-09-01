# Modules Code Guide
This folder contains the first step in constructing the database for this
project. The data in this folder must be processed before running the files in
the `analysis` folder for descriptive statistics and regression analysis.

This folder contains preprocessing and matching code used to build the selected
analysis-ready data released with the Science submission. Most files are Python
notebooks or Python scripts. The folder is not purely Python: `modules/CNKI/`
also contains two Stata preprocessing scripts,
`04_paperlevel_to_firmlevel.do` and `08_data_cleaning.do`. These two files are
part of the CNKI preprocessing chain, not the analysis-stage Stata workflows in
`../analytics/`.

## How To Read This Folder

The default public reproduction path for the release starts from the selected
process data included under `../stata_output/`. The `../proc_output/` directory
is retained as a destination for regenerated Python outputs but contains no data
files in this public copy. Reviewers do not need to rerun every notebook in this
folder to inspect or rerun the main analysis-stage code. Treat this folder as
the upstream code record for how the process-data layer was constructed.

Full raw-data reconstruction requires external data described in
`../docs/raw_data_inventory.md` and the relative paths in `../config/dataset.yml`.
Raw third-party data are not bundled in this public release.

## Folder Map

- `_utils/`: local helper modules used by notebooks, including notebook execution
  helpers and firm/country matching utilities.
- `CN_CN/`: Chinese patent-paper preprocessing, OpenAlex institution-country lookup, OpenAlex/PCS merging,
  country/source attribution, and final Chinese patent non-patent literature
  matching outputs. Some notebooks require OpenAlex and PCS raw/source files.
- `CNKI/`: CNKI publication preprocessing, JIF extraction, firm-name cleaning,
  CNKI firm-panel construction, and SOE patching. This folder includes the two
  CNKI Stata preprocessing scripts noted above. `01c_CNKI_WOS_journalISSN_overlap.ipynb`
  is a CNKI-WOS overlap diagnostic used to support filtering/interpretation.
- `WOS/`: Web of Science preprocessing for CN and U.S. firm publications,
  firm-type classification, canonical firm-name construction, LLM-assisted
  filtering, and final WOS firm-year variables.

## Default, Raw-Reconstruction, And Optional Steps

- Default release use: start from the included process data and run the analysis
  code in `../analytics/` as documented in `../docs/submission_readiness_review_20260626.md`.
- Raw reconstruction: run the relevant notebooks/scripts here only after placing
  equivalent raw/source files under `../dataset/` and checking `../config/dataset.yml`.
- OpenAlex reconstruction: notebooks such as `CN_CN/CN0_merge_openalex.ipynb`,
  `CN_CN/CN2_reduce_match_db.ipynb`, and `CN_CN/CN2z_full_match.ipynb` use
  config-relative paths or environment variables such as
  `OPENALEX_CSV_CONFIG_DIR`, `OPENALEX_TITLE_YEAR_PARQUET`, and
  `OPENALEX_TITLE_YEAR_FULL_PARQUET` for local OpenAlex snapshots.
- LLM-assisted steps: OpenAI-assisted notebooks/scripts require `OPENAI_API_KEY`.
  Ollama-assisted scripts default to `http://localhost:11434`; set `OLLAMA_HOST`,
  `OLLAMA_HOSTS`, or `OLLAMA_BASE_URL` if a different local endpoint is used.
- Diagnostics and checks: files named `CHECK*`, CNKI-WOS overlap notebooks, and
  low-frequency review notebooks are diagnostic or quality-control steps rather
  than default analysis-stage runners.

## Execution Notes

Many notebooks change the working directory to the release root before loading
`config/dataset.yml`. When running notebooks manually, launch them from this
release tree and confirm that relative paths resolve to `../dataset/`,
`../proc_output/`, `../stata_output/`, and related release folders.

No credentials are included in this folder. Do not publish a filled API-key file
or any private raw-data mirror.
