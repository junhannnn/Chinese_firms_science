/*******************************************************************************
Project: Science-linked patents—supplementary alternative outcomes
Script:  02_Science_closeness.do

Purpose:
  Estimate the sanction effect using firms' maximum closeness to CNKI and WOS
  publications as alternative outcomes. Both specifications include firm and
  year fixed effects with robust standard errors.

Main input (from ${stata_output}):
  - DID_allfirm-level.dta

Main output (under ${table_output}):
  - science_closeness.rtf: CNKI and WOS closeness estimates

Notes:
  Run through 3_Supplementary_materials/00_run_all.do so the shared path globals
  are available.
*******************************************************************************/

* ==============================================================================
* 1. Estimate the model using maximum closeness to CNKI publications
* ==============================================================================

use ${stata_output}DID_allfirm-level.dta, clear

reghdfe f_cnki_closeness_max did, absorb(firm_id year) vce(r)
est store M1
* ==============================================================================
* 2. Estimate the model using maximum closeness to WOS publications
* ==============================================================================

use ${stata_output}DID_allfirm-level.dta, clear
reghdfe f_wos_closeness_max did, absorb(firm_id year) vce(r)
est store M2
* ==============================================================================
* 3. Export the combined science-closeness table
* ==============================================================================

esttab M1 M2 using ${table_output}science_closeness.rtf, ///
    replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ///
    b(%20.3f) se(%7.3f) r2(%9.3f) ///
    stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
    mtitles("Model 1" "Model 2") ///
    nonotes

