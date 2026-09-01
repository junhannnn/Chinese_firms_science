# Geopolitical tensions with the U.S. accelerate Chinese firms’ leveraging of science

Public code-and-output release for the Science submission:

**Geopolitical tensions with the U.S. accelerate Chinese firms’ leveraging of science**

## What is included

- `modules/`: preprocessing code for CN patent-paper matching, CNKI, WOS,
  shared helpers, and the OpenAlex institution step used by CN_CN preprocessing.
  This folder is mostly Python notebooks/scripts, but it also includes two CNKI
  Stata preprocessing scripts: `modules/CNKI/04_paperlevel_to_firmlevel.do` and
  `modules/CNKI/08_data_cleaning.do`.
- `analytics/`: Stata analysis code for background figures, the main
  science-patent analyses, CNKI, and WOS.
- [analytics/Main text figures_final version/](<analytics/Main text figures_final version/>): self-contained editing-team replotting
  packages for Figures 1A and 1B. Each package includes a 28-row plotting table
  in Stata and Excel formats, a portable Stata 18 do-file, editable `.gph`
  output, a PDF, and figure-specific documentation.
- `stata_output/`: selected analysis-ready Stata panels and event tables for the
  public analysis boundary; several large panels are bundled as `.dta.zip`.
- `proc_output/`: retained as the documented location for regenerated Python
  process outputs; this lean public copy does not currently include proc-output
  data files.
- `figure_output/`: compact final figure outputs copied from the working
  project.
- `table_output/`: selected compact final table outputs copied from the working
  project.
- `config/dataset.yml`: relative path template for local reproduction.
- `requirements.txt`: pinned Python packages for the released public package
  set.
- `scripts/setup_stata_packages.do`: central installer for user-written Stata
  packages used by the release.
- `scripts/sanitize_public_release.py`: structural public-release checker and
  processed-data manifest refresher.
- `docs/`: raw-data inventory, processed-data manifest, processed-data scope
  notes, excluded data policy, software notes, and readiness review.

## Main-text figure replotting

The Figure 1 packages under [analytics/Main text figures_final version/](<analytics/Main text figures_final version/>) use only processed
event-study coefficients and 95% confidence intervals; they do not require the
firm-level estimation samples. Figure 1A contains all four series from
`stata_output/CN_CN/ROS_event_table.dta`. Figure 1B contains the matched-sample
groups B and D from `stata_output/CNKI/CNKI_event_table.dta` and
`stata_output/WOS/WOS_event_table.dta`.

To reproduce a figure, open Stata 18 or later, change the working directory to
the corresponding `Figure1A` or `Figure1B` package folder, and run `do`
[Figure1A.do](<analytics/Main text figures_final version/Figure1A/Figure1A.do>) or `do`
[Figure1B.do](<analytics/Main text figures_final version/Figure1B/Figure1B.do>). The do-file overwrites the local `.gph`
and PDF outputs. Figure 1B stores the final `x_plot` offsets in both plotting-data
formats so the left-to-right positions follow its interleaved CNKI/WOS legend;
the do-file validates and uses those stored coordinates without recalculation.
See [README_Figure1B.txt](<analytics/Main text figures_final version/Figure1B/README_Figure1B.txt>)
for the series-specific offsets.

## What is not included

Raw data and large nonessential upstream intermediates are not included because
many are large and/or third-party data products. See:

- `docs/raw_data_inventory.md`
- `docs/processed_data_scope.md`
- `docs/excluded_data_policy.md`

The included process-data layer is listed in
`docs/processed_data_manifest.csv`. In the current public copy, that manifest
covers the 24 included `stata_output/` files (about 1.11 GB in decimal units),
including compressed `.dta.zip` replacements and CEM-matched listed-firm panels
for the CN patent-science, CNKI, and WOS analyses. Full reconstruction from raw
data, or rerunning upstream
WOS/CNKI/CN_CN preprocessing, still requires the raw and intermediate inputs
described in `docs/raw_data_inventory.md` and
`docs/submission_readiness_review_20260626.md`.

## Public-use notes

The selected `stata_output/` files are present in this folder. Unzip the bundled
`.dta.zip` files before using those panels directly in Stata. If this release is
shared through a Git repository, confirm whether the hosting workflow should
track the bundled process-data files directly or publish them as a separate
release asset.

**Please find all `.zip` files and unzip them with: `find . -name "*.zip" -type f -exec unzip -o {} \;`**

Optional upstream, archival, and LLM-assisted reconstruction scripts use
release-relative paths or documented environment-variable defaults instead of
private local paths/endpoints. They still require excluded raw/source data
before full raw-data reconstruction can be attempted.

Before publishing or after changing files, recheck notebook output hygiene,
credential/cache artifacts, private local paths, and the consistency of
`docs/processed_data_manifest.csv` against the included `proc_output/` and
`stata_output/` files. If process-data files are intentionally added or removed,
update the manifest paths, byte counts, and purpose notes accordingly. Run
`python scripts/sanitize_public_release.py --check` for the structural preflight,
or add `--refresh-processed-manifest` to rebuild the processed-data manifest
from the live `proc_output/` and `stata_output/` files.

## Reproduction outline

1. Install Python dependencies from `requirements.txt`; see
   `docs/software_requirements.md` for the one archival/manual Python module
   caveat.
2. In Stata, run `do scripts/setup_stata_packages.do` once in an internet-enabled
   session to install the required SSC user-written commands.
3. To reproduce from the included analysis-ready data, start with the public
   boundary described in `docs/submission_readiness_review_20260626.md`. Do not
   treat every `00_run_all*.do` file as runnable from the bundled data.
4. To rebuild the analysis-ready data from raw sources, place raw data under the
   `dataset/` subfolders documented in `docs/raw_data_inventory.md`, check or
   edit `config/dataset.yml`, and run the relevant Python notebooks under
   `modules/` plus the upstream Stata preprocessing code.

The primary active WOS preprocessing code is in `modules/WOS`; the older private
WOS preprocessing version is not included.

## Credential and endpoint note

No API keys are included. OpenAI-assisted steps use the `OPENAI_API_KEY`
environment variable or a local, unpublished `config/openai_api_key.txt` file.
Ollama-assisted steps default to `http://localhost:11434`; set `OLLAMA_HOST`,
`OLLAMA_HOSTS`, or `OLLAMA_BASE_URL` if your local LLM server uses another URL.
Do not publish a filled key file.

## Verification

This folder was created by copying into a new public-release directory and then
sanitizing only the copied files. The original project files were not edited.

The current structural checks support publishing this folder as a code-plus-
selected-analysis-output public release, with limitations documented in
`docs/submission_readiness_review_20260626.md`.

## Contact

If you have any questions or suggestions about the code or data, please contact
junhan.wang@szu.edu.cn.
