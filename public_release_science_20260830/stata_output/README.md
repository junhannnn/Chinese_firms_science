# Stata processed outputs

The files generated from the Stata code are located in this section, but they
are not fully uploaded due to their large size. This section only contains
important data; unimportant data are omitted because including everything would
result in a very large file. If you need the specific files, you can contact
the first author to request them.

The archives use two internal path layouts, so they must be extracted according
to their filename type. Follow the **Extracting the bundled Stata data** section
in `../README.md`; a single generic unzip command will not place every `.dta`
file in the directory expected by the analysis code.

Included subfolders:

- `CN_CN`
- `CNKI`
- `WOS`

See `../docs/processed_data_manifest.csv` for the file-level inventory of the
expected Stata process outputs and `../docs/processed_data_scope.md` for the
inclusion rule.

## Public-release privacy note

Before public release, firm-identifying string fields were removed from the
included Stata data files where they appeared. The removed fields include
addresses, secretary/contact fields, websites, legal-representative fields,
business-scope and narrative text fields, group-affiliation fields, and
corporate name. A post-removal scan found no firm-name-like string values outside
generic organization-type or industry-category fields. The CNKI files retain
`corporate_id` identifiers for analysis linkage; these are identifiers rather
than firm-name strings.
