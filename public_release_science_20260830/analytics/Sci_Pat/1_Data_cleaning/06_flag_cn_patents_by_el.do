
/*******************************************************************************
Project: CN Patents — Flag Entity List vs Other Firms (Patent Level)
Script: 06_flag_cn_patents_by_el.do

Purpose
  - Create the universe of CN patents filed by Chinese firms and mark:
      [A] whether the patent relies on science (NPL / paper citations)
      [B] whether the patent is filed by Entity List firms (EL)

Inputs (from ${stata_output})
  - Chinese_patents_filed_by_firm.dta
  - Chinese_patents_whether_cite_science_basednation.dta
  - Entity_List_China_withpatents_manual.dta
  - CNpatents_year.dta

Outputs (saved under ${stata_output})
  (1) EL_patent_level.dta
      - patent level; EL match + paper citation count + years
  (2) Chinese_patents_filed_by_EL_otherfirms.dta   [IMPORTANT]
      - patent level; firm patents with science and EL indicators
  (3) fapp_standard.csv
      - unique standardized applicant names (for external processing)

Notes
  - EL_patent_level is constructed from NPL-citing patents merged to EL list,
    then merged to CNpatents_year for timing variables.
  - Final dataset merges firm patents + science measures + EL status.
*******************************************************************************/
* Run via `00_run_all_1.do` (depends on shared path globals set by the runner).



********************************************************************************
*********************** B. Entity List patent-level data ***********************
********************************************************************************

* Start from NPL-citation dataset (paper-level → collapse to patent-level count)
use ${stata_output}Chinese_npl_citations_both_sources.dta, clear

bys apn: gen paper_num = _N          // number of cited papers per patent
keep apn paper_num
duplicates drop                       // now patent-level

* Merge Entity List match (manual name cleaning version)
merge 1:1 apn using ${stata_output}Entity_List_China_withpatents_manual.dta
/*
_merge meanings here:
  1 = patent has NPL citations but NOT filed by an EL firm
  2 = patent filed by an EL firm but has NO NPL citations
  3 = patent has NPL citations AND is filed by an EL firm
*/

drop if _merge == 1                   // keep EL-filed patents (with/without NPL)
replace paper_num = 0 if _merge == 2  // EL-filed but no NPL → set paper count to 0
drop _merge

/*
Optional (currently disabled):
Append Huawei science-reliant patents (if maintained separately)
append using "huawei_patent_level.dta"
drop app-grtyr
replace entity_list = 1 if entity_list == .
*/

* Merge application year / grant year metadata
merge 1:1 apn using ${stata_output}CNpatents_year.dta
* Keep all EL-filed patents retained above and attach year metadata if present.
drop if _merge == 2
drop _merge

order apn appyr sxyr grtyr entity_list paper_num

save ${stata_output}EL_patent_level.dta, replace
// Vars include: apn appyr sxyr grtyr entity_list paper_num list_time ...


////////////////////////////////////////////////////////////////////////////////
************ Chinese patents: Entity List vs. other Chinese firms ***************
////////////////////////////////////////////////////////////////////////////////

/*
1) Chinese patents filed by Chinese firms
2) Merge science reliance measures [A]
3) Merge Entity List filing indicator [B]
*/

* Universe: patents filed by Chinese firms
use ${stata_output}Chinese_patents_filed_by_firm.dta, clear

* [A] Merge science reliance (already excludes foreign applicants)
merge 1:1 apn using ${stata_output}Chinese_patents_whether_cite_science_basednation.dta ///
    // get whether this patent cites science + related metrics
keep if _merge == 3
drop _merge

* [B] Merge EL patent-level indicator
merge 1:1 apn using ${stata_output}EL_patent_level.dta
/*
Note:
  - Here _merge==2 means "in EL_patent_level but not in firm-filed patents".
    This is expected because EL_patent_level can include non-firm applicants.
*/

* Preserve the full Chinese-firm patent universe and fill EL=0 for non-matches.
drop if _merge == 2
gen EL = 1
replace EL = 0 if _merge == 1
drop _merge

tab EL

* Keep analysis variables
keep apn appyr sxyr grtyr foundyr_fpatyr ///
    filed_by_firm EL entity_list cite_science cite_paper_num ///
    relative_ratio1 relative_ratio2 foreign_sci_ratio cn_sci_ratio us_sci_ratio nonusforeign_sci_ratio ///
    cite_cn_sci cite_foreign_sci cite_us_sci cite_nonus_foreign_sci list_time fapp fapp_standard ///
    cite_cn_lang cite_en_lang cite_cn_lang_ratio cite_en_lang_ratio ///
    paperyear_mean paperyear_med paperyear_min paperyear_max ///
    multi_country w_cn w_foreign w_us w_nonus_foreign

order apn appyr sxyr grtyr foundyr_fpatyr ///
    filed_by_firm EL entity_list cite_science cite_paper_num ///
    relative_ratio1 relative_ratio2 foreign_sci_ratio cn_sci_ratio us_sci_ratio nonusforeign_sci_ratio ///
    cite_cn_sci cite_foreign_sci cite_us_sci cite_nonus_foreign_sci list_time fapp fapp_standard ///
    cite_cn_lang cite_en_lang cite_cn_lang_ratio cite_en_lang_ratio ///
    paperyear_mean paperyear_med paperyear_min paperyear_max ///
    multi_country w_cn w_foreign w_us w_nonus_foreign

* Labels
label var filed_by_firm   "Filed by firms"
label var EL              "Filed by firms in the Entity List"
label var cite_science    "Indicator: patent cites science"
label var cite_paper_num  "Number of cited papers"

* Drop missing standardized applicant names
drop if fapp_standard == ""

save ${stata_output}Chinese_patents_filed_by_EL_otherfirms.dta, replace   // patent-level

* Export unique standardized applicant names
keep fapp_standard
duplicates drop
export delimited using ${stata_output}fapp_standard.csv, replace
