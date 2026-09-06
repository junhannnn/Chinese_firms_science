/*******************************************************************************
Project: Science-linked patents—Chinese publicly listed firms
Script:  01_main_effect.do

Purpose:
  Estimate the association between sanctions and firms' subsequent reliance on
  science using linear and Poisson fixed-effects models. Report estimates for
  the full sample and the coarsened-exact-matching (CEM) sample.

Main inputs (from ${stata_output}):
  - DID_listedfirm-level.dta
  - DID_listedfirm-level_cem.dta

Main output (under ${table_output}):
  - main_listed.rtf: full-sample and CEM-matched regression estimates

Notes:
  Run through 00_run_all.do so the shared path globals are available.
*******************************************************************************/

* ==============================================================================
* 1. Estimate full-sample models
* ==============================================================================
	
use ${stata_output}DID_listedfirm-level.dta, clear

global controls cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ academic_experience

* Estimate the level outcome using linear fixed effects.
reghdfe f_cite_science_num_w did whether_pat $controls, absorb(ListedCoID year) vce(r)
est store M1

* Estimate the log-transformed outcome using linear fixed effects.
reghdfe ln_f_cite_science_num did whether_pat $controls, absorb(ListedCoID year) vce(r)
est store M2

* Estimate the count outcome using Poisson pseudo-maximum likelihood.
ppmlhdfe f_cite_science_num did whether_pat $controls, absorb(ListedCoID year) vce(r)
est store M3


* ==============================================================================
* 2. Estimate CEM-matched models
* ==============================================================================

use ${stata_output}DID_listedfirm-level_cem.dta, clear

keep if cem_matched==1

* Estimate the level outcome using CEM weights.
reghdfe f_cite_science_num_w did whether_pat $controls [aweight=cem_weights], absorb(ListedCoID year) vce(r)
est store M4

* Estimate the log-transformed outcome using CEM weights.
reghdfe ln_f_cite_science_num did whether_pat $controls [aweight=cem_weights], absorb(ListedCoID year) vce(r)
est store M5

* Estimate the count outcome using CEM weights.
ppmlhdfe f_cite_science_num did whether_pat $controls [pweight=cem_weights], absorb(ListedCoID year) vce(r)
est store M6
* ==============================================================================
* 3. Export the combined regression table
* ==============================================================================

esttab M1 M2 M3 M4 M5 M6 using ${table_output}main_listed.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
	nonotes
