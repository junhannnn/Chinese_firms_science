********************************************************************************
* Public-release polish: formatting/comments adjusted only; original logic unchanged.
********************************************************************************

/*******************************************************************************
Project: Reviewer Robustness — Negative Control (Utility Model Patents)
Script: 3_UM_DID.do

Purpose
  - Estimate placebo DID regressions using utility-model patent outcomes.
  - Report results for all firms and listed firms, with and without matching.

Inputs (from ${stata_output})
  - DID_allfirm_UM.dta
  - DID_allfirm_UM_cem.dta
  - DID_listedfirm_UM.dta

Outputs
  - ${table_output}placebo_UM.rtf

Notes
  - Uses weighted specifications for the matched all-firm sample.
*******************************************************************************/

* Paths are managed centrally by `Reviewer/Negative control_design_UM_patent/00_run_all_7.do`.
* Required globals (e.g., `${stata_output}`, `${table_output}`) should be
* defined before calling this script.


********************************************************************************
********************** A. All Firms (Full Sample) ***************************
********************************************************************************

use ${stata_output}DID_allfirm_UM.dta, clear

* Model block A: all firms (full sample)

* OLS
reghdfe UM_num_w did, absorb(firm_id year) vce(r) 
est store M1

* ln and OLS
reghdfe ln_UM_num did, absorb(firm_id year) vce(r)
est store M2

* Poisson
ppmlhdfe UM_num did, absorb(firm_id year) vce(r)
est store M3


use ${stata_output}DID_allfirm_UM_cem.dta, clear

* Model block B: all firms (matched sample)

keep if cem_matched==1

* OLS
reghdfe UM_num_w did [aweight=cem_weights], absorb(firm_id year) vce(r) 
est store M4

* ln and OLS
reghdfe ln_UM_num did [aweight=cem_weights], absorb(firm_id year) vce(r)
est store M5

* Poisson
ppmlhdfe UM_num did [pweight=cem_weights], absorb(firm_id year) vce(r)
est store M6



********************************************************************************
********************** B. Public Listed Firms ********************************
********************************************************************************

use ${stata_output}DID_listedfirm_UM.dta, clear

* Model block C: listed firms (full sample)

* OLS
reghdfe UM_num_w did $controls, absorb(ListedCoID year) vce(r)
est store M7

* ln and OLS
reghdfe ln_UM_num did $controls, absorb(ListedCoID year) vce(r)
est store M8

* Poisson
ppmlhdfe UM_num did $controls, absorb(ListedCoID year) vce(r)
est store M9


********************** B1. Matching (CEM) ***********************************

use ${stata_output}DID_listedfirm_UM.dta, clear

* Model block D: listed firms (matched sample)
gen major_indus=substr(IndustryCode,1,1)
cem firm_age firm_size major_indus PROVINCE RDInvest, treatment(entity_list)

keep if cem_matched==1

* OLS
reghdfe UM_num_w did $controls [aweight=cem_weights], absorb(ListedCoID year) vce(r)
est store M10

* ln and OLS
reghdfe ln_UM_num did $controls [aweight=cem_weights], absorb(ListedCoID year) vce(r)
est store M11

* Poisson
ppmlhdfe UM_num did $controls [pweight=cem_weights], absorb(ListedCoID year) vce(r)
est store M12


esttab M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12 using ${table_output}placebo_UM.rtf, ///
    replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
    b(%20.3f) se(%7.3f) r2(%9.3f) ///
    stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
    mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6" "Model 7" "Model 8" "Model 9" "Model 10" "Model 11" "Model 12") ///
    nonotes
