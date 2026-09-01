

********************************************************************************
*********************** reliance on foreign science (num) **********************
********************************************************************************

use ${stata_output}DID_allfirm-level.dta, clear

* domestic science
reghdfe f_cite_cn_sci_num_w did whether_pat, absorb(firm_id year) vce(r) 
est store M1
reghdfe ln_f_cite_cn_sci_num did whether_pat, absorb(firm_id year) vce(r) 
est store M2
ppmlhdfe f_cite_cn_sci_num did whether_pat, absorb(firm_id year) vce(r) 
est store M3

* foreign science
reghdfe f_cite_foreign_sci_num_w did whether_pat, absorb(firm_id year) vce(r) 
est store M4
reghdfe ln_f_cite_foreign_sci_num did whether_pat, absorb(firm_id year) vce(r) 
est store M5
ppmlhdfe f_cite_foreign_sci_num did whether_pat, absorb(firm_id year) vce(r) 
est store M6

* US science
reghdfe f_cite_us_sci_num_w did whether_pat, absorb(firm_id year) vce(r) 
est store M7
reghdfe ln_f_cite_us_sci_num did whether_pat, absorb(firm_id year) vce(r) 
est store M8
ppmlhdfe f_cite_us_sci_num did whether_pat, absorb(firm_id year) vce(r)
est store M9

* non-US foreign science
reghdfe f_cite_nonus_foreign_sci_num_w did whether_pat, absorb(firm_id year) vce(r) 
est store M10
reghdfe ln_f_cite_nonus_foreign_sci_num did whether_pat, absorb(firm_id year) vce(r) 
est store M11
ppmlhdfe f_cite_nonus_foreign_sci_num did whether_pat, absorb(firm_id year) vce(r)
est store M12


esttab M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12 using ${table_output}compare_source_num.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6" "Model 7" "Model 8" "Model 9" "Model 10" "Model 11" "Model 12") ///
	nonotes 





************************************ CEM ***************************************

use ${stata_output}DID_allfirm-level_cem.dta, clear


* domestic science
reghdfe f_cite_cn_sci_num_w did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r) 
est store M1
reghdfe ln_f_cite_cn_sci_num did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r) 
est store M2
ppmlhdfe f_cite_cn_sci_num did whether_pat [pweight=cem_weights], absorb(firm_id year) vce(r) 
est store M3

* foreign science
reghdfe f_cite_foreign_sci_num_w did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r) 
est store M4
reghdfe ln_f_cite_foreign_sci_num did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r) 
est store M5
ppmlhdfe f_cite_foreign_sci_num did whether_pat [pweight=cem_weights], absorb(firm_id year) vce(r) 
est store M6

* US science
reghdfe f_cite_us_sci_num_w did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r) 
est store M7
reghdfe ln_f_cite_us_sci_num did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r) 
est store M8
ppmlhdfe f_cite_us_sci_num did whether_pat [pweight=cem_weights], absorb(firm_id year) vce(r)
est store M9

* non-US foreign science
reghdfe f_cite_nonus_foreign_sci_num_w did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r) 
est store M10
reghdfe ln_f_cite_nonus_foreign_sci_num did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r) 
est store M11
ppmlhdfe f_cite_nonus_foreign_sci_num did whether_pat [pweight=cem_weights], absorb(firm_id year) vce(r)
est store M12


esttab M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12 using ${table_output}compare_source_num_cem.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6" "Model 7" "Model 8" "Model 9" "Model 10" "Model 11" "Model 12") ///
	nonotes 



********************************************************************************
***************************** multiple coutry's science ************************
********************************************************************************

use ${stata_output}DID_allfirm-level.dta, clear

reghdfe f_multi_country_w did whether_pat, absorb(firm_id year) vce(r) 
est store M1

reghdfe ln_f_multi_country did whether_pat, absorb(firm_id year) vce(r) 
est store M2

ppmlhdfe f_multi_country did whether_pat, absorb(firm_id year) vce(r) 
est store M3

************************************ CEM ***************************************

use ${stata_output}DID_allfirm-level_cem.dta, clear

reghdfe f_multi_country_w did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r) 
est store M4

reghdfe ln_f_multi_country did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r) 
est store M5

ppmlhdfe f_multi_country did whether_pat [pweight=cem_weights], absorb(firm_id year) vce(r) 
est store M6

esttab M1 M2 M3 M4 M5 M6 using ${table_output}multi_coutry_science.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3") ///
	mgroups("All sample" "Matched sample", pattern(1 0 0 1 0 0)) ///
	nonotes 



********************************************************************************
*********************** reliance on foreign science (ratio) ********************
********************************************************************************

******************************** main effect ***********************************

use ${stata_output}DID_allfirm-level.dta, clear

* domestic science
reghdfe f_cite_cn_sci_ratio1 did whether_pat, absorb(firm_id year) vce(r) //+
est store M1

* foreign science
reghdfe f_cite_foreign_sci_ratio1 did whether_pat, absorb(firm_id year) vce(r) //+ 
est store M2

* US science
reghdfe f_cite_us_sci_ratio1 did whether_pat, absorb(firm_id year) vce(r) //+ not significant
est store M3

* non-US foreign science
reghdfe f_cite_nonus_foreign_sci_ratio1 did whether_pat, absorb(firm_id year) vce(r) //+
est store M4

esttab M1 M2 M3 M4 using ${table_output}compare_source_ratio.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2, fmt(%15.0fc %9.3f) labels("Observations" "R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4") ///
	nonotes 
	
******************************** Moderating effect *****************************

use ${stata_output}DID_allfirm_mo.dta, clear

sum pre_uspat_ratio2 if pre_uspat_ratio2<., meanonly
gen dummy_uspat = pre_uspat_ratio2 >= r(mean)

* domestic science
reghdfe f_cite_cn_sci_ratio1 did##dummy_uspat whether_pat, absorb(firm_id year) vce(r)
est store M1

* foreign science
reghdfe f_cite_foreign_sci_ratio1 did##dummy_uspat whether_pat, absorb(firm_id year) vce(r)
est store M2

* US science
reghdfe f_cite_us_sci_ratio1 did##dummy_uspat whether_pat, absorb(firm_id year) vce(r)
est store M3

* non-US foreign science
reghdfe f_cite_nonus_foreign_sci_ratio1 did##dummy_uspat whether_pat, absorb(firm_id year) vce(r)
est store M4


esttab M1 M2 M3 M4 using ${table_output}compare_source_ratio_mo.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2, fmt(%15.0fc %9.3f) labels("Observations" "R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4") ///
	nonotes 

