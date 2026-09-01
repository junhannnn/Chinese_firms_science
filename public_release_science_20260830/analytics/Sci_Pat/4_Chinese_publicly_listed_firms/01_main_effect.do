/*******************************************************************************
Project: Chinese Publicly Listed Firms - Main Effect Analysis
Script: 01_main_effect.do

Purpose
  - Report full-sample and matched-sample estimates.

Inputs (from ${stata_output})
  - DID_listedfirm-level.dta

Tables (saved under ${table_output})
  - main_listed.rtf

Notes
  - This script assumes path globals are defined by
    4_Chinese_publicly_listed_firms/00_run_all_4.do.
*******************************************************************************/
* Run via `00_run_all_4.do` (depends on shared path globals set by the runner).



********************************************************************************
*********************** Staggered DID analysis: cite science *******************
********************************************************************************
	
use ${stata_output}DID_listedfirm-level.dta, clear

global controls cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ academic_experience

* OLS
reghdfe f_cite_science_num_w did whether_pat $controls, absorb(ListedCoID year) vce(r)
est store M1

* ln and OLS
reghdfe ln_f_cite_science_num did whether_pat $controls, absorb(ListedCoID year) vce(r)
est store M2

* Poisson
ppmlhdfe f_cite_science_num did whether_pat $controls, absorb(ListedCoID year) vce(r)
est store M3


********************************** CEM *****************************************

use ${stata_output}DID_listedfirm-level_cem.dta, clear

keep if cem_matched==1

* OLS
reghdfe f_cite_science_num_w did whether_pat $controls [aweight=cem_weights], absorb(ListedCoID year) vce(r)
est store M4

* ln and OLS
reghdfe ln_f_cite_science_num did whether_pat $controls [aweight=cem_weights], absorb(ListedCoID year) vce(r)
est store M5

* Poisson
ppmlhdfe f_cite_science_num did whether_pat $controls [pweight=cem_weights], absorb(ListedCoID year) vce(r)
est store M6


esttab M1 M2 M3 M4 M5 M6 using ${table_output}main_listed.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
	nonotes
