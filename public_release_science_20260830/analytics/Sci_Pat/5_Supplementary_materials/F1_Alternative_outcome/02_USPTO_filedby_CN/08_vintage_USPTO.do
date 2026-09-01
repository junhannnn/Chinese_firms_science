/*******************************************************************************
Project: Robustness Checks - USPTO Science Vintage Tests
Script: 08_vintage_USPTO.do

Purpose
  - Estimate DID regressions on publication-year and citation-lag vintage
    measures in the USPTO-based firm-year panel.
  - Assess whether sanctions shift the vintage profile of scientific knowledge
    cited by Chinese firms' U.S. patents.

Inputs (from ${stata_output})
  - USpatents_DID_allfirm.dta

Tables (saved under ${table_output})
  - robust_USPTO_vintage.rtf

Notes
  - Invoked by `00_run_all_6.do` in the final step of this USPTO robustness
    pipeline.
*******************************************************************************/
* Run via `00_run_all_6.do` (depends on shared path globals set by the runner).


/*
Table output:
  (1) robust_USPTO_vintage.rtf
*/

********************************************************************************
********************************** Vintage *************************************
********************************************************************************


******************************** A. Publication Year ***************************

use ${stata_output}USpatents_DID_allfirm.dta, clear

* min
reghdfe f_paperyear_min did, absorb(firm_id year) vce(r)
est store M1

* max
reghdfe f_paperyear_max did, absorb(firm_id year) vce(r)
est store M2

* mean
reghdfe f_paperyear_mean did, absorb(firm_id year) vce(r)
est store M3

******************************* C. Temporal Range ******************************

reghdfe f_lag did, absorb(firm_id year) vce(r)
est store M4


esttab M1 M2 M3 M4 using ${table_output}robust_USPTO_vintage.rtf, ///
    replace star( * 0.11 ** 0.05 *** 0.01 ) nogaps compress ///
    b(%20.3f) se(%7.3f) r2(%9.3f) ///
    stats(N r2, fmt(%15.0fc %9.3f) labels("Observations" "R2")) ///
    mtitles("Model 1" "Model 2" "Model 3" "Model 4") ///
    nonotes
