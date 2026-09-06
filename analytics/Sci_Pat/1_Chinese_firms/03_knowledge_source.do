/*******************************************************************************
Project: Science-linked patents—Chinese-firm analysis
Script:  03_knowledge_source.do

Purpose:
  Examine how the estimated treatment effect varies with the geographic source
  and international breadth of scientific knowledge cited by Chinese-firm
  patents. The script compares domestic, foreign, U.S., and non-U.S. foreign
  sources using count and share outcomes in full and CEM-weighted samples.

Main inputs:
  - ${stata_output}DID_allfirm-level.dta (full firm-year panel)
  - ${stata_output}DID_allfirm-level_cem.dta (CEM panel and weights)

Main outputs:
  - ${table_output}compare_source_num.rtf
  - ${table_output}compare_source_num_cem.rtf
  - ${table_output}multi_coutry_science.rtf
  - ${table_output}compare_source_ratio.rtf

Required setup:
  The master runner defines stata_output and table_output before calling this
  file. The script also requires the community-contributed commands reghdfe,
  ppmlhdfe, and esttab.
*******************************************************************************/

* ==============================================================================
* 1. Estimate full-sample models by geographic source of cited science
* ==============================================================================

use ${stata_output}DID_allfirm-level.dta, clear

* Models 1-3: domestic scientific sources.
reghdfe f_cite_cn_sci_num_w did whether_pat, absorb(firm_id year) vce(r) 
est store M1
reghdfe ln_f_cite_cn_sci_num did whether_pat, absorb(firm_id year) vce(r) 
est store M2
ppmlhdfe f_cite_cn_sci_num did whether_pat, absorb(firm_id year) vce(r) 
est store M3

* Models 4-6: all foreign scientific sources.
reghdfe f_cite_foreign_sci_num_w did whether_pat, absorb(firm_id year) vce(r) 
est store M4
reghdfe ln_f_cite_foreign_sci_num did whether_pat, absorb(firm_id year) vce(r) 
est store M5
ppmlhdfe f_cite_foreign_sci_num did whether_pat, absorb(firm_id year) vce(r) 
est store M6

* Models 7-9: U.S. scientific sources.
reghdfe f_cite_us_sci_num_w did whether_pat, absorb(firm_id year) vce(r) 
est store M7
reghdfe ln_f_cite_us_sci_num did whether_pat, absorb(firm_id year) vce(r) 
est store M8
ppmlhdfe f_cite_us_sci_num did whether_pat, absorb(firm_id year) vce(r)
est store M9

* Models 10-12: non-U.S. foreign scientific sources.
reghdfe f_cite_nonus_foreign_sci_num_w did whether_pat, absorb(firm_id year) vce(r) 
est store M10
reghdfe ln_f_cite_nonus_foreign_sci_num did whether_pat, absorb(firm_id year) vce(r) 
est store M11
ppmlhdfe f_cite_nonus_foreign_sci_num did whether_pat, absorb(firm_id year) vce(r)
est store M12


* Export the twelve source-specific count models.
esttab M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12 using ${table_output}compare_source_num.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) drop("whether_pat") ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6" "Model 7" "Model 8" "Model 9" "Model 10" "Model 11" "Model 12") ///
	nonotes 





* ==============================================================================
* 2. Estimate CEM-weighted models by geographic source of cited science
* ==============================================================================

use ${stata_output}DID_allfirm-level_cem.dta, clear


* Models 1-3: domestic scientific sources.
reghdfe f_cite_cn_sci_num_w did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r) 
est store M1
reghdfe ln_f_cite_cn_sci_num did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r) 
est store M2
ppmlhdfe f_cite_cn_sci_num did whether_pat [pweight=cem_weights], absorb(firm_id year) vce(r) 
est store M3

* Models 4-6: all foreign scientific sources.
reghdfe f_cite_foreign_sci_num_w did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r) 
est store M4
reghdfe ln_f_cite_foreign_sci_num did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r) 
est store M5
ppmlhdfe f_cite_foreign_sci_num did whether_pat [pweight=cem_weights], absorb(firm_id year) vce(r) 
est store M6

* Models 7-9: U.S. scientific sources.
reghdfe f_cite_us_sci_num_w did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r) 
est store M7
reghdfe ln_f_cite_us_sci_num did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r) 
est store M8
ppmlhdfe f_cite_us_sci_num did whether_pat [pweight=cem_weights], absorb(firm_id year) vce(r)
est store M9

* Models 10-12: non-U.S. foreign scientific sources.
reghdfe f_cite_nonus_foreign_sci_num_w did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r) 
est store M10
reghdfe ln_f_cite_nonus_foreign_sci_num did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r) 
est store M11
ppmlhdfe f_cite_nonus_foreign_sci_num did whether_pat [pweight=cem_weights], absorb(firm_id year) vce(r)
est store M12


* Export the twelve CEM-weighted source-specific count models.
esttab M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12 using ${table_output}compare_source_num_cem.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) drop("whether_pat") ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6" "Model 7" "Model 8" "Model 9" "Model 10" "Model 11" "Model 12") ///
	nonotes 



* ==============================================================================
* 3. Estimate effects on the international breadth of cited science
* ==============================================================================

* Estimate full-sample level, log, and Poisson specifications.
use ${stata_output}DID_allfirm-level.dta, clear

reghdfe f_multi_country_w did whether_pat, absorb(firm_id year) vce(r) 
est store M1

reghdfe ln_f_multi_country did whether_pat, absorb(firm_id year) vce(r) 
est store M2

ppmlhdfe f_multi_country did whether_pat, absorb(firm_id year) vce(r) 
est store M3

* Repeat the three specifications using the CEM panel and weights.
use ${stata_output}DID_allfirm-level_cem.dta, clear

reghdfe f_multi_country_w did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r) 
est store M4

reghdfe ln_f_multi_country did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r) 
est store M5

ppmlhdfe f_multi_country did whether_pat [pweight=cem_weights], absorb(firm_id year) vce(r) 
est store M6

* Export full-sample and CEM-weighted estimates in one table.
esttab M1 M2 M3 M4 M5 M6 using ${table_output}multi_coutry_science.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) drop("whether_pat") ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3") ///
	mgroups("All sample" "Matched sample", pattern(1 0 0 1 0 0)) ///
	nonotes 



* ==============================================================================
* 4. Estimate full-sample effects on geographic-source shares
* ==============================================================================

use ${stata_output}DID_allfirm-level.dta, clear

* Model 1: share of cited science from domestic sources.
reghdfe f_cite_cn_sci_ratio1 did whether_pat, absorb(firm_id year) vce(r) // Geographic-source share specification.
est store M1

* Model 2: share of cited science from all foreign sources.
reghdfe f_cite_foreign_sci_ratio1 did whether_pat, absorb(firm_id year) vce(r) // Geographic-source share specification.
est store M2

* Model 3: share of cited science from U.S. sources.
reghdfe f_cite_us_sci_ratio1 did whether_pat, absorb(firm_id year) vce(r) // Geographic-source share specification.
est store M3

* Model 4: share of cited science from non-U.S. foreign sources.
reghdfe f_cite_nonus_foreign_sci_ratio1 did whether_pat, absorb(firm_id year) vce(r) // Geographic-source share specification.
est store M4

* Export the four geographic-source share models.
esttab M1 M2 M3 M4 using ${table_output}compare_source_ratio.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) drop("whether_pat") ///
	stats(N r2, fmt(%15.0fc %9.3f) labels("Observations" "R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4") ///
	nonotes 
