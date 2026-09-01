/*******************************************************************************
Project: WOS Pipeline - Listed-Firm DID Analysis
Script: 04_WOS_DID_listed.do

Purpose
  - Build the WOS sample for Chinese publicly listed firms.
  - Merge WOS firms to CSMAR controls and estimate full-sample and CEM DID.

Inputs
  - `${stata_output}CN_WOS_DID.dta`
  - `${python_output}name_match_best.csv` (Python name-matching output)
  - `${CN_CN}CSMAR_cv.dta`

Outputs
  - `${CN_CN}WOS_Engname.csv`
  - `${CN_CN}name_match_best.dta`
  - `${stata_output}CN_WOS_DID_listed.dta`
  - `${table_output}WOS_listedfirm.rtf`

Instructions
  - Run after `01_WOS_data_cleaning.do`.
  - Ensure the Python name-matching step is completed before this script.
*******************************************************************************/

* Path globals are defined centrally in `00_run_all.do`.


********************************************************************************
*********************************** Prepare ************************************
********************************************************************************

*** Prepare 1
use ${stata_output}CN_WOS_DID.dta, clear

keep firm_id firm_en
rename firm_id firm_id_wos
rename firm_en English_name_wos
duplicates drop

export delimited using ${CN_CN}WOS_Engname.csv, replace


*** Prepare 2
* This step uses Python

*** Prepare 3
*import delimited using ${CN_CN}name_match_best.csv, clear //original: WOS
import delimited using ${python_output}name_match_best.csv, clear //WOS
drop if score==0
keep if score==100
drop score strategy
save ${CN_CN}name_match_best.dta, replace


********************************************************************************
**************************** Sample: Chinese listed firms **********************
********************************************************************************

use ${stata_output}CN_WOS_DID.dta, clear

rename firm_id firm_id_wos
rename firm_en English_name_wos

merge m:1 firm_id_wos using ${CN_CN}name_match_best.dta

keep if _merge==3
drop _merge

rename symbol Symbol
merge 1:1 Symbol year using ${CN_CN}CSMAR_cv.dta
drop if _merge==2
drop _merge

order Symbol year

gen firm_listing_year = substr(LISTINGDATE, 1, 4)
label var firm_listing_year "Listing year of the firm"
destring firm_listing_year, replace
gen firm_age = year-firm_listing_year
gen firm_size=ln(RegisterCapital)
gen cash=ln(CashHoldings)

global controls cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ academic_experience

foreach v in $controls {
    bysort firm_id (year): ipolate `v' year, gen(_tmp) epolate
    replace `v' = _tmp if missing(`v')
    drop _tmp
}

foreach var in $controls {
    drop if `var' == .
}

foreach v in $controls {
    winsor2 `v', replace
}

bysort firm_id: egen number = sum(pub_num)
drop if number == 0
drop number

save ${stata_output}CN_WOS_DID_listed.dta, replace



********************************************************************************
******************************* (1) all sample *********************************
********************************************************************************

use ${stata_output}CN_WOS_DID_listed.dta, clear
* OLS
reghdfe pub_num_w did $controls, absorb(year firm_id) vce(r)
est store M1

* ln and OLS
reghdfe ln_pub_num did $controls, absorb(year firm_id) vce(r)
est store M2

* Poisson
ppmlhdfe pub_num did $controls, absorb(year firm_id) vce(r)
est store M3

********************************************************************************
************************** (2) matched sample **********************************
********************************************************************************

use ${stata_output}CN_WOS_DID_listed_cem.dta, clear

keep if cem_matched==1

bysort firm_id: egen number = sum(pub_num)
drop if number == 0
drop number

* OLS
reghdfe pub_num_w did $controls [aweight=cem_weights], absorb(year firm_id) vce(r)
est store M4

* ln and OLS
reghdfe ln_pub_num did $controls [aweight=cem_weights], absorb(year firm_id) vce(r)
est store M5

* Poisson
ppmlhdfe pub_num did $controls [pweight=cem_weights], absorb(year firm_id) vce(r)
est store M6



esttab M1 M2 M3 M4 M5 M6 using ${table_output}WOS_listedfirm.rtf, ///
    replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
    b(%20.3f) se(%7.3f) r2(%9.3f) ///
    stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
    mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
    nonotes

