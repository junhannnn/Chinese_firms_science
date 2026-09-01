/*******************************************************************************
Project: Robustness Checks - Other Sanctions Lists
Script: 02_Other_lists.do

Purpose
  - Run robustness checks related to overlap with other sanctions lists using:
      (i) alternative treatment-set definitions, and
      (ii) a two-indicator specification (`did` + `did_other`).
  - This script consolidates both analyses into one file while preserving the
    original execution order and logic.

Notes
  - Section A: alternative treatment-set definitions.
  - Section B: two-indicator specification.
*******************************************************************************/


********************************************************************************
* Section A: Alternative Treatment-Set Definitions
********************************************************************************

/*******************************************************************************
Project: Robustness Checks - Other Sanctions Lists (Alternative Treatment Sets)
Script: 02_Other_lists.do (Section A)

Purpose
  - Test robustness to overlap with firms appearing on other sanctions lists.
  - Compare two designs for PCS, CNKI, and WOS samples:
    (i) exclude firms that are only on other lists from the control group, and
    (ii) expand the treatment group to include firms on other lists.

Inputs (from source-specific ${stata_output} folders)
  - CN_CN/DID_allfirm-level.dta
  - CNKI/CNKI_DID.dta
  - WOS/CN_WOS_DID.dta

Tables (saved under ${table_output})
  - robust_otherlist_pcs.rtf
  - robust_otherlist_cnki.rtf
  - robust_otherlist_wos.rtf

Notes
  - The script begins with diagnostic tabulations of overlap between `entity_list`
    and `other_list` in the PCS sample before running regressions.
*******************************************************************************/

******************************** Other list ************************************

use ${RUN5_STATA_CN_CN}DID_allfirm-level.dta, clear
keep firm_id other_list entity_list
duplicates drop
keep if entity_list==1 | other_list==1

tabstat other_list entity_list, stat(sum)
/*
   Stats |  other_~t  entity~t
---------+--------------------
     Sum |       208       293
------------------------------

*/

gen both = (other_list==1 & entity_list==1)
gen only_other = (other_list==1 & entity_list==0)
gen only_EL = (other_list==0 & entity_list==1)

tabstat both only_other only_EL, stat(sum)
/*
   Stats |      both  only_o~r   only_EL
---------+------------------------------
     Sum |        91       117       202
----------------------------------------

*/


********************************************************************************
********************* 1. Exclude firms only on other lists *********************
********************************************************************************

/*
Treatment group: firms included in the Entity List
Control group: firms not included in the Entity List, excluding firms that are
               included only in other sanctions lists
*/

use ${RUN5_STATA_CN_CN}DID_allfirm-level.dta, clear

drop if other_list==1 & entity_list==0 // exclude firms only on other lists

* OLS
reghdfe f_cite_science_num_w did whether_pat, absorb(firm_id year) vce(r)
est store M1

* ln and OLS
reghdfe ln_f_cite_science_num did whether_pat, absorb(firm_id year) vce(r)
est store M2

* Poisson
ppmlhdfe f_cite_science_num did whether_pat, absorb(firm_id year) vce(r)
est store M3
********************************************************************************
******* 2. Also treat firms on other lists as part of the treatment group ******
********************************************************************************

/*
Treatment group: firms included in the Entity List or other sanctions lists
Control group: firms not included in any of these lists
*/

use ${RUN5_STATA_CN_CN}DID_allfirm-level.dta, clear

drop did dif_year

gen did=0
replace did=1 if (year>=list_year & entity_list==1)|(year>=otherlist_year & other_list==1)

gen dif_year_EL = year-list_year
gen dif_year_OL = year-otherlist_year
egen dif_year = rowmax(dif_year_EL dif_year_OL)

order firm_id year entity_list list_year other_list otherlist_year did dif_year_EL dif_year_OL dif_year
sort firm_id year


* OLS
reghdfe f_cite_science_num_w did whether_pat, absorb(year firm_id) vce(r)
est store M4

* ln and OLS
reghdfe ln_f_cite_science_num did whether_pat, absorb(year firm_id) vce(r)
est store M5

* Poisson
ppmlhdfe f_cite_science_num did whether_pat, absorb(year firm_id) vce(r)
est store M6
esttab M1 M2 M3 M4 M5 M6 using ${RUN5_TABLE_CN_CN}robust_otherlist_pcs.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
	mgroups("Group 1" "Group 2", pattern(1 0 0 1 0 0)) ///
	note("PCS sample")

********************************************************************************
******************************* CNKI (other list) ******************************
********************************************************************************

********************* 1. Exclude firms only on other lists *********************

/*
Treatment group: firms included in the Entity List
Control group: firms not included in the Entity List, excluding firms that are
               included only in other sanctions lists
*/

use ${RUN5_STATA_CNKI}CNKI_DID.dta, clear

drop if other_list==1 & entity_list==0 // exclude firms only on other lists

* OLS
reghdfe pub_num_w did, absorb(firm_id year) vce(r)
est store M1

* ln and OLS
reghdfe ln_pub_num did, absorb(firm_id year) vce(r)
est store M2

* Poisson
ppmlhdfe pub_num did, absorb(firm_id year) vce(r)
est store M3
******* 2. Also treat firms on other lists as part of the treatment group ******

/*
Treatment group: firms included in the Entity List or other sanctions lists
Control group: firms not included in any of these lists
*/

use ${RUN5_STATA_CNKI}CNKI_DID.dta, clear

drop did

gen did=0
replace did=1 if (year>=list_year & entity_list==1)|(year>=otherlist_year & other_list==1)

gen dif_year_EL = year-list_year
gen dif_year_OL = year-otherlist_year
egen dif_year = rowmax(dif_year_EL dif_year_OL)

