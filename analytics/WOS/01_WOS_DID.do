/*******************************************************************************
Project: WOS analysis
Script:  01_WOS_DID.do

Purpose:
  Produce descriptive statistics and baseline difference-in-differences (DID)
  estimates for Web of Science (WOS) publication outcomes in the full Chinese-
  firm sample. The models report level, log-transformed, and Poisson
  specifications.

Main input:
  ${stata_output}CN_WOS_DID.dta

Main outputs:
  - ${table_output}summary_stats_wos.doc (descriptive and correlation tables)
  - ${table_output}WOS.rtf (baseline DID estimates)

Required setup:
  Run this file through 00_run_all.do, which defines stata_output and
  table_output. The script also requires the community-contributed commands
  asdoc, reghdfe, ppmlhdfe, and esttab.
*******************************************************************************/

* ==============================================================================
* 1. Produce descriptive statistics
* ==============================================================================

use ${stata_output}CN_WOS_DID.dta, clear

* Define publication outcomes and the DID indicator included in summary tables.
global summary_statistics ///
pub_num f_u_colla_num pub_num_h f_u_colla_num_h /// Dependent variables
did // DID indicator

* Panel 1: distributional summary statistics.
asdoc tabstat $summary_statistics, save(${table_output}summary_stats_wos.doc) replace stat(N mean sd p50 min max)

* Panel 2: pairwise correlation matrix appended to the same document.
asdoc cor $summary_statistics, save(${table_output}summary_stats_wos.doc) append

* Report the pre-treatment mean publication count among treated firms.
use ${stata_output}CN_WOS_DID.dta, clear
keep if entity_list==1 & year<list_year // Retain treated firms before treatment.
sum pub_num_w // The resulting mean is reported in the Stata results window.

* ==============================================================================
* 2. Estimate baseline DID models for publication counts
* ==============================================================================

use ${stata_output}CN_WOS_DID.dta, clear

* Model 1: linear specification for winsorized publication counts.
reghdfe pub_num_w did, absorb(year firm_id) vce(r)
est store M1

* Model 2: linear specification for log-transformed publication counts.
reghdfe ln_pub_num did, absorb(year firm_id) vce(r)
est store M2

* Model 3: Poisson specification for publication counts.
ppmlhdfe pub_num did, absorb(year firm_id) vce(r)
est store M3

* Export the three stored specifications as one regression table.
esttab M1 M2 M3 using ${table_output}WOS.rtf, ///
    replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
    b(%20.3f) se(%7.3f) r2(%9.3f) ///
    stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
    mtitles("pub_num" "pub_num" "pub_num") ///
    nonotes
