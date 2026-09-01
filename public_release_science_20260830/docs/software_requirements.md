# Software Requirements Notes

This release contains both default analysis code and optional/raw-reconstruction
code. `requirements.txt` is the pinned Python environment file for the public
package set referenced by released notebooks and scripts.

## Python

The included `requirements.txt` covers the standard public Python dependencies
referenced by the released tree, including pandas, numpy, PyYAML, requests,
urllib3, dask, rapidfuzz, openai, ollama, nbconvert, nbformat, networkx, pyvis,
pandarallel, cleanco, tqdm, matplotlib, pdfplumber, unidecode, pyarrow,
openpyxl, xlrd, googletrans, and deep-translator.

Known archival/manual edge case: the optional notebook
`analytics/Sci_Pat/5_Supplementary_materials/F1_Alternative_outcome/02_USPTO_filedby_CN/03_match_EL_with_USpatents.ipynb`
imports `china_cities`. I could not verify a reliable public package pin for
that module from the local release context. If that archival notebook is needed,
provide a compatible `china_cities` module locally or replace the import with a
reviewer-approved public city/province term source.

The notebook `modules/CN_CN/POST1_process_country_keywords.ipynb` imports
`kw_matcher` after adding `modules/_utils/` to `sys.path`; this is a local helper
module shipped in the release, not an external package.

Public-release hygiene status is summarized in
`docs/submission_readiness_review_20260626.md`. If files change, recheck notebook
output hygiene, credential/cache artifacts, private local paths, and processed
manifest consistency before publishing.

## Stata

The Stata code declares `version 18.0` in the master runners. Many analysis
scripts rely on user-written Stata commands, including:

- `reghdfe`
- `ppmlhdfe`
- `winsor2`
- `esttab` / `estout`
- `cem`
- `distinct`
- `ivreghdfe`

Run the central setup script once before the Stata analyses:

```stata
do scripts/setup_stata_packages.do
```

The setup script installs `ftools`, `reghdfe`, `ppmlhdfe`, `winsor2`, `estout`,
`cem`, `distinct`, and `ivreghdfe` from SSC into the user's normal Stata PLUS
location. It requires an internet-enabled Stata session or equivalent manual SSC
package installation. It does not modify project data files.

## Execution Note

The public-release refresh did not execute Stata or rebuild the raw-data
pipeline. Validation is structural and hygiene-focused unless separately noted.

