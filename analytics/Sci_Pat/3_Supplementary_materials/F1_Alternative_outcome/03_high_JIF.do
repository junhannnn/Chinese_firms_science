/*******************************************************************************
Project: Science-linked patents—supplementary alternative outcomes
Script:  03_high_JIF.do

Purpose:
  Test whether the main findings are robust when publication outcomes are
  restricted to high-journal-impact-factor (high-JIF) research. Estimate level,
  log-transformed, and count models using CNKI and WOS data.

Main inputs:
  - ${RUN5_STATA_CNKI}CNKI_DID.dta
  - ${RUN5_STATA_WOS}CN_WOS_DID.dta

Main output:
  - ${RUN5_TABLE_WOS}robust_high_JIF.rtf

Notes:
  Run through 3_Supplementary_materials/00_run_all.do so the RUN5_* path globals
  are available. The combined result table is written to the WOS table folder.
*******************************************************************************/

* ==============================================================================
* 1. Estimate high-JIF publication models using CNKI data
* ==============================================================================

use ${RUN5_STATA_CNKI}CNKI_DID.dta, clear

* Estimate the level outcome using linear fixed effects.
reghdfe pub_num_h_w did, absorb(year firm_id) vce(r)
est store M1

* Estimate the log-transformed outcome using linear fixed effects.
reghdfe ln_pub_num_h did, absorb(year firm_id) vce(r)
est store M2

* Estimate the count outcome using Poisson pseudo-maximum likelihood.
ppmlhdfe pub_num_h did, absorb(year firm_id) vce(r)
est store M3

* ==============================================================================
* 2. Estimate high-JIF publication models using WOS data
* ==============================================================================

use ${RUN5_STATA_WOS}CN_WOS_DID.dta, clear

* Estimate the level outcome using linear fixed effects.
reghdfe pub_num_h_w did, absorb(year firm_id) vce(r)
est store M4

* Estimate the log-transformed outcome using linear fixed effects.
reghdfe ln_pub_num_h did, absorb(year firm_id) vce(r)
est store M5

* Estimate the count outcome using Poisson pseudo-maximum likelihood.
ppmlhdfe pub_num_h did, absorb(year firm_id) vce(r)
est store M6

* ==============================================================================
* 3. Export the combined high-JIF results table
* ==============================================================================

esttab M1 M2 M3 M4 M5 M6 using ${RUN5_TABLE_WOS}robust_high_JIF.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
	nonotes
