# Stata processed-data availability

This folder contains the selected analysis-ready Stata data included in the
public release. Other processed datasets are omitted because of their size or
applicable access, licensing, and redistribution restrictions. Researchers who
need an omitted file may contact the paper's first author at
[junhan.wang@szu.edu.cn](mailto:junhan.wang@szu.edu.cn).

The two `.dta.zip` archives retain repository-relative internal paths. Follow
the **Extracting the bundled Stata data** section in `../README.md` so the
extracted `.dta` files are placed where the analysis code expects them.

Included subfolders:

- `CN_CN`
- `CNKI`
- `WOS`

## Included files

The release contains the following 12 artifacts (about 0.19 GB as stored).
Exact stored sizes are recorded in `../config/processed_data_manifest.csv`.

| File | Contents |
| --- | --- |
| `CN_CN/DID_allfirm-level.dta.zip` | Full Chinese-firm patent-science panel; extract before use |
| `CN_CN/DID_listedfirm-level.dta` | Chinese publicly listed-firm patent-science panel |
| `CN_CN/ROS_event_table.dta` | Patent-science event-study estimates |
| `CN_CN/ROS_event_table_mo.dta` | Patent-science moderator event-study estimates |
| `CNKI/CNKI_DID.dta.zip` | Full Chinese-firm CNKI publication panel; extract before use |
| `CNKI/CNKI_listedfirm_DID.dta` | Publicly listed-firm CNKI publication panel |
| `CNKI/CNKI_listedfirm_withsubs.dta` | CNKI listed-firm publication counts including subsidiaries |
| `CNKI/CNKI_event_table.dta` | CNKI event-study estimates |
| `WOS/CN_WOS_DID_listed.dta` | Chinese publicly listed-firm WOS publication panel |
| `WOS/US_WOS.dta` | U.S.-firm WOS publication data |
| `WOS/WOS_CN_listed_with_subs.dta` | WOS listed-firm publication counts including subsidiaries |
| `WOS/WOS_event_table.dta` | WOS event-study estimates |

Matched-sample panels, the full Chinese-firm WOS panel, moderator panels, and
other upstream or supplementary inputs are not included. The saved event-study
estimates can be inspected without those inputs, but regenerating them requires
the data named in the relevant analysis scripts. See `../README.md` for the
master-workflow limitations and an example that uses only bundled data.

## Public-release privacy note

Before public release, unused direct identifiers and identifying location or
contact fields were removed from the included Stata data. Removed fields include
stock and security identifiers, unified social credit codes, securities-affairs
representatives, postal codes, ISINs, company-registration codes, precise office
and registered-location coordinates, city and province fields, Qichacha record
identifiers, and unused corporate or firm identifiers.

Identifiers required for fixed-effects estimation were retained as existing
internal analytical identifiers or converted to pseudonymous identifiers. In
particular, `ListedCoID` in the CN patent-science listed-firm panel and
`Symbol_id` in the CNKI listed-firm panel were remapped to sequential
public-release identifiers. The stock-code-like `firm_id` variables in the CNKI
and WOS subsidiary/publication process tables were similarly remapped. These
transformations preserve row order and firm-group membership without retaining
the original identifier values.

### Anonymization operations by file

The following operations were applied to the public-release copies. Variable
names are reported exactly as they appeared in the original Stata files.

- `CN_CN/DID_listedfirm-level.dta`
  - Removed: `Symbol`, `firm_id`, `SecurityID`, `Zipcode`,
    `SecurityConsultant`, `SocialCreditCode`, `Lng`, `Lat`, `ISIN`, `Crcd`,
    `RegisterLongitude`, `RegisterLatitude`, `PROVINCECODE`, `PROVINCE`,
    `CITYCODE`, and `CITY`.
  - Replaced `ListedCoID` with sequential pseudonymous identifiers while
    preserving the original firm groupings.

- `CNKI/CNKI_DID.dta.zip`
  - Removed: `统一社会信用代码`, `corporate_id`, and `firm_qcc_id`.
  - Retained the analytical `firm_id` unchanged because it is required by the
    released fixed-effects specifications.

- `CNKI/CNKI_listedfirm_DID.dta`
  - Removed: `Symbol`, `SocialCreditCode`, `corporate_id`, `ListedCoID`,
    `SecurityID`, `Zipcode`, `SecurityConsultant`, `Lng`, `Lat`, `ISIN`,
    `Crcd`, `RegisterLongitude`, `RegisterLatitude`, `PROVINCECODE`,
    `PROVINCE`, `CITYCODE`, and `CITY`.
  - Replaced `Symbol_id` with sequential pseudonymous identifiers while
    preserving the original firm groupings.

- `CNKI/CNKI_listedfirm_withsubs.dta`
  - No variables were removed.
  - Replaced the stock-code-like `firm_id` with sequential pseudonymous
    identifiers while preserving the original firm groupings.

- `WOS/CN_WOS_DID_listed.dta`
  - Removed: `Symbol`, `ListedCoID`, `SecurityID`, `Zipcode`,
    `SecurityConsultant`, `SocialCreditCode`, `Lng`, `Lat`, `ISIN`, `Crcd`,
    `RegisterLongitude`, `RegisterLatitude`, `PROVINCECODE`, `PROVINCE`,
    `CITYCODE`, and `CITY`.
  - Retained the existing internal analytical identifier `firm_id_wos`
    unchanged.

- `WOS/WOS_CN_listed_with_subs.dta`
  - No variables were removed.
  - Replaced the stock-code-like `firm_id` with sequential pseudonymous
    identifiers while preserving the original firm groupings.

For every file, the number and order of observations were preserved. Values of
all retained non-identifier variables were left unchanged. Pseudonymous
identifiers were generated independently within each file: equal original
identifiers remain equal within that file, but the public identifiers must not
be used to link firms across different files.

Some removed identifiers remain referenced in upstream data-construction code
because they are needed to match restricted raw records before the final panels
are produced. They are not required by the downstream analysis blocks that load
the anonymized public-release files.
