/*******************************************************************************
Project: Robustness Checks - USPTO Patents Filed by Chinese Firms (Preparation)
Script: 04_Entity_list_match_patent_USPTO.do

Purpose
  - Build intermediate USPTO-based datasets needed for the robustness analysis
    using U.S. patents filed by Chinese firms.
  - Convert and clean Entity List match results, China location identifiers,
    patent technology fields, and science-citation nationality indicators.
  - Construct the merged patent-level sample of U.S. patents filed by Entity
    List / other Chinese firms.

Inputs
  - ${python_output}USpatents_EL_matches.csv
  - ${USpatents}g_location_disambiguated.tsv
  - ${USpatents}g_wipo_technology.tsv
  - ${CN_US}USpatents_reliance_science_include_foreign.dta
  - Additional USPTO raw/intermediate files referenced later in the script

Outputs (saved under ${stata_output})
  - USpatents_EL_matches.dta
  - USpatents_China_locationID.dta
  - USpatents_industry.dta
  - USpatents_whether_cite_science_basednation.dta
  - USpatents_filedby_CNfirms.dta
  - US_patents_filed_by_EL_otherCNfirms.dta

Notes
  - This script is a preparation step for downstream USPTO robustness scripts
    (e.g., `05_DID_USPTO.do`, `06_moderator_USPTO.do`,
    `07_knowledge_source_USPTO.do`, and `08_vintage_USPTO.do`).
*******************************************************************************/
* Run via `00_run_all_6.do` (depends on shared path globals set by the runner).

/*
Planned outputs in this script:
  (1) USpatents_EL_matches.dta
  (2) USpatents_China_locationID.dta
  (3) USpatents_industry.dta
  (4) USpatents_whether_cite_science_basednation.dta
  (5) USpatents_filedby_CNfirms.dta
  (6) US_patents_filed_by_EL_otherCNfirms.dta [important]
*/


********************************************************************************
************************************* Prepare **********************************
********************************************************************************

****************************** A. Convert File Types ****************************

import delimited ${python_output}USpatents_EL_matches.csv, clear
keep patent_id date
duplicates drop
gen filed_by_EL=1

gen list_time = date(date, "YMD")
format list_time %td

bys patent_id: egen early=min(list_time)
keep if list_time==early
keep patent_id filed_by_EL list_time
save ${stata_output}USpatents_EL_matches.dta, replace //var: patent_id filed_by_EL list_time


***************** B. China Location IDs (Individuals or Entities) **********

import delimited ${USpatents}g_location_disambiguated.tsv, bindquote(strict) clear
keep if disambig_country=="CN"
keep location_id disambig_country disambig_city
rename disambig_country country
rename disambig_city city
order location_id country city
save ${stata_output}USpatents_China_locationID.dta, replace //var: location_id country city


********************** C. Industry Labels for All Firms ***********************

import delimited ${USpatents}g_wipo_technology.tsv, bindquote(strict) clear
keep if wipo_field_sequence==0
keep patent_id wipo_field_id wipo_field_title
tostring patent_id, replace
save ${stata_output}USpatents_industry.dta, replace //var: patent_id wipo_field_id wipo_field_title


**************** D. Science-Citation Source Indicators (USPTO Patents)  ********

use ${CN_US}USpatents_reliance_science_include_foreign.dta, clear

keep if authororder==-1 //last author
rename pub_year paperyear

keep patent_id paperid country paperyear
duplicates drop
sort patent_id paperid country

* cite paper num
bys patent_id:gen cite_paper_num=_N

* (1) cite foreign science
gen foreign_sci=0
replace foreign_sci=1 if country!="China"
bys patent_id: egen cite_foreign_sci=max(foreign_sci) //Mark whether this patent cites foreign science
label var cite_foreign_sci "whether this patent cite foreign science"

* (2) cite US science
gen us_sci=0
replace us_sci=1 if country=="USA"
bys patent_id: egen cite_us_sci=max(us_sci) //Mark whether this patent cites US science
label var cite_us_sci "whether this patent cite US science"

