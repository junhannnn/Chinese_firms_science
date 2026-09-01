/*******************************************************************************
Project: Robustness Checks - Spillover Effects (Same-Size Peers)
Script: 01_Spillover_effect.do

Purpose
  - Test spillover effects by constructing a peer-treatment indicator
    (`did_spillover`) within industry/field, size group, and year.
  - Re-estimate outcomes for non-treated firms in PCS, CNKI, and WOS samples.

Inputs (from source-specific ${stata_output} folders)
  - CN_CN/DID_allfirm-level.dta
  - CNKI/CNKI_DID.dta
  - WOS/CN_WOS_DID.dta

Tables (saved under ${table_output})
  - robust_spillover.rtf

Notes
  - Size categories are constructed separately for PCS, CNKI, and WOS using
    source-specific publication/patent counts and grouping variables.
*******************************************************************************/
* Run via `5_Supplementary_materials/00_run_all.do` (depends on `RUN5_*` globals).

********************************************************************************
***************************** Spillover effect *********************************
********************************************************************************

********************************************************************************
***************************** Reliance on science ******************************
********************************************************************************

use ${RUN5_STATA_CN_CN}DID_allfirm-level.dta, clear

* Same-size peer groups (PCS)
bys firm_id: egen size = sum (f_patent_num)
/*
keep firm_id size
duplicates drop
sum size, d
*/
gen size_category = 0
replace size_category=1 if size<=1 //0-25%
replace size_category=2 if size==2 //25%-50%
replace size_category=3 if size>2 & size<4 //50%-75%
replace size_category=4 if size>=4 //75%-100%


bys industry size_category year: egen did_spillover = max(did) // considering spillover effect

drop if entity_list==1 // drop original treatment group

* OLS
reghdfe f_cite_science_num_w did_spillover whether_pat, absorb(firm_id year) vce(r)
est store M1

* ln and OLS
reghdfe ln_f_cite_science_num did_spillover whether_pat, absorb(firm_id year) vce(r)
est store M2

* Poisson
ppmlhdfe f_cite_science_num did_spillover whether_pat, absorb(firm_id year) vce(r)
est store M3

********************************************************************************
*********************************** CNKI ***************************************
********************************************************************************

use ${RUN5_STATA_CNKI}CNKI_DID.dta, clear
drop if 所属行业=="-" | 所属行业==""
* The original CNKI industry field is used for peer grouping.

* Same-size peer groups (CNKI)
bys firm_id: egen size = sum (pub_num)
/*
keep firm_id size
duplicates drop
sum size, d
*/
gen size_category = 0
replace size_category=1 if size==0 //0-25%
replace size_category=2 if size==1 //25%-50%
replace size_category=3 if size==2|size==3 //50%-75%
replace size_category=4 if size>=4 //75%-100%


bys 所属行业 size_category year: egen did_spillover = max(did) // considering spillover effect
drop if entity_list==1 // drop original treatment group


* OLS
reghdfe pub_num_w did_spillover, absorb(firm_id year) vce(r)
est store M4

* ln and OLS
reghdfe ln_pub_num did_spillover, absorb(firm_id year) vce(r)
est store M5

* Poisson
ppmlhdfe pub_num did_spillover, absorb(firm_id year) vce(r)
est store M6

********************************************************************************
*********************************** WOS ****************************************
********************************************************************************

use ${RUN5_STATA_WOS}CN_WOS_DID.dta, clear

drop if wos_field==""

* Same-size peer groups (WOS)
bys firm_id: egen size = sum (pub_num)
/*
keep firm_id size
duplicates drop
sum size, d
*/
gen size_category = 0
replace size_category=1 if size==0 //0-25%
replace size_category=2 if size==1 //25%-50%
replace size_category=3 if size==2 //50%-75%
replace size_category=4 if size>=3 //75%-100%


bys wos_field size_category year: egen did_spillover = max(did) // considering spillover effect
drop if entity_list==1 // drop original treatment group

* OLS
reghdfe pub_num_w did_spillover, absorb(firm_id year) vce(r)
est store M7

* ln and OLS
reghdfe ln_pub_num did_spillover, absorb(firm_id year) vce(r)
est store M8

* Poisson
ppmlhdfe pub_num did_spillover, absorb(firm_id year) vce(r)
est store M9


esttab M1 M2 M3 M4 M5 M6 M7 M8 M9 using ${RUN5_TABLE_CN_CN}robust_spillover.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did_spillover) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6" "Model 7" "Model 8" "Model 9") ///
	nonotes
