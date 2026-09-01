
/*******************************************************************************
Project: CN Patents (1985–2025) — Analysis Sample Construction
Script: 04_build_analysis_sample.do

Purpose
  - Build a patent-level dataset that flags whether a CN patent cites scientific
    papers and characterizes cited science by:
      - author nationality (last author's country)
      - language
      - paper-year statistics
      - ratios and weighted shares

Inputs (from ${stata_output})
  - CNpatents_reliance_science.dta            (patent–paper level)
  - CNpatents_year.dta                        (all patents, incl. zero-citation)
  - CNpatents_type_country.dta                (to restrict to Chinese entities)
  - fapp_foundyr_fpatyr.dta (if merged later in the script)

Outputs (saved under ${stata_output})
  (1) Chinese_patents_whether_cite_science_basednation.dta  [IMPORTANT]
      - patent level
      - restricted to patents filed by Chinese entities (`app_country` equals the China value)

Notes
  - Patents with zero science citations are included by merging to all patents
    and setting citation-related variables to 0.
*******************************************************************************/
* Run via `00_run_all_1.do` (depends on shared path globals set by the runner).



********************************************************************************
********************** A. Patents: whether cite science ************************
********************************************************************************

/*** Classify cited science using last author's nationality ***/
use "${stata_output}CNpatents_reliance_science.dta", clear

/* Flag if a patent cites papers from multiple countries (based on 'country') */
bysort patent_id: gen flag = (country != country[1])
bysort patent_id: egen multi_country = max(flag)
drop flag


/*************************
  (1) Citation indicators
**************************/

* (1) Cite CN science (mainland China)
gen cn_sci = 0
replace cn_sci = 1 if country == "China"
bys patent_id: egen cite_cn_sci = max(cn_sci)
label var cite_cn_sci "whether this patent cite Chinese science"

* (2) Cite foreign science (non-China)
gen foreign_sci = 0
replace foreign_sci = 1 if country != "China"
bys patent_id: egen cite_foreign_sci = max(foreign_sci)
label var cite_foreign_sci "whether this patent cite foreign science"

* (3) Cite US science
gen us_sci = 0
replace us_sci = 1 if country == "USA"
bys patent_id: egen cite_us_sci = max(us_sci)
label var cite_us_sci "whether this patent cite US science"

* (4) Cite non-US foreign science (non-China and non-USA)
gen nonus_foreign_sci = 1
replace nonus_foreign_sci = 0 if country == "China" | country == "USA"
bys patent_id: egen cite_nonus_foreign_sci = max(nonus_foreign_sci)
label var cite_nonus_foreign_sci "whether this patent cite non-US foreign science"


/*************************
  (2) Citation counts
**************************/

* Number of cited papers within patent
bys patent_id: gen cite_paper_num = _N
label var cite_paper_num "num of papers cited by patent. =0 means this patent doesn't cite any papers"

* By-country paper counts
bys patent_id: egen cite_cn_paper_num      = sum(cn_sci)
bys patent_id: egen cite_foreign_paper_num = sum(foreign_sci)
bys patent_id: egen cite_us_paper_num      = sum(us_sci)
bys patent_id: egen cite_nonusforeign_paper_num = sum(nonus_foreign_sci)


/*************************
  (3) Ratios / shares
**************************/

gen relative_ratio1 = cite_cn_paper_num / cite_foreign_paper_num
label var relative_ratio1 "# of CN papers / # of foreign papers"

gen relative_ratio2 = cite_us_paper_num / cite_nonusforeign_paper_num
label var relative_ratio2 "# of US papers / # of non-US foreign papers"

gen cn_sci_ratio = cite_cn_paper_num / cite_paper_num
label var cn_sci_ratio "# of CN papers / # of all papers"

gen foreign_sci_ratio = cite_foreign_paper_num / cite_paper_num
label var foreign_sci_ratio "# of foreign papers / # of all papers"

gen us_sci_ratio = cite_us_paper_num / cite_paper_num
label var us_sci_ratio "# of US papers / # of all papers"

gen nonusforeign_sci_ratio = cite_nonusforeign_paper_num / cite_paper_num
label var nonusforeign_sci_ratio "# of non-US foreign papers / # of all papers"


/*************************
  (4) Language indicators
**************************/

gen language_CN = 0
replace language_CN = 1 if language == "Chinese"

gen language_EN = 0
replace language_EN = 1 if language == "English"

bys patent_id: egen cite_cn_lang = max(language_CN)
bys patent_id: egen cite_en_lang = max(language_EN)

label var cite_cn_lang "whether this patent cites Chinese-language papers"
label var cite_en_lang "whether this patent cites English-language papers"

gen cite_cn_lang_ratio = cite_cn_lang / cite_paper_num
gen cite_en_lang_ratio = cite_en_lang / cite_paper_num


/*************************
  (5) Paper-year statistics
**************************/

