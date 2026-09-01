# Processed Data Scope

This public release includes selected process data so readers can reproduce or
inspect the main analysis from an analysis-ready stage, without requiring the
full private raw-data workspace.

## Included

- Analysis-ready Stata DID panels for CN patent-science, CNKI, and WOS analyses.
- CEM-matched CN patent-science panels, moderator/mediator panels,
  listed-firm panels, selected alternative-outcome panels, and saved
  event-study coefficient tables.
- CNKI and WOS listed-firm analysis panels, including the CEM-matched panels
  used by the listed-firm regressions and dynamic-effect scripts, plus saved
  event tables.

The file-level inventory is in `processed_data_manifest.csv`. In the current
public copy, the included process-data layer contains 24 files under
`stata_output/`, totaling about 1.11 GB in decimal units. Several large panels
are included as `.dta.zip` files. There are no data files currently included
under `proc_output/`; that folder is retained as the expected location for
regenerated Python process outputs.

## Excluded

- The raw `dataset/` folder.
- Temporary Stata files under `temp_output/`.
- Current `proc_output/` data files and full raw-like exports such as
  `proc_output/WOS/WOS_2010_2023.csv`.
- WOS/CNKI upstream matching outputs and some panels that were present in
  earlier internal manifests but are not in this lean public copy, including
  utility-model negative-control panels and the unlisted WOS all-firm DID panel.
- Very large patent-level reconstruction files and other upstream intermediates
  that are not needed for the retained analysis-ready `stata_output/` layer.
- Optional archival/reviewer/experimental scripts may still require excluded
  upstream files or third-party raw data; those scripts are retained for
  transparency but are not the default reproduction path.

## Reproduction Boundary

Unzip any included `.dta.zip` files, then use the included `stata_output/` data
to rerun the release-supported Stata analysis stages identified in
`submission_readiness_review_20260626.md`, and compare against `figure_output/`
and `table_output/`.

To fully reconstruct the processed data from raw sources, obtain the raw data
described in `raw_data_inventory.md`, place them under `dataset/`, and run the
preprocessing code in `modules/` and the upstream Stata cleaning scripts.
