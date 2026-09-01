

********************************************************************************
************************ 1. Firm's reliance on US tech *************************
********************************************************************************


******************************* (1) Full sample ********************************

use ${stata_output}DID_allfirm_mo.dta, clear

sum pre_uspat_ratio2 if pre_uspat_ratio2<., meanonly
gen dummy_uspat = pre_uspat_ratio2 >= r(mean)

asdoc tabstat dummy_uspat, ///
    save(${table_output}mo_summary_stats.doc) replace ///
    stat(N mean sd min max)

* OLS
reghdfe f_cite_science_num_w did##dummy_uspat whether_pat, absorb(firm_id year) vce(r)
est store M1

* ln and OLS
reghdfe ln_f_cite_science_num did##dummy_uspat whether_pat, absorb(firm_id year) vce(r)
est store M2

* Poission
ppmlhdfe f_cite_science_num did##dummy_uspat whether_pat, absorb(firm_id year) vce(r)
est store M3


*** Compute effect size

use ${stata_output}DID_allfirm_mo.dta, clear

sum pre_uspat_ratio2 if pre_uspat_ratio2<., meanonly
gen dummy_uspat = pre_uspat_ratio2 >= r(mean)


reghdfe f_cite_science_num_w did##dummy_uspat whether_pat, absorb(firm_id year) vce(r)

summ dummy_uspat
local sd = r(sd)

local add_effect = _b[1.did#1.dummy_uspat] * `sd'
display "Additional DID effect (1 SD increase) = " `add_effect'

summ f_cite_science_num_w if entity_list==1 & year<list_year
local premean = r(mean)

local pct = 100 * `add_effect' / `premean'
display "Percent of pre-treatment mean = " `pct' "%"



**************************** (2) matched sample ********************************

use ${stata_output}DID_allfirm_mo_cem.dta, clear

sum pre_uspat_ratio2 if pre_uspat_ratio2<., meanonly
gen dummy_uspat = pre_uspat_ratio2 >= r(mean)


reghdfe f_cite_science_num_w did##dummy_uspat whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r)
est store M4

reghdfe ln_f_cite_science_num did##dummy_uspat whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r)
est store M5

ppmlhdfe f_cite_science_num did##dummy_uspat whether_pat [pweight=cem_weights], absorb(firm_id year) vce(r)
est store M6


esttab M1 M2 M3 M4 M5 M6 using ${table_output}main_mo_uspat.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	nobaselevels drop("1.dummy_uspat") ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
	mgroups("Full sample" "Matched sample", pattern(1 0 0 1 0 0)) ///
	nonotes 

	
*** Compute effect size

use ${stata_output}DID_allfirm_mo_cem.dta, clear

sum pre_uspat_ratio2 if pre_uspat_ratio2<., meanonly
gen dummy_uspat = pre_uspat_ratio2 >= r(mean)

reghdfe f_cite_science_num_w did##dummy_uspat whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r)

keep if cem_matched==1
summ dummy_uspat
local sd = r(sd)

local add_effect = _b[1.did#1.dummy_uspat] * `sd'
display "Additional DID effect (1 SD increase) = " `add_effect'

summ f_cite_science_num_w if entity_list==1 & year<list_year
local premean = r(mean)

local pct = 100 * `add_effect' / `premean'
display "Percent of pre-treatment mean = " `pct' "%"	
