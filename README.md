# Geopolitical tensions with the U.S. accelerate Chinese firms’ leveraging of science

Code and analysis outputs for the paper.

## Contents

- `analytics/`: Stata analysis code organized by evidence source and
  supplementary-analysis family.
- `modules/`: Python data-cleaning scripts and notebooks, with Stata
  preprocessing steps; see Modules: Python data cleaning below.
- `stata_output/`: 12 analysis-ready data artifacts (10 `.dta` files
  and two `.dta.zip` archives), totaling about 0.19 GB as stored.
- `figure_output/` and `table_output/`: final results.
- `config/`: dataset paths, an API-key example, and the bundled-data inventory.

Raw data, most upstream intermediates, and Python process outputs are not
included. External input locations are described in
`dataset/README.md`.

## Modules: Python data cleaning

The `modules/` directory contains the Python scripts (`.py`) and Jupyter
notebooks (`.ipynb`) used to clean source records, standardize firm names, match
publications and patents, and construct variables for the Stata analyses.
The code is grouped by data source:

| Folder | Main cleaning and preparation tasks | Example files |
| --- | --- | --- |
| `modules/CNKI/` | Extract journal impact factors; clean publication and affiliation records; identify firms; standardize firm names; merge Qichacha corporate information; and supplement state-owned-enterprise classifications. | [Publication cleaning](modules/CNKI/02_clean_CNKI.ipynb), [firm-name standardization](modules/CNKI/03_standard_firm_name.ipynb), [corporate-data merge](modules/CNKI/06_merge.ipynb), [SOE classification](modules/CNKI/07_patch_with_ChatGPT_SOE.ipynb) |
| `modules/WOS/` | Prepare publication–author and affiliation records; identify countries and organization types; filter and standardize firms; match affiliation variants; and aggregate Chinese and U.S. firm publication measures. | [Publication–author preparation](modules/WOS/00a_WOS_paperauthor_info.ipynb), [country recognition](modules/WOS/01_country_recognition.py), [Chinese firm-name standardization](modules/WOS/04a_canonical_firms_CN.ipynb), [Chinese firm variables](modules/WOS/POST02a_calc_CN_variables.ipynb), [U.S. firm variables](modules/WOS/POST02b_calc_US_variables.ipynb) |
| `modules/CN_CN/` | Clean non-patent literature citations from IncoPat; match patent citations to OpenAlex and PCS records; identify publication years and affiliation countries; and combine patent–paper links from the available sources. | [Citation cleaning](modules/CN_CN/CN1_Clean_npl_IncoPat.ipynb), [OpenAlex matching](modules/CN_CN/CN2_reduce_match_db.ipynb), [country attribution](modules/CN_CN/OA3_process_country.ipynb), [combined citation output](modules/CN_CN/POST4_final_result.ipynb) |

Additional notebooks in `modules/CN_CN/1_Data_cleaning/` and
`modules/CN_CN/2_Prepare_data/` prepare business-information fields,
patent-applicant/firm-code links, and the countries of cited patents.
The CNKI chain also includes two Stata preprocessing steps:
`modules/CNKI/04_paperlevel_to_firmlevel.do` aggregates paper records to firms,
and `modules/CNKI/08_data_cleaning.do` prepares the final panel.

To work with these modules:

1. Obtain the source files required by the chosen script or notebook. Raw data
   and most intermediate Python outputs are not bundled with this release.
2. Review `config/dataset.yml` and the file's input/output settings. Several
   notebooks change the working directory, while some WOS scripts read filenames
   relative to the current directory; check these settings before execution.
3. Use a Python environment with the packages required by that step; the package
   list is in `requirements.txt`. Open notebooks in Jupyter and follow their
   cells and input dependencies. The numbered names identify processing stages,
   but the modules are not a single automated end-to-end runner.
4. For steps that call OpenAI, provide your own `OPENAI_API_KEY`. For steps that
   call Ollama, run the model named in the code and configure `OLLAMA_HOST` or
   `OLLAMA_HOSTS` where supported. These services are not required for the
   Stata-only example below.

Most Python outputs are written under `proc_output/`, with Stata-ready
outputs under `stata_output/`; individual files define their exact destinations.
For questions about the cleaning and matching steps, contact
the paper's first author at [junhan.wang@szu.edu.cn](mailto:junhan.wang@szu.edu.cn).

## Quick start

1. Start Stata 18 or later from the release root.
2. Run `do scripts/setup_stata_packages.do` once to install the
   required user-written commands.
3. Extract the two bundled Stata archives as described below.
4. Run an analysis whose inputs are included, such as the CNKI baseline example
   below. To run a complete master workflow, first obtain its omitted inputs.
   Review each child script's header for the exact files it requires.

Python is needed for upstream preprocessing and the structural release check;
it is not needed to run Stata analyses from the bundled data. The Python
preprocessing code and package list are in `modules/` and `requirements.txt`.

## Extracting the bundled Stata data

The two `.dta.zip` archives retain their repository-relative paths. Extract
them from the release root while preserving those paths:

```powershell
Expand-Archive -LiteralPath "stata_output/CN_CN/DID_allfirm-level.dta.zip" -DestinationPath "."
Expand-Archive -LiteralPath "stata_output/CNKI/CNKI_DID.dta.zip" -DestinationPath "."
```

After extraction, the corresponding `.dta` files should be located beside
their archives under `stata_output/CN_CN/` and `stata_output/CNKI/`.
Allow approximately 2.91 GB of additional disk space for the extracted files.

## Example using only bundled data

After extracting the CNKI archive and installing the Stata commands, run this
from the release root to reproduce the full-sample CNKI summary statistics and
baseline regression table:

```stata
global stata_output "./stata_output/CNKI/"
global table_output "./table_output/CNKI/"
do "analytics/CNKI/01_CNKI_DID.do"
```

## Data availability

Some processed datasets are omitted because of their size or applicable access,
licensing, and redistribution restrictions. Researchers who need an omitted
file may contact the paper's first author at
[junhan.wang@szu.edu.cn](mailto:junhan.wang@szu.edu.cn).
