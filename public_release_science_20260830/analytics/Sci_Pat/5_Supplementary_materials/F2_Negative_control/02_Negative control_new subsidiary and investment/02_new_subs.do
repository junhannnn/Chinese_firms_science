********************************************************************************
* Public-release polish: formatting/comments adjusted only; original logic unchanged.
********************************************************************************

/*******************************************************************************
Project: Reviewer Robustness — Negative Control (Listed Firms: New Subsidiaries)
Script: 02_new_subs.do

Purpose
  - Construct a listed-firm placebo outcome measuring the yearly number of newly
    added subsidiaries from CSMAR subsidiary notes.
  - Merge the placebo outcome into the listed-firm DID panel and estimate
    baseline and matched (CEM) regressions.

Inputs
  - ${subs_data}STK_NotesSubJoint.dta
  - ${subs_data}STK_NotesSubJoint1.dta
  - ${stata_output}DID_listedfirm-level.dta

Outputs (saved under ${stata_output})
  - CSMAR_new_subs_num.dta

Tables (saved under ${table_output})
  - listedfirm_new_subs.rtf

Temporary files (saved under ${temp_output}, deleted in-script)
  - temp_subs1.dta
  - temp_subs2.dta

Notes
  - This script implements a negative-control/placebo test using new subsidiary
    additions as the outcome for listed firms.
*******************************************************************************/


********************************************************************************
************************ A. Prepare Placebo Outcome (New Subsidiaries) *********
********************************************************************************

*** (1) First source file

use ${subs_data}STK_NotesSubJoint.dta, clear

keep if Relationship=="上市公司的子公司" //only keep subs

keep Symbol EndDate RalatedParty
duplicates drop

gen year=substr(EndDate, 1, 4)
destring year, replace
drop EndDate

rename RalatedParty subs
order Symbol year subs

save ${temp_output}temp_subs1.dta, replace //var: Symbol year subs


*** (2) Second source file

use ${subs_data}STK_NotesSubJoint1.dta, clear

keep if Relationship=="上市公司的子公司" //only keep subs

keep Symbol EndDate RalatedParty
duplicates drop

gen year=substr(EndDate, 1, 4)
destring year, replace
drop EndDate

rename RalatedParty subs
order Symbol year subs

save ${temp_output}temp_subs2.dta, replace //var: Symbol year subs


*******************************************************
* Goal: For each Symbol-year, count newly added subsidiaries
* Required variables: Symbol year subs
*******************************************************

use ${temp_output}temp_subs1.dta, clear
append using ${temp_output}temp_subs2.dta

duplicates drop


* 1) Basic cleaning (optional but recommended)
*    - make sure subs is a clean string
replace subs = strtrim(subs)
replace subs = itrim(subs)

* 2) Find first year each sub appears within each Symbol
sort Symbol subs year
by Symbol subs: gen first_year = year[1]

* 3) Mark whether sub is newly added in that year
gen new_sub = (year == first_year)

* 4) Count number of newly added subs per Symbol-year
bysort Symbol year: egen newsubs = total(new_sub)

* 5) Keep one row per Symbol-year (panel summary)
keep Symbol year newsubs
duplicates drop

sort Symbol year

tab year
keep if year>=2010 & year<=2022

save ${stata_output}CSMAR_new_subs_num.dta, replace //var: Symbol year newsubs



erase ${temp_output}temp_subs1.dta
erase ${temp_output}temp_subs2.dta



********************************************************************************
*********************** B. Regression (Full + Matched Samples) *****************
********************************************************************************

use ${stata_output}DID_listedfirm-level.dta, clear

tostring Symbol, replace format(%06.0f)
merge 1:1 Symbol year using ${stata_output}CSMAR_new_subs_num.dta
drop if _merge==2
replace newsubs=0 if _merge==1
drop _merge

global controls cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ academic_experience

winsor2 newsubs, cuts(0 99.5)
gen ln_newsubs = ln(newsubs+1)


* OLS
reghdfe newsubs_w did $controls, absorb(ListedCoID year) vce(r)
est store M1

* ln and OLS
reghdfe ln_newsubs did $controls, absorb(ListedCoID year) vce(r)
est store M2

* Poisson
ppmlhdfe newsubs did $controls, absorb(ListedCoID year) vce(r)
est store M3

******************************* C. Matched Sample (CEM) ************************

use ${stata_output}DID_listedfirm-level.dta, clear

tostring Symbol, replace format(%06.0f)
merge 1:1 Symbol year using ${stata_output}CSMAR_new_subs_num.dta
drop if _merge==2
replace newsubs=0 if _merge==1
drop _merge

global controls cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ academic_experience

winsor2 newsubs, cuts(0 99.5)
gen ln_newsubs = ln(newsubs+1)


* Coarsened exact matching on listed-firm characteristics
gen major_indus=substr(IndustryCode,1,1)
cem firm_age firm_size major_indus PROVINCE RDInvest, treatment(entity_list)

keep if cem_matched==1

* OLS
reghdfe newsubs_w did $controls [aweight=cem_weights], absorb(ListedCoID year) vce(r)
est store M4

* ln and OLS
reghdfe ln_newsubs did $controls [aweight=cem_weights], absorb(ListedCoID year) vce(r)
est store M5

* Poisson
ppmlhdfe newsubs did $controls [pweight=cem_weights], absorb(ListedCoID year) vce(r)
est store M6



esttab M1 M2 M3 M4 M5 M6 using ${table_output}listedfirm_new_subs.rtf, ///
    replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
    b(%20.3f) se(%7.3f) r2(%9.3f) ///
    stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
    mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
    nonotes
