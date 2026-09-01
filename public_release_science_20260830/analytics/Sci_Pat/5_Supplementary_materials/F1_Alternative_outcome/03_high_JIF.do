/*******************************************************************************
Project: Robustness Checks - High-Impact Publication Subsamples
Script: 03_high_JIF.do

Purpose
  - Test robustness using only high-JIF publication outcomes in CNKI and WOS.

Inputs (from source-specific ${stata_output} folders)
  - CNKI/CNKI_DID.dta
  - WOS/CN_WOS_DID.dta

Tables (saved under ${table_output})
  - robust_high_JIF.rtf

Notes
  - In the current script, `${table_output}` is set to the WOS output folder
    before each combined `esttab` export, so both result tables are written
    under the WOS table path.
*******************************************************************************/
* Run via `5_Supplementary_materials/00_run_all.do` (depends on `RUN5_*` globals).

********************************************************************************
******************************* High-JIF Subsample *****************************
********************************************************************************

*----------------------------*
* High-JIF outcomes
*----------------------------*

************************************* CNKI *************************************

use ${RUN5_STATA_CNKI}CNKI_DID.dta, clear

* OLS
reghdfe pub_num_h_w did, absorb(year firm_id) vce(r)
est store M1

* ln and OLS
reghdfe ln_pub_num_h did, absorb(year firm_id) vce(r)
est store M2

* Poisson
ppmlhdfe pub_num_h did, absorb(year firm_id) vce(r)
est store M3

************************************* WOS **************************************

use ${RUN5_STATA_WOS}CN_WOS_DID.dta, clear

* OLS
reghdfe pub_num_h_w did, absorb(year firm_id) vce(r)
est store M4

* ln and OLS
reghdfe ln_pub_num_h did, absorb(year firm_id) vce(r)
est store M5

* Poisson
ppmlhdfe pub_num_h did, absorb(year firm_id) vce(r)
est store M6

esttab M1 M2 M3 M4 M5 M6 using ${RUN5_TABLE_WOS}robust_high_JIF.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
	nonotes
