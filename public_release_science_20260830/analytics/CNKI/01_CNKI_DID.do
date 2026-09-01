
/*******************************************************************************
Project: CNKI Analysis - Baseline DID
Script: 01_CNKI_DID.do

Purpose
  - Produce descriptive statistics and baseline DID estimates for CNKI outcomes.

Inputs (from ${stata_output})
  - CNKI_DID.dta

Outputs
  - ${table_output}CNKI_summary_stats.doc
  - ${table_output}CNKI_main.rtf

Notes
  - Requires user-written commands used in this script (for example: `asdoc`,
    `reghdfe`, `ppmlhdfe`, `distinct`, `esttab`).
*******************************************************************************/

* Paths are initialized by `00_run_all.do`.

********************************************************************************
**************************** Descriptive Statistics ****************************
********************************************************************************

use ${stata_output}CNKI_DID.dta, clear

global summary_statistics ///
pub_num f_u_colla_num pub_num_h f_u_colla_num_h ///DV
did //IV

* Table 1. Variable definitions and summary statistics
asdoc tabstat $summary_statistics, save(${table_output}CNKI_summary_stats.doc) replace stat(N mean sd p50 min max)

* Table 2. Correlation matrix
asdoc cor $summary_statistics, save(${table_output}CNKI_summary_stats.doc) append


* Table 3. Pre-treatment statistics of treated group
use ${stata_output}CNKI_DID.dta, clear
keep if entity_list == 1 & year < list_year

asdoc sum pub_num_w f_u_colla_num_w, ///
    save(${table_output}CNKI_summary_stats.doc) append ///
    stat(mean)


********************************************************************************
********************************** Main ****************************************
********************************************************************************

******************************* DV: publication num ****************************

*** (1) all sample
use ${stata_output}CNKI_DID.dta, clear

* OLS
reghdfe pub_num_w did, absorb(firm_id year) vce(r)
est store M1

* ln and OLS
reghdfe ln_pub_num did, absorb(firm_id year) vce(r)
est store M2

* Poisson
ppmlhdfe pub_num did, absorb(firm_id year) vce(r)
est store M3


esttab M1 M2 M3 using ${table_output}CNKI_main.rtf, ///
    replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
    b(%20.3f) se(%7.3f) r2(%9.3f) ///
    stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
    mtitles("Model 1" "Model 2" "Model 3") ///
    nonotes