bys patent_id: egen paperyear_mean = mean(paperyear)
bys patent_id: egen paperyear_med  = median(paperyear)
bys patent_id: egen paperyear_min  = min(paperyear)
bys patent_id: egen paperyear_max  = max(paperyear)


/*************************
  (6) Weighted shares (within-patent citation composition)
**************************/

* 1) Numerators: counts within patent
bys patent_id: egen n_cn            = total(cn_sci)
bys patent_id: egen n_foreign       = total(foreign_sci)
bys patent_id: egen n_us            = total(us_sci)
bys patent_id: egen n_nonus_foreign = total(nonus_foreign_sci)

* 2) Weighted shares
gen w_cn            = n_cn / cite_paper_num
gen w_foreign       = n_foreign / cite_paper_num
gen w_us            = n_us / cite_paper_num
gen w_nonus_foreign = n_nonus_foreign / cite_paper_num

label var w_cn            "Share of cited science from China within patent (weighted)"
label var w_foreign       "Share of cited science from foreign (non-China) within patent (weighted)"
label var w_us            "Share of cited science from USA within patent (weighted)"
label var w_nonus_foreign "Share of cited science from non-US foreign within patent (weighted)"


/*** Collapse to patent level ***/
keep patent_id cite_paper_num cite_cn_sci cite_foreign_sci cite_us_sci cite_nonus_foreign_sci ///
     relative_ratio1 relative_ratio2 foreign_sci_ratio cn_sci_ratio us_sci_ratio nonusforeign_sci_ratio ///
     cite_cn_lang cite_en_lang cite_cn_lang_ratio cite_en_lang_ratio ///
     paperyear_mean paperyear_med paperyear_min paperyear_max ///
     multi_country w_cn w_foreign w_us w_nonus_foreign

duplicates drop   // patent–paper -> patent level

save "${temp_output}temp_patent_level.dta", replace



********************************************************************************
********************* Merge patent-level variables to all patents **************
********************************************************************************

use "${temp_output}temp_patent_level.dta", clear

/*** (1) Mark whether patent cites science; merge patent-year data ***/
gen cite_science = 1
rename patent_id apn

merge 1:1 apn using "${stata_output}CNpatents_year.dta"
* _merge==2 corresponds to patents with zero matched science citations; keep
* them in the universe and set citation variables to 0 below.

* For patents with no matched science citations (_merge==2), set relevant vars to 0
local var_list cite_paper_num ///
    cite_science cite_cn_sci cite_foreign_sci cite_us_sci cite_nonus_foreign_sci ///
    cite_cn_lang cite_en_lang

foreach var of local var_list {
    replace `var' = 0 if _merge == 2
}

drop _merge
label var cite_science "Indicator var. =1 means this patent cited papers"


/*** (2) Exclude foreign-filed patents (keep the China value in `app_country`) ***/
merge 1:1 apn using "${stata_output}CNpatents_type_country.dta"
* app_country is used here to keep Chinese-filed patents only.
drop if _merge == 2
drop _merge

drop if app_country != "中国"


/*** (3) Merge firm founding year proxy (founding year if available; else first patent year) ***/
merge m:1 fapp using "${stata_output}fapp_foundyr_fpatyr.dta"
* Merge firm-level founding-year proxy at first-applicant-name level.
drop if _merge == 2
drop _merge


/*** (4) Merge applicant type ***/
merge 1:1 apn using "${stata_output}Chinese_patents_filed_by_diff_types.dta"
* Bring applicant-type classification (firm/university/other) to patent level.
drop if _merge == 2
drop _merge


/*************************
  Final selection / order
**************************/

keep apn appyr grtyr foundyr_fpatyr fapp type ///
     cite_science cite_paper_num cite_cn_sci cite_foreign_sci cite_us_sci cite_nonus_foreign_sci ///
     relative_ratio1 relative_ratio2 foreign_sci_ratio cn_sci_ratio us_sci_ratio nonusforeign_sci_ratio ///
     cite_cn_lang cite_en_lang cite_cn_lang_ratio cite_en_lang_ratio ///
     paperyear_mean paperyear_med paperyear_min paperyear_max ///
     multi_country w_cn w_foreign w_us w_nonus_foreign

order apn appyr grtyr foundyr_fpatyr fapp type ///
      cite_science cite_paper_num cite_cn_sci cite_foreign_sci cite_us_sci cite_nonus_foreign_sci ///
      relative_ratio1 relative_ratio2 foreign_sci_ratio cn_sci_ratio us_sci_ratio nonusforeign_sci_ratio ///
      cite_cn_lang cite_en_lang cite_cn_lang_ratio cite_en_lang_ratio ///
      paperyear_mean paperyear_med paperyear_min paperyear_max ///
      multi_country w_cn w_foreign w_us w_nonus_foreign

save "${stata_output}Chinese_patents_whether_cite_science_basednation.dta", replace

erase "${temp_output}temp_patent_level.dta"
