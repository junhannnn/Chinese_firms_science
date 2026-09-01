********************************************************************************
* Public-release polish: formatting/comments adjusted only; original logic unchanged.
********************************************************************************

/*******************************************************************************
Project: Reviewer Robustness — Negative Control (Utility Model Patents)
Script: 2_UM_merge_EL.do

Purpose
  - Construct utility-model placebo DID samples at the firm-year level.
  - Merge firm names to Entity List timing and build both full-sample and
    listed-firm analysis datasets.
  - Generate treatment/event-time variables and matching covariates/weights.

Inputs
  - ${python_output}CNfirm_utilitymodel_2010_2025.csv
  - ${stata_output}EL_merge.dta
  - ${stata_output}csmar_cv.dta (for listed-firm panel)

Outputs (saved under ${stata_output})
  - DID_allfirm_UM.dta
  - DID_allfirm_UM_cem.dta
  - DID_listedfirm_UM.dta

Notes
  - This is a placebo/negative-control pipeline using utility model patents.
  - The all-firm matched sample uses manually constructed CEM-style bins/weights.
*******************************************************************************/

* Paths are managed centrally by `5_Supplementary_materials/00_run_all.do`.
* Required globals (e.g., `${stata_output}`, `${python_output}`, `${temp_output}`)
* should be defined before calling this script.

********************************************************************************
********************** A. All Firms (Full Sample) ***************************
********************************************************************************

******************* A1. Convert Patent-Level Data to Firm-Year *******************

import delimited ${python_output}CNfirm_utilitymodel_2010_2025.csv, clear
rename 申请年 appyr
rename 授权年 grtyr
rename 申请人 name
rename 统一社会信用代码 SocialCreditCode

rename appyr year

tab grant
drop if grant==0 //only keep granted UM patents

keep if year>=2010 & year<=2022 //change here
tab year

recast str100 name
merge m:1 name using ${stata_output}EL_merge.dta
drop if _merge==2 //check 20
drop _merge

egen firm_id = group(name)
bys firm_id year: gen UM_num = _N

keep firm_id year UM_num list_time SocialCreditCode
duplicates drop
order firm_id year

replace SocialCreditCode = "" if lower(SocialCreditCode)=="nan"
gen has_code = (SocialCreditCode != "")
bysort firm_id year (has_code): keep if _n==_N
drop has_code
isid firm_id year



xtset firm_id year

* Fill missing firm-year rows to complete the panel skeleton

tsfill, full

* After tsfill, carry identifiers and treatment timing forward/backward
local svars firm_id list_time SocialCreditCode

sort firm_id year
foreach v of local svars {
    by firm_id (year): replace `v' = `v'[_n-1] if missing(`v')
}

gen year_1 = 3000-year
sort firm_id year_1
foreach v of local svars {
    by firm_id (year_1): replace `v' = `v'[_n-1] if missing(`v')
}
drop year_1

sort firm_id year


foreach v of varlist UM_num {
    replace `v' = 0 if missing(`v')
}


sort firm_id year
bysort firm_id: egen first_pos = min(cond(UM_num>0, year, .))
bysort firm_id: egen last_pos  = max(cond(UM_num>0, year, .))
keep if year >= first_pos & year <= last_pos
drop first_pos last_pos


gen entity_list = 0
replace entity_list = 1 if list_time != .

gen did=0
gen list_year=year(list_time)
replace did=1 if (year>list_year & entity_list==1)

gen dif_year = year-list_year

gen ln_UM_num=ln(UM_num+1)
winsor2 UM_num, cuts(0 99.5)

drop if dif_year<-3
replace dif_year=3 if dif_year>3 & dif_year!=.


* Construct a pre-treatment patent intensity measure for matching


*** Add matching variable: before_patent
* Treatment group: Average number of patents before inclusion
egen before_patent = mean(UM_num) if !missing(list_year) & year < list_year, by(firm_id)
bysort firm_id (year): replace before_patent = before_patent[_n-1] if missing(before_patent)
* Control group: Average number of patents over the entire sample period
egen before_patent_control = mean(UM_num), by(firm_id)
replace before_patent = before_patent_control if missing(before_patent)
drop before_patent_control


save ${stata_output}DID_allfirm_UM.dta, replace


********************** A2. Matching (CEM) ***********************************

use ${stata_output}DID_allfirm_UM.dta, clear

* 1) Create bins for matching variable
gen log_before_patent = log(before_patent + 1)
xtile bin = log_before_patent, nq(100)

* 2) Keep required variables (original specification)
keep entity_list bin UM_num_w ln_UM_num UM_num firm_id year did dif_year
drop if missing(entity_list, bin, UM_num_w, ln_UM_num, UM_num, firm_id, year)

* 3) Treatment / control indicators
gen t = (entity_list==1)
gen c = (entity_list==0)

* 4) Counts of treated and control observations within each bin
bys bin: egen nt = total(t)
bys bin: egen nc = total(c)

* 5) Matched-bin flag: each bin must contain both treated and controls
gen cem_matched = (nt>0 & nc>0)

* 6) Keep only matched bins
keep if cem_matched==1

* 7) CEM weights: treated = 1; controls = nt/nc
gen cem_weights = 1
replace cem_weights = nt/nc if c==1

compress
save ${stata_output}DID_allfirm_UM_cem.dta, replace


********************************************************************************
********************** B. Public Listed Firms ********************************
********************************************************************************


use ${stata_output}DID_allfirm_UM.dta, clear

keep firm_id SocialCreditCode
duplicates drop
drop if SocialCreditCode==""
duplicates drop SocialCreditCode, force

merge 1:m SocialCreditCode using ${stata_output}csmar_cv.dta
keep if _merge==3
drop _merge

duplicates drop firm_id year, force
merge 1:1 firm_id year using ${stata_output}DID_allfirm_UM.dta
drop if _merge==2
drop _merge

drop did dif_year

local svars firm_id entity_list list_time list_year SocialCreditCode

sort firm_id year
foreach v of local svars {
    by firm_id (year): replace `v' = `v'[_n-1] if missing(`v')
}

gen year_1 = 3000-year
sort firm_id year_1
foreach v of local svars {
    by firm_id (year_1): replace `v' = `v'[_n-1] if missing(`v')
}
drop year_1

sort firm_id year


foreach v of varlist UM_num UM_num_w ln_UM_num before_patent {
    replace `v' = 0 if missing(`v')
}


replace entity_list=0 if entity_list==.

gen did=0
replace did=1 if (year>list_year & entity_list==1)

gen dif_year = year-list_year


gen firm_listing_year = substr(LISTINGDATE, 1, 4)
label var firm_listing_year "Listing year of the firm"
label var list_time "Date of being listed on the Entity List"
destring firm_listing_year, replace
gen firm_age = year-firm_listing_year

gen firm_size=ln(RegisterCapital)
gen cash=ln(CashHoldings)

global controls cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ academic_experience

drop if dif_year<-3
replace dif_year=3 if dif_year>3 & dif_year!=.

save ${stata_output}DID_listedfirm_UM.dta, replace
