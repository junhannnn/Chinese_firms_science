# Raw data

Raw data are not included in this public-release folder because the source
datasets are large and come from third-party data providers. Python input
locations are configured in `../config/dataset.yml`:

| Configuration key | Subfolder under this directory | Source data |
| --- | --- | --- |
| path_openalex | `OpenAlex/` | OpenAlex snapshots and institution/publication metadata |
| path_pcs | `PCS/` | Patent-to-science citation links |
| path_wos | `WOS/` | Web of Science publication and affiliation records |
| path_cnki | `CNKI/` | CNKI publication records |
| path_other | `Miscellaneous/` | Auxiliary inputs named in the preprocessing scripts |
| path_csmar | `CSMAR_subsidiary/` | Listed-firm subsidiary records |
| path_cnpat | `CN_patents/` | Chinese patent records |
| path_uspat | `US_patents/` | U.S. patent records |

The Stata scripts define their own path globals and may also use `CSMAR/` and
`DISCERN/`. Review each script's header and input commands for the exact source
filenames and locations; the Python configuration does not configure Stata.
Create any required folders and supply the external files before running the
corresponding preprocessing steps.

Source data and most processed intermediates are omitted because of their size
or applicable access, licensing, and redistribution restrictions. Researchers
who need an omitted input may contact the first author at
[junhan.wang@szu.edu.cn](mailto:junhan.wang@szu.edu.cn). See `../README.md` for
what can be run from the bundled data.