* (3) cite non-US foreign science
* Note: code below is preserved as-is for public release (original logic unchanged).
gen nonus_foreign_sci=0
replace nonus_foreign_sci=1 if country!="China" & country!="USA"
bys patent_id: egen cite_nonus_foreign_sci=max(nonus_foreign_sci) //Mark whether this patent cites non-US foreign science
label var cite_nonus_foreign_sci "whether this patent cite non-US foreign science"

* (4) cite Chinese science
gen cn_sci=0
replace cn_sci=1 if country=="China"
bys patent_id: egen cite_cn_sci=max(cn_sci) //Mark whether this patent cites China science
label var cite_cn_sci "whether this patent cite China science"

* relative ratio
bys patent_id: egen cite_us_paper_num=sum(us_sci)
bys patent_id: egen cite_nonusforeign_paper_num=sum(nonus_foreign_sci)
gen relative_ratio = cite_us_paper_num/cite_nonusforeign_paper_num
label var relative_ratio "# of US papers / # of non-US foreign papers"

bys patent_id: egen paperyear_mean = mean(paperyear)
bys patent_id: egen paperyear_med = median(paperyear)
bys patent_id: egen paperyear_min = min(paperyear)
bys patent_id: egen paperyear_max = max(paperyear)

keep patent_id cite_paper_num cite_foreign_sci cite_us_sci cite_nonus_foreign_sci cite_cn_sci relative_ratio paperyear_*
duplicates drop

* gen whether the patent cite science, and merge application year and grant year
gen cite_science=1

* merge grant year
merge m:1 patent_id using ${CN_US}USpatents_grtyr.dta //_merge=1 is zero

replace cite_paper_num=0 if _merge==2
replace cite_science=0 if _merge==2
replace cite_foreign_sci=0 if _merge==2
replace cite_us_sci=0 if _merge==2
replace cite_nonus_foreign_sci=0 if _merge==2

drop _merge

* merge application year
merge m:1 patent_id using ${CN_US}USpatents_appyr.dta
drop if _merge==1
drop _merge

label var cite_science "Indicator var. =1 means this patent cited papers"
label var cite_paper_num "num of papers cited by patent. =0 means this patent doesn't cite any papers"

order patent_id cite_science cite_foreign_sci cite_us_sci cite_nonus_foreign_sci cite_cn_sci cite_paper_num relative_ratio appyr grtyr
save ${stata_output}USpatents_whether_cite_science_basednation.dta, replace //var: patent_id cite_science cite_paper_num cite_foreign_sci cite_us_sci cite_nonus_foreign_sci appyr grtyr


********************************************************************************
**************************** Entity list patent-level **************************
********************************************************************************

**************************** A. Match With USPTO Patents ************************

import delimited ${USpatents}g_assignee_disambiguated.tsv, bindquote(strict) clear

rename disambig_assignee_individual_nam assignee_individual_name_first
rename v5 assignee_individual_name_last
sort patent_id assignee_sequence
rename disambig_assignee_organization organization

merge m:1 location_id using ${stata_output}USpatents_China_locationID.dta
keep if _merge==3
drop _merge

keep if assignee_type==3 //only keep US patnets filed by Chinese firms
keep if assignee_sequence==0
save ${stata_output}USpatents_filedby_CNfirms.dta, replace

drop assignee_id assignee_individual_name_first assignee_individual_name_last location_id assignee_type assignee_sequence

* (1) merge with US patents filed by firms on the Entity list
merge 1:1 patent_id using ${stata_output}USpatents_EL_matches.dta
drop if _merge==2 //filed by entity list but not firms
drop _merge
replace filed_by_EL=0 if filed_by_EL==.
tab filed_by_EL

* (2) merge with whether cite science
merge 1:1 patent_id using ${stata_output}USpatents_whether_cite_science_basednation.dta
drop if _merge==2
drop _merge

merge 1:1 patent_id using ${stata_output}USpatents_industry.dta
drop if _merge==2
drop _merge


order patent_id appyr grtyr organization

label var filed_by_EL "whether filed by firms in the Entity List"
label var list_time "Time to be listed on the Entity List"

rename filed_by_EL EL

save ${stata_output}US_patents_filed_by_EL_otherCNfirms.dta, replace //Patent-level
