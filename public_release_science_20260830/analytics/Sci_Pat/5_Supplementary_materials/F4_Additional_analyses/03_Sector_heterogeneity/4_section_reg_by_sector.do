

	
use ${stata_output}DID_allfirm-level.dta, clear

bysort industry_id: gen tag1 = (_n == 1) //based on subclass
count if tag1 == 1 //618

gen industry_section = substr(industry, 1, 1)
encode industry_section, gen(industry_section_id)

bysort industry_section_id: gen tag2 = (_n == 1) //based on section
count if tag2 == 1 //8

*** OLS
reghdfe f_cite_science_num_w did whether_pat, absorb(firm_id year) vce(r)
est store M1
reghdfe f_cite_science_num_w did##ib1.industry_section_id whether_pat, absorb(firm_id year) vce(r)
est store M2

* ln and OLS
reghdfe ln_f_cite_science_num did whether_pat, absorb(firm_id year) vce(r)
est store M3
reghdfe ln_f_cite_science_num did##ib1.industry_section_id whether_pat, absorb(firm_id year) vce(r)
est store M4


esttab M1 M2 M3 M4 using ${table_output}industry_difference.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	nonotes

	
	
* drop one sector each time

reghdfe f_cite_science_num_w did whether_pat if industry_section_id!=1, absorb(firm_id year) vce(r)
est store M1
reghdfe f_cite_science_num_w did whether_pat if industry_section_id!=2, absorb(firm_id year) vce(r)
est store M2
reghdfe f_cite_science_num_w did whether_pat if industry_section_id!=3, absorb(firm_id year) vce(r)
est store M3
reghdfe f_cite_science_num_w did whether_pat if industry_section_id!=4, absorb(firm_id year) vce(r)
est store M4
reghdfe f_cite_science_num_w did whether_pat if industry_section_id!=5, absorb(firm_id year) vce(r)
est store M5
reghdfe f_cite_science_num_w did whether_pat if industry_section_id!=6, absorb(firm_id year) vce(r)
est store M6
reghdfe f_cite_science_num_w did whether_pat if industry_section_id!=7, absorb(firm_id year) vce(r)
est store M7
reghdfe f_cite_science_num_w did whether_pat if industry_section_id!=8, absorb(firm_id year) vce(r)
est store M8


esttab M1 M2 M3 M4 M5 M6 M7 M8 using ${table_output}robust_drop_one_industry_1.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	nonotes
	

reghdfe ln_f_cite_science_num did whether_pat if industry_section_id!=1, absorb(firm_id year) vce(r)
est store M1
reghdfe ln_f_cite_science_num did whether_pat if industry_section_id!=2, absorb(firm_id year) vce(r)
est store M2
reghdfe ln_f_cite_science_num did whether_pat if industry_section_id!=3, absorb(firm_id year) vce(r)
est store M3
reghdfe ln_f_cite_science_num did whether_pat if industry_section_id!=4, absorb(firm_id year) vce(r)
est store M4
reghdfe ln_f_cite_science_num did whether_pat if industry_section_id!=5, absorb(firm_id year) vce(r)
est store M5
reghdfe ln_f_cite_science_num did whether_pat if industry_section_id!=6, absorb(firm_id year) vce(r)
est store M6
reghdfe ln_f_cite_science_num did whether_pat if industry_section_id!=7, absorb(firm_id year) vce(r)
est store M7
reghdfe ln_f_cite_science_num did whether_pat if industry_section_id!=8, absorb(firm_id year) vce(r)
est store M8


esttab M1 M2 M3 M4 M5 M6 M7 M8 using ${table_output}robust_drop_one_industry_2.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	nonotes
	
	
ppmlhdfe f_cite_science_num did whether_pat if industry_section_id!=1, absorb(firm_id year) vce(r)
est store M1
ppmlhdfe f_cite_science_num did whether_pat if industry_section_id!=2, absorb(firm_id year) vce(r)
est store M2
ppmlhdfe f_cite_science_num did whether_pat if industry_section_id!=3, absorb(firm_id year) vce(r)
est store M3
ppmlhdfe f_cite_science_num did whether_pat if industry_section_id!=4, absorb(firm_id year) vce(r)
est store M4
ppmlhdfe f_cite_science_num did whether_pat if industry_section_id!=5, absorb(firm_id year) vce(r)
est store M5
ppmlhdfe f_cite_science_num did whether_pat if industry_section_id!=6, absorb(firm_id year) vce(r)
est store M6
ppmlhdfe f_cite_science_num did whether_pat if industry_section_id!=7, absorb(firm_id year) vce(r)
est store M7
ppmlhdfe f_cite_science_num did whether_pat if industry_section_id!=8, absorb(firm_id year) vce(r)
est store M8


esttab M1 M2 M3 M4 M5 M6 M7 M8 using ${table_output}robust_drop_one_industry_3.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	nonotes
