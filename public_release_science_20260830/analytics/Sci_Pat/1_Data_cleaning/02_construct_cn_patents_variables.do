
/*******************************************************************************
Project: CN Patents (1985–2025) — Variable Construction
Script: 02_construct_cn_patents_variables.do

Purpose
  - Construct core patent-level datasets and derived variables used in ROS/EL
    linkage and analysis (years, applicant type/country, firm-only samples, etc.).
  - Import cleaned NPL citation output from Python and save as Stata.

Inputs
  - ${python_output}Chinese_npl_citations_both_sources.csv
  - ${CN_patents}date.dta
  - ${CN_patents}app.dta
  - (and other ${CN_patents} components built in Script 01)

Outputs (saved under ${stata_output})
  (1) Chinese_npl_citations_both_sources.dta
  (2) Chinese_patents_filed_by_diff_types.dta
  (3) Chinese_patents_filed_by_firm.dta
  (4) CNpatent_pubid_allyears.dta
  (5) CNpatents_type_country.dta
  (6) CNpatents_year.dta
  (7) fapp_foundyr_fpatyr.dta

Notes
  - NPL citations are aggregated from patent–paper–author to patent–paper level
    in Python (see POST3_ROS_result.ipynb).
*******************************************************************************/
* Run via `00_run_all_1.do` (depends on shared path globals set by the runner).


********************************************************************************
****************************** Prepare: Format *********************************
********************************************************************************

/*
We aggregated from the patent–paper–author level to the patent–paper level
using the last author. See `POST3_ROS_result.ipynb`.
*/
import delimited "${python_output}Chinese_npl_citations_both_sources.csv", ///
    varnames(1) stringcols(1) clear

save "${stata_output}Chinese_npl_citations_both_sources.dta", replace



********************************************************************************
************************* Prepare: Chinese patents data ************************
********************************************************************************

/*** (1) Chinese patent data: years (application / examination / grant) ***/
use "${CN_patents}date.dta", clear

keep 申请号 授权公告号 申请日 授权公告日 实质审查生效日
rename 申请号     apn
rename 授权公告号 grt_id

gen appyr = year(申请日)
gen sxyr  = year(实质审查生效日)
gen grtyr = year(授权公告日)

label var grt_id "Grant ID of Chinese patent"
label var appyr  "application year"
label var sxyr   "substantive examination year"
label var grtyr  "grant year"

keep apn grt_id appyr sxyr grtyr
duplicates drop

* Generate simple pub_id
gen pub_id = regexs(0) if regexm(grt_id, "\d+") == 1
drop grt_id
label var pub_id "Publication or grant ID of Chinese patent"

order apn pub_id appyr sxyr grtyr
save "${stata_output}CNpatents_year.dta", replace
* Vars: apn pub_id appyr sxyr grtyr (1987–2025)


/*** (2) Unique pub_id for merging (keep one record per pub_id) ***/
use "${stata_output}CNpatents_year.dta", clear

keep pub_id appyr sxyr grtyr
duplicates drop pub_id, force

save "${stata_output}CNpatent_pubid_allyears.dta", replace
* Vars: pub_id appyr sxyr grtyr



********************************************************************************
**************** Prepare: Chinese patents filed by diff types ******************
********************************************************************************

/*** (1) Construct apn–type mapping using single-applicant patents only ***/
use "${CN_patents}app.dta", clear
rename 申请号 apn

* Only single-applicant patents: multi-applicant cases do not have a unique type
keep if 申请人数量 == 1

gen type = .
replace type = 1 if 申请人类型 == "企业"
replace type = 2 if 申请人类型 == "大专院校" | 申请人类型 == "学校" | 申请人类型 == "科研单位"
replace type = 3 if 申请人类型 == "个人" | 申请人类型 == "机关团体" | 申请人类型 == "其他"

label define labels ///
    1 "Firm" ///
    2 "University and research institution" ///
    3 "Individual and other"
label values type labels
label var type "Filed by Firm, University/research institution, or Individual/others"

* Clean and extract standardized first applicant
replace 标准化申请人 = subinstr(标准化申请人, "[", "", .)
replace 标准化申请人 = subinstr(标准化申请人, "]", "", .)

gen fapp_standard = 标准化申请人
replace fapp_standard = substr(标准化申请人, 1, strpos(标准化申请人, ";") - 1) ///
    if strpos(标准化申请人, ";") > 0

rename 第一申请人 fapp

keep apn fapp fapp_standard type
duplicates drop

save "${temp_output}apn_type.dta", replace
* Vars: apn fapp fapp_standard type (1985–2025)


/*** (2) Type mapping at fapp level ***/
use "${temp_output}apn_type.dta", clear
keep fapp type
duplicates drop
duplicates drop fapp, force

save "${temp_output}fapp_type.dta", replace
* Vars: fapp type


/*** (3) Type mapping at fapp_standard level ***/
use "${temp_output}apn_type.dta", clear
keep fapp_standard type
duplicates drop
duplicates drop fapp_standard, force

rename type type2
save "${temp_output}fapp_standard_type.dta", replace
* Vars: fapp_standard type2


/*** (4) Assign a type to each apn (prefer fapp match; fallback to fapp_standard) ***/
use "${CN_patents}app.dta", clear
rename 申请号 apn

replace 标准化申请人 = subinstr(标准化申请人, "[", "", .)
replace 标准化申请人 = subinstr(标准化申请人, "]", "", .)

