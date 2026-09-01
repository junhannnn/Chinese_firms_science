# Excluded Data Policy

This public-release copy excludes the large raw-data folder and large
nonessential upstream process/intermediate outputs. It includes selected
analysis-ready Stata outputs needed by the public analysis boundary; see
`processed_data_manifest.csv` and `processed_data_scope.md`.

The excluded source areas include:

- `dataset/`
- current data files under `proc_output/`
- `temp_output/CN_CN/`
- `temp_output/CNKI/`
- `temp_output/WOS/`
- raw-like or oversized Python intermediates, including the full WOS source
  export (`proc_output/WOS/WOS_2010_2023.csv`)
- patent-level and raw reconstruction `.dta` files not required by the bundled
  analysis-ready boundary
- upstream WOS/CNKI matching outputs and CEM panels that are not listed in the
  current `processed_data_manifest.csv`

The public bundle keeps selected final `figure_output/` and `table_output/`
artifacts because they are useful for checking retained submitted-paper
outputs. It also keeps selected `stata_output/` files so the retained analyses
can be inspected or rerun without redistributing the full private/raw
workspace. Stata logs are not included in this copy.

The public release intentionally does not include the analysis code, logs, or
result tables for the following supplementary analyses:

- the within-treatment/not-yet-treated analysis (Table S32);
- the CSDID/Callaway-Sant'Anna analysis (Table S33); and
- the logit and complementary log-log selection models (Table S6).
