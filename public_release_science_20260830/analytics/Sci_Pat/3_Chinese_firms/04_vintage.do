/*******************************************************************************
Project: Chinese Firms - Science Vintage Tests
Script: 04_vintage.do

Purpose
  - Estimate DID regressions on science-citation vintage measures to test
    whether sanctions change the age profile of scientific knowledge cited by
    Chinese firms.
  - Compare results for the full sample and the matched (CEM) sample.

Inputs (from ${stata_output})
  - DID_allfirm_level.dta
  - DID_allfirm_level_cem.dta

Tables (saved under ${table_output})
  - vintage.rtf
  - vintage_cem.rtf

Notes
  - This script assumes shared globals (e.g., ${stata_output}, ${table_output})
    have already been defined, typically by 3_Chinese_firms/00_run_all_3.do.
  - A CEM construction snippet is kept as a commented reference in the middle
    of the file; the executed CEM regressions read the pre-built matched file.
*******************************************************************************/
* Run via `00_run_all_3.do` (depends on shared path globals set by the runner).



********************************************************************************
********************************* All sample ***********************************
********************************************************************************


************************************* year *************************************

use ${stata_output}DID_allfirm-level.dta, clear

* min
reghdfe f_paperyear_min did whether_pat, absorb(firm_id year) vce(r)
est store M1

* max
reghdfe f_paperyear_max did whether_pat, absorb(firm_id year) vce(r)
est store M2

* mean
reghdfe f_paperyear_mean did whether_pat, absorb(firm_id year) vce(r)
est store M3

* median
reghdfe f_paperyear_med did whether_pat, absorb(firm_id year) vce(r)
est store M4



esttab M1 M2 M3 M4 using ${table_output}vintage.rtf, ///
	replace star( * 0.11 ** 0.05 *** 0.01 ) nogaps compress ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2, fmt(%15.0fc %9.3f) labels("Observations" "R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4") ///
	nonotes


	
********************************************************************************
************************************ CEM ***************************************
********************************************************************************

tempfile temp

use "${stata_output}DID_allfirm-level.dta", clear
keep firm_id year f_paperyear_med

duplicates drop
isid firm_id year

save `temp', replace

************************************* year *************************************

use ${stata_output}DID_allfirm-level_cem.dta, clear

merge 1:1 firm_id year using `temp'

keep if cem_matched==1

* min
reghdfe f_paperyear_min did whether_pat, absorb(firm_id year) vce(r)
est store M1

* max
reghdfe f_paperyear_max did whether_pat, absorb(firm_id year) vce(r)
est store M2

* mean
reghdfe f_paperyear_mean did whether_pat, absorb(firm_id year) vce(r)
est store M3

* median
reghdfe f_paperyear_med did whether_pat, absorb(firm_id year) vce(r)
est store M4


esttab M1 M2 M3 M4 using ${table_output}vintage_cem.rtf, ///
	replace star( * 0.11 ** 0.05 *** 0.01 ) nogaps compress ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2, fmt(%15.0fc %9.3f) labels("Observations" "R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4") ///
	nonotes
