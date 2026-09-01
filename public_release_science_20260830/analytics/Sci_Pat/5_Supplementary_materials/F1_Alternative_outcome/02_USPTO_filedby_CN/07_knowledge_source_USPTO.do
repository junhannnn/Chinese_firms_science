/*******************************************************************************
Project: Robustness Checks - USPTO Knowledge Source Composition
Script: 07_knowledge_source_USPTO.do

Purpose
  - Test whether sanctioned Chinese firms change the composition of scientific
    knowledge sources in the USPTO-based firm-year panel.
  - Estimate DID models for source-specific counts (Chinese,
    foreign, U.S., and non-U.S. foreign science reliance).

Inputs (from ${stata_output})
  - USpatents_DID_allfirm.dta

Tables (saved under ${table_output})
  - robust_USPTO_source_num.rtf

Notes
  - This script mirrors the knowledge-source robustness design used in the main
    Chinese-firms analysis, but on the USPTO-based panel.
*******************************************************************************/
* Run via `00_run_all_6.do` (depends on shared path globals set by the runner).

/*
Table outputs:
  (1) robust_USPTO_source_num.rtf
*/


********************************************************************************
************************* Knowledge Source Composition (Counts) ****************
********************************************************************************

use ${stata_output}USpatents_DID_allfirm.dta, clear

* domestic science
reghdfe f_cite_cn_sci_num_w did, absorb(firm_id year) vce(r)
est store M1
reghdfe ln_f_cite_cn_sci_num did, absorb(firm_id year) vce(r)
est store M2
ppmlhdfe f_cite_cn_sci_num did, absorb(firm_id year) vce(r)
est store M3

* foreign science
reghdfe f_cite_foreign_sci_num_w did, absorb(firm_id year) vce(r)
est store M4
reghdfe ln_f_cite_foreign_sci_num did, absorb(firm_id year) vce(r)
est store M5
ppmlhdfe f_cite_foreign_sci_num did, absorb(firm_id year) vce(r)
est store M6

* US science
reghdfe f_cite_us_sci_num_w did, absorb(firm_id year) vce(r)
est store M7
reghdfe ln_f_cite_us_sci_num did, absorb(firm_id year) vce(r)
est store M8
ppmlhdfe f_cite_us_sci_num did, absorb(firm_id year) vce(r)
est store M9

* non-US foreign science
reghdfe f_cite_nonus_foreign_sci_num_w did, absorb(firm_id year) vce(r)
est store M10
reghdfe ln_f_cite_nonus_foreign_sci_num did, absorb(firm_id year) vce(r)
est store M11
ppmlhdfe f_cite_nonus_foreign_sci_num did, absorb(firm_id year) vce(r)
est store M12


esttab M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12 using ${table_output}robust_USPTO_source_num.rtf, ///
    replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
    b(%20.3f) se(%7.3f) r2(%9.3f) ///
    stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
    mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6" "Model 7" "Model 8" "Model 9" "Model 10" "Model 11" "Model 12") ///
    nonotes
