/*******************************************************************************
Project: Science-linked patents—Chinese publicly listed firms
Script:  02_moderators.do

Purpose:
  Test whether firms' dependence on U.S. technology moderates the relationship
  between sanctions and subsequent reliance on science. Estimate linear and
  Poisson fixed-effects models for the full and CEM-matched samples.

Main inputs (from ${stata_output}):
  - DID_listedfirm_mo.dta
  - DID_listedfirm_mo_cem.dta

Main output (under ${table_output}):
  - main_listed_mo_uspat.rtf: moderator estimates for both samples

Notes:
  Run through 00_run_all.do so the shared path globals are available.
*******************************************************************************/

* ==============================================================================
* 1. Estimate full-sample moderator models
* ==============================================================================

use ${stata_output}DID_listedfirm_mo.dta, clear

global controls firm_size cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ academic_experience

* Estimate the level outcome using linear fixed effects.
reghdfe f_cite_science_num_w did##moderator whether_pat $controls, absorb(ListedCoID year) vce(r) 
est store M1

* Estimate the log-transformed outcome using linear fixed effects.
reghdfe ln_f_cite_science_num did##moderator whether_pat $controls, absorb(ListedCoID year) vce(r) 
est store M2

* Estimate the count outcome using Poisson pseudo-maximum likelihood.
ppmlhdfe f_cite_science_num did##moderator whether_pat $controls, absorb(ListedCoID year) vce(r) 
est store M3
* ==============================================================================
* 2. Estimate CEM-matched moderator models
* ==============================================================================

use ${stata_output}DID_listedfirm_mo_cem.dta, clear

global controls firm_size cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ academic_experience

* Estimate the level outcome using CEM weights.
reghdfe f_cite_science_num_w did##moderator whether_pat $controls [aweight=cem_weights], absorb(ListedCoID year) vce(r) 
est store M4

* Estimate the log-transformed outcome using CEM weights.
reghdfe ln_f_cite_science_num did##moderator whether_pat $controls [aweight=cem_weights], absorb(ListedCoID year) vce(r) 
est store M5

* Estimate the count outcome using CEM weights.
ppmlhdfe f_cite_science_num did##moderator whether_pat $controls [pweight=cem_weights], absorb(ListedCoID year) vce(r) 
est store M6
* ==============================================================================
* 3. Export the combined moderator table
* ==============================================================================

esttab M1 M2 M3 M4 M5 M6 using ${table_output}main_listed_mo_uspat.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	drop("did" "1.moderator" "0.did" "0.moderator" "0.did#0.moderator" "0.did#1.moderator" "1.did#0.moderator" "whether_pat") ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
	mgroups("Full sample" "Matched sample", pattern(1 0 0 1 0 0)) ///
	nonotes
