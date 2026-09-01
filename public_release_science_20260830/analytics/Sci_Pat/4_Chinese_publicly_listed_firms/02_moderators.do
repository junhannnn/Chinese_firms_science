

********************************************************************************
**************************** (1) Citation of US patents ************************
********************************************************************************

use ${stata_output}DID_listedfirm_mo.dta, clear

sum pre_uspat_ratio2 if pre_uspat_ratio2<., meanonly
gen dummy_uspat = pre_uspat_ratio2 >= r(mean)

global controls firm_size cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ academic_experience

* OLS
reghdfe f_cite_science_num_w did##dummy_uspat whether_pat $controls, absorb(ListedCoID year) vce(r) 
est store M1

* ln and OLS
reghdfe ln_f_cite_science_num did##dummy_uspat whether_pat $controls, absorb(ListedCoID year) vce(r) 
est store M2

* Poisson
ppmlhdfe f_cite_science_num did##dummy_uspat whether_pat $controls, absorb(ListedCoID year) vce(r) 
est store M3


********************************** CEM *****************************************

use ${stata_output}DID_listedfirm_mo_cem.dta, clear

sum pre_uspat_ratio2 if pre_uspat_ratio2<., meanonly
gen dummy_uspat = pre_uspat_ratio2 >= r(mean)

global controls firm_size cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ academic_experience

* OLS
reghdfe f_cite_science_num_w did##dummy_uspat whether_pat $controls [aweight=cem_weights], absorb(ListedCoID year) vce(r) 
est store M4

* ln and OLS
reghdfe ln_f_cite_science_num did##dummy_uspat whether_pat $controls [aweight=cem_weights], absorb(ListedCoID year) vce(r) 
est store M5

* Poisson
ppmlhdfe f_cite_science_num did##dummy_uspat whether_pat $controls [pweight=cem_weights], absorb(ListedCoID year) vce(r) 
est store M6


esttab M1 M2 M3 M4 M5 M6 using ${table_output}main_listed_mo_uspat.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	drop("did" "1.dummy_uspat" "0.did" "0.dummy_uspat" "0.did#0.dummy_uspat" "0.did#1.dummy_uspat" "1.did#0.dummy_uspat") ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
	mgroups("Full sample" "Matched sample", pattern(1 0 0 1 0 0)) ///
	nonotes
