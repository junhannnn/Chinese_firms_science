/*******************************************************************************
Project: Science-linked patents—supplementary negative-control analyses
Script:  01_UM.do

Purpose:
  Use utility-model patent outcomes as a negative-control test of the estimated
  sanction effect. Estimate level, log-transformed, and count specifications for
  all Chinese firms and publicly listed firms in full and CEM-matched samples.

Main inputs (from ${stata_output}):
  - DID_allfirm_UM.dta
  - DID_allfirm_UM_cem.dta
  - DID_listedfirm_UM.dta
  - DID_listedfirm_UM_cem.dta

Main output (under ${table_output}):
  - placebo_UM.rtf: full-sample and matched-sample negative-control estimates

Notes:
  Run through 3_Supplementary_materials/00_run_all.do so the shared path globals
  are available.
*******************************************************************************/

* ==============================================================================
* 1. Estimate full-sample models for all Chinese firms
* ==============================================================================

use ${stata_output}DID_allfirm_UM.dta, clear

* Estimate the level outcome using linear fixed effects.
reghdfe UM_num_w did, absorb(firm_id year) vce(r) 
est store M1

* Estimate the log-transformed outcome using linear fixed effects.
reghdfe ln_UM_num did, absorb(firm_id year) vce(r)
est store M2

* Estimate the count outcome using Poisson pseudo-maximum likelihood.
ppmlhdfe UM_num did, absorb(firm_id year) vce(r)
est store M3
* ==============================================================================
* 2. Estimate CEM-matched models for all Chinese firms
* ==============================================================================

use ${stata_output}DID_allfirm_UM_cem.dta, clear

keep if cem_matched==1

* Estimate the level outcome using CEM weights.
reghdfe UM_num_w did [aweight=cem_weights], absorb(firm_id year) vce(r) 
est store M4

* Estimate the log-transformed outcome using CEM weights.
reghdfe ln_UM_num did [aweight=cem_weights], absorb(firm_id year) vce(r)
est store M5

* Estimate the count outcome using CEM weights.
ppmlhdfe UM_num did [pweight=cem_weights], absorb(firm_id year) vce(r)
est store M6
* ==============================================================================
* 3. Estimate full-sample models for publicly listed firms
* ==============================================================================

use ${stata_output}DID_listedfirm_UM.dta, clear

* Estimate the level outcome using linear fixed effects and firm controls.
reghdfe UM_num_w did $controls, absorb(ListedCoID year) vce(r)
est store M7

* Estimate the log-transformed outcome using linear fixed effects and controls.
reghdfe ln_UM_num did $controls, absorb(ListedCoID year) vce(r)
est store M8

* Estimate the count outcome using Poisson pseudo-maximum likelihood and controls.
ppmlhdfe UM_num did $controls, absorb(ListedCoID year) vce(r)
est store M9
* ==============================================================================
* 4. Estimate CEM-matched models for publicly listed firms
* ==============================================================================

use ${stata_output}DID_listedfirm_UM_cem.dta, clear
keep if cem_matched==1

* Estimate the level outcome using CEM weights and firm controls.
reghdfe UM_num_w did $controls [aweight=cem_weights], absorb(ListedCoID year) vce(r)
est store M10

* Estimate the log-transformed outcome using CEM weights and firm controls.
reghdfe ln_UM_num did $controls [aweight=cem_weights], absorb(ListedCoID year) vce(r)
est store M11

* Estimate the count outcome using CEM weights and firm controls.
ppmlhdfe UM_num did $controls [pweight=cem_weights], absorb(ListedCoID year) vce(r)
est store M12
* ==============================================================================
* 5. Export the combined utility-model negative-control table
* ==============================================================================

esttab M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12 using ${table_output}placebo_UM.rtf, ///
    replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
    b(%20.3f) se(%7.3f) r2(%9.3f) ///
    stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
    mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6" "Model 7" "Model 8" "Model 9" "Model 10" "Model 11" "Model 12") ///
    nonotes
