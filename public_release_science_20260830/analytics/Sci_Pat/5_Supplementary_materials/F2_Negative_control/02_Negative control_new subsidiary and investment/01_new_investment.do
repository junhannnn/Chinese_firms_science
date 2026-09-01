********************************************************************************
* Public-release polish: formatting/comments adjusted only; original logic unchanged.
********************************************************************************

/*******************************************************************************
Project: Reviewer Robustness — Negative Control (Listed Firms: New Investment)
Script: 01_new_investment.do

Purpose
  - Construct a listed-firm placebo outcome measuring the yearly number of
    newly added equity investment targets from CSMAR equity investment records.
  - Merge the placebo outcome into the listed-firm DID panel and estimate
    baseline and matched (CEM) regressions.

Inputs
  - ${raw_data}上市公司股权投资情况表/IV_EquityIV.dta
  - ${stata_output}DID_listedfirm-level.dta

Outputs (saved under ${stata_output})
  - CSMAR_new_equity_targets.dta

Tables (saved under ${table_output})
  - listedfirm_new_invest.rtf

Notes
  - This script implements a negative-control/placebo test using new equity
    investment targets as the outcome for listed firms.
*******************************************************************************/



********************************************************************************
********************** A. Prepare Placebo Outcome (New Investment) *************
********************************************************************************

use ${raw_data}上市公司股权投资情况表/IV_EquityIV.dta, clear

*----------------------------*
* 1) Keep variable
*----------------------------*

keep Symbol EndDate HoldInstitutionName EventTypeCode AccountItem CurrencyCode BookValue

*----------------------------*
* 2) Basic cleaning
*----------------------------*

* 2.1 Ensure Symbol is string with leading zeros preserved
capture confirm string variable Symbol
if _rc {
    tostring Symbol, replace format(%06.0f)
}
else {
    replace Symbol = strtrim(Symbol)
    replace Symbol = itrim(Symbol)
}

* 2.2 Clean investee/target name
replace HoldInstitutionName = strtrim(HoldInstitutionName)
replace HoldInstitutionName = itrim(HoldInstitutionName)

* Drop missing target names
drop if missing(HoldInstitutionName)


* 2.3 generate year
gen year=substr(EndDate, 1, 4)
destring year, replace
drop EndDate

*----------------------------*
* 3) Optional sample restriction (uncomment if desired)
*----------------------------*

* (A) Keep only equity investment event types (example: 2 and 3 in your data)
* keep if inlist(EventTypeCode, 2, 3)

* (B) Keep only more "strategic/long-term" accounting items (example)
* keep if inlist(AccountItem, "长期股权投资", "其他权益工具投资", "可供出售金融资产")

*----------------------------*
* 4) Remove within-year duplicates
*    (same firm-year-target can appear multiple quarters)
*----------------------------*
duplicates drop Symbol year HoldInstitutionName, force

*----------------------------*
* 5) Identify first year a target appears in a firm's holdings
*----------------------------*
sort Symbol HoldInstitutionName year
by Symbol HoldInstitutionName: gen int first_year = year[1]

* Mark new target in that year
gen byte new_target = (year == first_year)

*----------------------------*
* 6) Collapse to firm-year NewTargets
*----------------------------*
collapse (sum) NewTargets = new_target, by(Symbol year)

*----------------------------*
* 7) Finalize and save
*----------------------------*
sort Symbol year
label var NewTargets "Number of newly added equity investment targets in year t"

keep if year>=2010 & year<=2022

save ${stata_output}CSMAR_new_equity_targets.dta, replace



********************************************************************************
*********************** B. Regression (Full + Matched Samples) *****************
********************************************************************************

use ${stata_output}DID_listedfirm-level.dta, clear

tostring Symbol, replace format(%06.0f)
merge 1:1 Symbol year using ${stata_output}CSMAR_new_equity_targets.dta
drop if _merge==2
replace NewTargets=0 if _merge==1
drop _merge

global controls cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ academic_experience

winsor2 NewTargets, cuts(0 99.5)
gen ln_NewTargets = ln(NewTargets+1)


* OLS
reghdfe NewTargets_w did $controls, absorb(ListedCoID year) vce(r)
est store M1

* ln and OLS
reghdfe ln_NewTargets did $controls, absorb(ListedCoID year) vce(r)
est store M2

* Poisson
ppmlhdfe NewTargets did $controls, absorb(ListedCoID year) vce(r)
est store M3

******************************* C. Matched Sample (CEM) ************************

use ${stata_output}DID_listedfirm-level.dta, clear

tostring Symbol, replace format(%06.0f)
merge 1:1 Symbol year using ${stata_output}CSMAR_new_equity_targets.dta
drop if _merge==2
replace NewTargets=0 if _merge==1
drop _merge

global controls cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ academic_experience

winsor2 NewTargets, cuts(0 99.5)
gen ln_NewTargets = ln(NewTargets+1)


* Coarsened exact matching on listed-firm characteristics
gen major_indus=substr(IndustryCode,1,1)
cem firm_age firm_size major_indus PROVINCE RDInvest, treatment(entity_list)

keep if cem_matched==1

* OLS
reghdfe NewTargets_w did $controls [aweight=cem_weights], absorb(ListedCoID year) vce(r)
est store M4

* ln and OLS
reghdfe ln_NewTargets did $controls [aweight=cem_weights], absorb(ListedCoID year) vce(r)
est store M5

* Poisson
ppmlhdfe NewTargets did $controls [pweight=cem_weights], absorb(ListedCoID year) vce(r)
est store M6



esttab M1 M2 M3 M4 M5 M6 using ${table_output}listedfirm_new_invest.rtf, ///
    replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
    b(%20.3f) se(%7.3f) r2(%9.3f) ///
    stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
    mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
    nonotes
