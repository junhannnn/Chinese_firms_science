/*******************************************************************************
Project: Robustness Checks - Alternative Outcome Measures
Script: 01_Alternative_measures.do

Purpose
  - Re-estimate the baseline sanction effect using alternative dependent
    variables across patent-science reliance (PCS), CNKI, and WOS samples.
  - Use binary and share-based measures to test robustness to outcome
    definitions.

Inputs (from source-specific ${stata_output} folders)
  - CN_CN/DID_allfirm-level.dta
  - CNKI/CNKI_DID.dta
  - WOS/CN_WOS_DID.dta

Tables (saved under ${table_output})
  - robust_alternative_measures.rtf

Notes
  - `${table_output}` is initialized in the CN_CN section and reused for the
    final combined table after the CNKI and WOS regressions.
*******************************************************************************/
* Run via `5_Supplementary_materials/00_run_all.do` (depends on `RUN5_*` globals).

********************************************************************************
************************** Alternative Measurements ****************************
********************************************************************************

*----------------------------*
* 1. PCS (patent-based measures)
*----------------------------*

use ${RUN5_STATA_CN_CN}DID_allfirm-level.dta, clear

* (1) Whether a firm's patent citing science - OLS
reghdfe f_cite_science did, absorb(year firm_id) vce(r)
est store M1

* (2) Percentage of sci-reliant patents among all patents of the firm - OLS
reghdfe f_cite_science_ratio did, absorb(year firm_id) vce(r)
est store M2

*----------------------------*
* 2. CNKI
*----------------------------*

use ${RUN5_STATA_CNKI}CNKI_DID.dta, clear
gen pub_num_dummy = 0
replace pub_num_dummy=1 if pub_num>1

reghdfe pub_num_dummy did, absorb(year firm_id) vce(r)
est store M3

*----------------------------*
* 3. WOS
*----------------------------*

use ${RUN5_STATA_WOS}CN_WOS_DID.dta, clear
gen pub_num_dummy = 1
replace pub_num_dummy=0 if pub_num==0

reghdfe pub_num_dummy did, absorb(year firm_id) vce(r)
est store M4


esttab M1 M2 M3 M4 using ${RUN5_TABLE_CN_CN}robust_alternative_measures.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4") ///
	nonotes
