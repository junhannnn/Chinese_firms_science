/*******************************************************************************
Project: WOS Pipeline - Baseline DID and CEM
Script: 02_WOS_DID.do

Purpose
  - Produce baseline WOS DID estimates for publication outcomes.
  - Build a CEM-matched sample and report matched-sample regressions.

Inputs
  - `${stata_output}CN_WOS_DID.dta` (created by `01_WOS_data_cleaning.do`).

Outputs
  - `${table_output}summary_stats_wos.doc`
  - `${table_output}WOS.rtf`
  - `${stata_output}CN_WOS_DID_cem.dta`
  - `${table_output}WOS_cem.rtf`

Instructions
  - Run after `01_WOS_data_cleaning.do`.
  - Keep this script as the source for baseline and matched DID tables in WOS.
*******************************************************************************/

* Path globals are defined centrally in `00_run_all.do`.


********************************************************************************
************************* descriptive statistics *******************************
********************************************************************************

use ${stata_output}CN_WOS_DID.dta, clear

global summary_statistics ///
pub_num f_u_colla_num pub_num_h f_u_colla_num_h ///DV
did //IV

* Table 1. Variable definitions and summary statistics
asdoc tabstat $summary_statistics, save(${table_output}summary_stats_wos.doc) replace stat(N mean sd p50 min max)

* Table 2. Correlation matrix
asdoc cor $summary_statistics, save(${table_output}summary_stats_wos.doc) append



use ${stata_output}CN_WOS_DID.dta, clear
keep if entity_list==1 & year<list_year //pre-treatment of the treated group
sum pub_num_w //0.330


********************************************************************************
************************************ Main **************************************
********************************************************************************

******************************* DV: publication num ****************************

*** (1) all sample

use ${stata_output}CN_WOS_DID.dta, clear

* OLS
reghdfe pub_num_w did, absorb(year firm_id) vce(r)
est store M1

* ln and OLS
reghdfe ln_pub_num did, absorb(year firm_id) vce(r)
est store M2

* Poisson
ppmlhdfe pub_num did, absorb(year firm_id) vce(r)
est store M3


esttab M1 M2 M3 using ${table_output}WOS.rtf, ///
    replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
    b(%20.3f) se(%7.3f) r2(%9.3f) ///
    stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
    mtitles("pub_num" "pub_num" "pub_num") ///
    nonotes

