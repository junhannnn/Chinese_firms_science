/*******************************************************************************
Project: Science-linked patents—supplementary alternative outcomes
Script:  01_Alternative_measures.do

Purpose:
  Re-estimate the sanction effect using alternative measures of firms' reliance
  on science. The specifications cover patent-based outcomes and publication
  outcomes constructed from CNKI and Web of Science (WOS) data.

Main inputs:
  - ${RUN5_STATA_CN_CN}DID_allfirm-level.dta
  - ${RUN5_STATA_CNKI}CNKI_DID.dta
  - ${RUN5_STATA_WOS}CN_WOS_DID.dta

Main output:
  - ${RUN5_TABLE_CN_CN}robust_alternative_measures.rtf

Notes:
  Run through 3_Supplementary_materials/00_run_all.do so the RUN5_* path globals
  are available.
*******************************************************************************/

* ==============================================================================
* 1. Estimate models using patent-based alternative outcomes
* ==============================================================================

use ${RUN5_STATA_CN_CN}DID_allfirm-level.dta, clear

* Estimate the binary science-reliance outcome using linear fixed effects.
reghdfe f_cite_science did, absorb(year firm_id) vce(r)
est store M1

* Estimate the share of science-reliant patents using linear fixed effects.
reghdfe f_cite_science_ratio did, absorb(year firm_id) vce(r)
est store M2

* ==============================================================================
* 2. Estimate the CNKI publication-indicator model
* ==============================================================================

use ${RUN5_STATA_CNKI}CNKI_DID.dta, clear

* Identify firm-years with more than one CNKI publication.
gen pub_num_dummy = 0
replace pub_num_dummy=1 if pub_num>1

reghdfe pub_num_dummy did, absorb(year firm_id) vce(r)
est store M3

* ==============================================================================
* 3. Estimate the WOS publication-indicator model
* ==============================================================================

use ${RUN5_STATA_WOS}CN_WOS_DID.dta, clear

* Construct the WOS publication indicator from the publication count.
gen pub_num_dummy = 1
replace pub_num_dummy=0 if pub_num==0

reghdfe pub_num_dummy did, absorb(year firm_id) vce(r)
est store M4
* ==============================================================================
* 4. Export the combined alternative-outcome table
* ==============================================================================

esttab M1 M2 M3 M4 using ${RUN5_TABLE_CN_CN}robust_alternative_measures.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4") ///
	nonotes