order firm_id year entity_list list_year other_list otherlist_year did dif_year_EL dif_year_OL dif_year
sort firm_id year


* OLS
reghdfe pub_num_w did, absorb(firm_id year) vce(r)
est store M4

* ln and OLS
reghdfe ln_pub_num did, absorb(firm_id year) vce(r)
est store M5

* Poisson
ppmlhdfe pub_num did, absorb(firm_id year) vce(r)
est store M6


esttab M1 M2 M3 M4 M5 M6 using ${RUN5_TABLE_CN_CN}robust_otherlist_cnki.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
	mgroups("Group 1" "Group 2", pattern(1 0 0 1 0 0)) ///
	note("CNKI sample")


********************************************************************************
******************************** WOS (other list) ******************************
********************************************************************************

********************* 1. Exclude firms only on other lists *********************

/*
Treatment group: firms included in the Entity List
Control group: firms not included in the Entity List, excluding firms that are
               included only in other sanctions lists
*/

use ${RUN5_STATA_WOS}CN_WOS_DID.dta, clear

drop if other_list==1 & entity_list==0 // exclude firms only on other lists

* OLS
reghdfe pub_num_w did, absorb(firm_id year) vce(r)
est store M1

* ln and OLS
reghdfe ln_pub_num did, absorb(firm_id year) vce(r)
est store M2

* Poisson
ppmlhdfe pub_num did, absorb(firm_id year) vce(r)
est store M3
******* 2. Also treat firms on other lists as part of the treatment group ******

/*
Treatment group: firms included in the Entity List or other sanctions lists
Control group: firms not included in any of these lists
*/

use ${RUN5_STATA_WOS}CN_WOS_DID.dta, clear

drop did

gen did=0
replace did=1 if (year>=list_year & entity_list==1)|(year>=otherlist_year & other_list==1)

gen dif_year_EL = year-list_year
gen dif_year_OL = year-otherlist_year
egen dif_year = rowmax(dif_year_EL dif_year_OL)

order firm_id year entity_list list_year other_list otherlist_year did dif_year_EL dif_year_OL dif_year
sort firm_id year


* OLS
reghdfe pub_num_w did, absorb(firm_id year) vce(r)
est store M4

* ln and OLS
reghdfe ln_pub_num did, absorb(firm_id year) vce(r)
est store M5

* Poisson
ppmlhdfe pub_num did, absorb(firm_id year) vce(r)
est store M6


esttab M1 M2 M3 M4 M5 M6 using ${RUN5_TABLE_CN_CN}robust_otherlist_wos.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
	mgroups("Group 1" "Group 2", pattern(1 0 0 1 0 0)) ///
	note("WOS sample")


********************************************************************************
* Section B: Two-Indicator Specification
********************************************************************************

/*******************************************************************************
Project: Robustness Checks - Other Sanctions Lists (Two-IV Specification)
Script: 02_Other_lists.do (Section B)

Purpose
  - Estimate robustness models that include separate indicators for Entity List
    treatment (`did`) and other-list treatment (`did_other`) simultaneously.
  - Compare results across PCS, CNKI, and WOS samples.

Inputs (from source-specific ${stata_output} folders)
  - CN_CN/DID_allfirm-level.dta
  - CNKI/CNKI_DID.dta
  - WOS/CN_WOS_DID.dta

Tables (saved under ${table_output})
  - robust_otherlist_twoIV.rtf

Notes
  - `did_other` is defined using `otherlist_year` while the original `did`
    variable is retained from the source datasets.
*******************************************************************************/

*----------------------------*
* 0. PCS (other-list indicator as second treatment variable)
*----------------------------*

********************************************************************************
****************************** PCS (other list) ********************************
********************************************************************************

use ${RUN5_STATA_CN_CN}DID_allfirm-level.dta, clear

gen did_other = 0
replace did_other = 1 if (year>=otherlist_year & other_list==1)


* OLS
reghdfe f_cite_science_num_w did did_other whether_pat, absorb(firm_id year) vce(r)
est store M1

* ln and OLS
reghdfe ln_f_cite_science_num did did_other whether_pat, absorb(firm_id year) vce(r)
est store M2

* Poisson
ppmlhdfe f_cite_science_num did did_other whether_pat, absorb(firm_id year) vce(r)
est store M3
********************************************************************************
******************************* CNKI (other list) ******************************
********************************************************************************

use ${RUN5_STATA_CNKI}CNKI_DID.dta, clear

gen did_other = 0
replace did_other = 1 if (year>=otherlist_year & other_list==1)

* OLS
reghdfe pub_num_w did did_other, absorb(firm_id year) vce(r)
est store M4

* ln and OLS
reghdfe ln_pub_num did did_other, absorb(firm_id year) vce(r)
est store M5

* Poisson
ppmlhdfe pub_num did did_other, absorb(firm_id year) vce(r)
est store M6
********************************************************************************
******************************* WOS (other list) *******************************
********************************************************************************

use ${RUN5_STATA_WOS}CN_WOS_DID.dta, clear

gen did_other = 0
replace did_other = 1 if (year>=otherlist_year & other_list==1)

* OLS
reghdfe pub_num_w did did_other, absorb(firm_id year) vce(r)
est store M7

* ln and OLS
reghdfe ln_pub_num did did_other, absorb(firm_id year) vce(r)
est store M8

* Poisson
ppmlhdfe pub_num did did_other, absorb(firm_id year) vce(r)
est store M9

esttab M1 M2 M3 M4 M5 M6 M7 M8 M9 using ${RUN5_TABLE_CN_CN}robust_otherlist_twoIV.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6" "Model 7" "Model 8" "Model 9") ///
	mgroups("PCS" "CNKI" "WOS", pattern(1 0 0 1 0 0 1 0 0)) ///
	nonotes
