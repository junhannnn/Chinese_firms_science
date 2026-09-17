/*******************************************************************************
Project: WOS analysis
Script:  03_WOS_DID_listed.do

Purpose:
  Estimate baseline difference-in-differences (DID) models for Web of Science
  publication outcomes among Chinese listed firms. Results compare the full
  sample with a coarsened-exact-matching (CEM) sample using level,
  log-transformed, and Poisson specifications.

Main inputs:
  - ${stata_output}CN_WOS_DID_listed.dta (full listed-firm sample)
  - ${stata_output}CN_WOS_DID_listed_cem.dta (CEM sample and weights)

Main output:
  ${table_output}WOS_listedfirm.rtf

Required setup:
  00_run_all.do defines stata_output and table_output before calling this file.
  The global macro $controls must be defined by the calling environment. The
  script also requires the community-contributed commands reghdfe, ppmlhdfe,
  and esttab.
*******************************************************************************/



* ==============================================================================
* 1. Estimate models for the full listed-firm sample
* ==============================================================================

use ${stata_output}CN_WOS_DID_listed.dta, clear

global controls cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ academic_experience

* Model 1: linear specification for winsorized publication counts.
reghdfe pub_num_w did $controls, absorb(year firm_id) vce(r)
est store M1

* Model 2: linear specification for log-transformed publication counts.
reghdfe ln_pub_num did $controls, absorb(year firm_id) vce(r)
est store M2

* Model 3: Poisson specification for publication counts.
ppmlhdfe pub_num did $controls, absorb(year firm_id) vce(r)
est store M3

* ==============================================================================
* 2. Estimate weighted models for the CEM sample
* ==============================================================================

use ${stata_output}CN_WOS_DID_listed_cem.dta, clear

global controls cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ academic_experience

keep if cem_matched==1

* Exclude firms with no publications over the retained panel.
bysort firm_id: egen number = sum(pub_num)
drop if number == 0
drop number

* Model 4: CEM-weighted linear specification for winsorized counts.
reghdfe pub_num_w did $controls [aweight=cem_weights], absorb(year firm_id) vce(r)
est store M4

* Model 5: CEM-weighted linear specification for log-transformed counts.
reghdfe ln_pub_num did $controls [aweight=cem_weights], absorb(year firm_id) vce(r)
est store M5

* Model 6: CEM-weighted Poisson specification for publication counts.
ppmlhdfe pub_num did $controls [pweight=cem_weights], absorb(year firm_id) vce(r)
est store M6

* ==============================================================================
* 3. Export the full-sample and matched-sample estimates
* ==============================================================================

esttab M1 M2 M3 M4 M5 M6 using ${table_output}WOS_listedfirm.rtf, ///
    replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
    b(%20.3f) se(%7.3f) r2(%9.3f) ///
    stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
    mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
    nonotes
