/*******************************************************************************
Project: CNKI analysis
Script:  01_CNKI_DID.do

Purpose:
  Produce descriptive statistics and baseline difference-in-differences (DID)
  estimates for publication outcomes in the full Chinese-firm sample. The
  models report level, log-transformed, and Poisson specifications.

Main input:
  ${stata_output}CNKI_DID.dta

Main outputs:
  - ${table_output}CNKI_summary_stats.doc (descriptive and correlation tables)
  - ${table_output}CNKI_main.rtf (baseline DID estimates)

Required setup:
  00_run_all.do defines stata_output and table_output before calling this file.
  The script also requires the community-contributed commands asdoc, reghdfe,
  ppmlhdfe, and esttab.
*******************************************************************************/

* ==============================================================================
* 1. Produce descriptive statistics
* ==============================================================================

use ${stata_output}CNKI_DID.dta, clear

* Define publication outcomes and the DID indicator included in summary tables.
global summary_statistics ///
pub_num f_u_colla_num pub_num_h f_u_colla_num_h /// Dependent variables
did // DID indicator

* Append the three descriptive panels to a single Word-compatible document.
* Panel 1: distributional summary statistics.
asdoc tabstat $summary_statistics, save(${table_output}CNKI_summary_stats.doc) replace stat(N mean sd p50 min max)

* Panel 2: pairwise correlation matrix.
asdoc cor $summary_statistics, save(${table_output}CNKI_summary_stats.doc) append

* Panel 3: pre-treatment publication outcomes for treated firms.
use ${stata_output}CNKI_DID.dta, clear
keep if entity_list == 1 & year < list_year

asdoc sum pub_num_w f_u_colla_num_w, ///
    save(${table_output}CNKI_summary_stats.doc) append ///
    stat(mean)

* ==============================================================================
* 2. Estimate baseline DID models for publication counts
* ==============================================================================

use ${stata_output}CNKI_DID.dta, clear

* Model 1: linear specification for winsorized publication counts.
reghdfe pub_num_w did, absorb(firm_id year) vce(r)
est store M1

* Model 2: linear specification for log-transformed publication counts.
reghdfe ln_pub_num did, absorb(firm_id year) vce(r)
est store M2

* Model 3: Poisson specification for publication counts.
ppmlhdfe pub_num did, absorb(firm_id year) vce(r)
est store M3

* Export the three stored specifications as one regression table.
esttab M1 M2 M3 using ${table_output}CNKI_main.rtf, ///
    replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
    b(%20.3f) se(%7.3f) r2(%9.3f) ///
    stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
    mtitles("Model 1" "Model 2" "Model 3") ///
    nonotes