gen fapp_standard = 标准化申请人
replace fapp_standard = substr(标准化申请人, 1, strpos(标准化申请人, ";") - 1) ///
    if strpos(标准化申请人, ";") > 0

rename 第一申请人 fapp

keep apn fapp fapp_standard

* First match on fapp (more accurate), then on fapp_standard
merge m:1 fapp using "${temp_output}fapp_type.dta"
* Drop observations not represented in the applicant-name type mapping.
drop if _merge == 2
drop _merge

merge m:1 fapp_standard using "${temp_output}fapp_standard_type.dta"
* Standardized-name fallback recovers additional observations.
drop if _merge == 2
drop _merge

replace type = type2 if type == .
drop if type == .

keep apn fapp fapp_standard type
duplicates drop
sort apn
duplicates drop apn, force
order apn fapp fapp_standard type

tab type
/*
      filed by Firm, University and |
research institution, or Individual |
                         and others |      Freq.     Percent        Cum.
------------------------------------+-----------------------------------
                               Firm |  6,060,519       71.50       71.50
University and research institution |  1,952,626       23.04       94.54
               Individual and other |    463,225        5.46      100.00
------------------------------------+-----------------------------------
                              Total |  8,476,370      100.00
*/

save "${stata_output}Chinese_patents_filed_by_diff_types.dta", replace
* Vars: apn fapp fapp_standard type (1985–2025)

keep if type == 1
drop type
gen filed_by_firm = 1

save "${stata_output}Chinese_patents_filed_by_firm.dta", replace
* Vars: apn fapp fapp_standard filed_by_firm


/*** Clean temp files ***/
erase "${temp_output}apn_type.dta"
erase "${temp_output}fapp_type.dta"
erase "${temp_output}fapp_standard_type.dta"



////////////////////////////////////////////////////////////////////////////////
/// Exclude patents filed by foreigners in China and refine by different types ///
////////////////////////////////////////////////////////////////////////////////

use "${CN_patents}add.dta", clear
keep 申请号 申请人国家地区
rename 申请号       apn
rename 申请人国家地区 app_country
duplicates drop

save "${temp_output}process.dta", replace
* Vars: apn app_country


use "${stata_output}Chinese_patents_filed_by_diff_types.dta", clear
drop fapp_standard

merge 1:1 apn using "${temp_output}process.dta"
* process.dta contains applicant country and applicant type assembled above.
drop _merge

save "${stata_output}CNpatents_type_country.dta", replace
* Vars: apn type app_country

erase "${temp_output}process.dta"



********************************************************************************
************* Prepare: Founding year for firms filed Chinese patents ***********
********************************************************************************

/*** (1) Patent-level founding year from businfo ***/
use "${CN_patents}businfo.dta", clear
* Note: patents granted in 2024/2025 may not have the business-registration founding-date field.
rename 申请号 apn

gen estab_date  = regexr(工商成立日期, "[^0-9]", "")
gen founding_yr = real(substr(estab_date, 1, 4))

drop if founding_yr == 0 | founding_yr == .

keep apn founding_yr
duplicates drop

tab founding_yr
save "${temp_output}apn_founding_year.dta", replace
* Vars: apn founding_yr


/*** (2) Applicant-level founding year (single-applicant patents only) ***/
use "${CN_patents}app.dta", clear
rename 申请号   apn
rename 第一申请人 fapp

* Only single-applicant patents (avoid ambiguity)
keep if 申请人数量 == 1
keep apn fapp
duplicates drop
duplicates drop apn, force

merge 1:1 apn using "${temp_output}apn_founding_year.dta"
* Keep only matched observations when building applicant-level founding-year map.
keep if _merge == 3
drop _merge

keep fapp founding_yr
duplicates drop
duplicates drop fapp, force

tab founding_yr
sort founding_yr

save "${temp_output}fapp_founding_year.dta", replace
* Vars: fapp founding_yr



/*************************** (3) First patent year *****************************
  If the firm's founding year is unavailable, use first patent application year.
*******************************************************************************/
use "${stata_output}Chinese_patents_filed_by_firm.dta", clear

merge 1:1 apn using "${stata_output}CNpatents_year.dta"
* Bring application year into the firm-level file to compute first patent year.
drop if _merge == 2
drop _merge

keep fapp appyr
duplicates drop

bys fapp: egen first_pat_yr = min(appyr)
keep fapp first_pat_yr
duplicates drop

save "${temp_output}fapp_fpat_year.dta", replace
* Vars: fapp first_pat_yr


/*** (4) Combine founding year and first patent year ***/
use "${temp_output}fapp_founding_year.dta", clear
merge 1:1 fapp using "${temp_output}fapp_fpat_year.dta"
* Registry founding year is preferred; first patent year is the fallback proxy.
drop _merge

gen foundyr_fpatyr = founding_yr
replace foundyr_fpatyr = first_pat_yr if missing(founding_yr)

keep fapp foundyr_fpatyr
label variable foundyr_fpatyr "Founding year (if available), otherwise first patent year"

save "${stata_output}fapp_foundyr_fpatyr.dta", replace
* Vars: fapp foundyr_fpatyr


/*** Clean temp files ***/
erase "${temp_output}apn_founding_year.dta"
erase "${temp_output}fapp_founding_year.dta"
erase "${temp_output}fapp_fpat_year.dta"
