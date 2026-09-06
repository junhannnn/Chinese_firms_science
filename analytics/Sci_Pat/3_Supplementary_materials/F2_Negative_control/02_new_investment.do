/*******************************************************************************
Project: Science-linked patents—supplementary negative-control analyses
Script:  02_new_investment.do

Purpose:
  Test whether sanctions predict publicly listed firms' new-investment outcome.
  Estimate level, log-transformed, and count specifications in the full and
  CEM-matched samples.

Main inputs (from ${stata_output}):
  - DID_listedfirm-level_newinvest.dta
  - DID_listedfirm-level_newinvest_cem.dta

Main output (under ${table_output}):
  - listedfirm_new_invest.rtf: full-sample and matched-sample estimates

Notes:
  Run through 3_Supplementary_materials/00_run_all.do so the shared path globals
  and firm controls are available.
*******************************************************************************/

* ==============================================================================
* 1. Estimate full-sample new-investment models
* ==============================================================================

use ${stata_output}DID_listedfirm-level_newinvest.dta, clear
* Estimate the level outcome using linear fixed effects.
reghdfe NewTargets_w did $controls, absorb(ListedCoID year) vce(r)
est store M1

* Estimate the log-transformed outcome using linear fixed effects.
reghdfe ln_NewTargets did $controls, absorb(ListedCoID year) vce(r)
est store M2

* Estimate the count outcome using Poisson pseudo-maximum likelihood.
ppmlhdfe NewTargets did $controls, absorb(ListedCoID year) vce(r)
est store M3

* ==============================================================================
* 2. Estimate CEM-matched new-investment models
* ==============================================================================

use ${stata_output}DID_listedfirm-level_newinvest_cem.dta, clear
keep if cem_matched==1

* Estimate the level outcome using CEM weights.
reghdfe NewTargets_w did $controls [aweight=cem_weights], absorb(ListedCoID year) vce(r)
est store M4

* Estimate the log-transformed outcome using CEM weights.
reghdfe ln_NewTargets did $controls [aweight=cem_weights], absorb(ListedCoID year) vce(r)
est store M5

* Estimate the count outcome using CEM weights.
ppmlhdfe NewTargets did $controls [pweight=cem_weights], absorb(ListedCoID year) vce(r)
est store M6
* ==============================================================================
* 3. Export the combined new-investment table
* ==============================================================================

esttab M1 M2 M3 M4 M5 M6 using ${table_output}listedfirm_new_invest.rtf, ///
    replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
    b(%20.3f) se(%7.3f) r2(%9.3f) ///
    stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
    mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
    nonotes
