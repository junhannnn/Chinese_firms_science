/*******************************************************************************
Project: Chinese Publicly Listed Firms - Government Subsidy Mediation
Script: gov_subsidy.do

Purpose
  - Test whether government subsidy variables mediate the treatment effect in
    the listed-firm DID setting.
  - Export mediation and regression result tables.

Inputs (from ${stata_output})
  - DID_listedfirm-level.dta

Tables (saved under ${table_output})
  - main_listed_me_gov.rtf

Notes
  - This script assumes path globals are defined by
    4_Chinese_publicly_listed_firms/00_run_all_4.do.
*******************************************************************************/
* Run via `00_run_all_4.do` (depends on shared path globals set by the runner).


********************************************************************************
******************************* Post → Subsidy → Y *****************************
********************************************************************************

use ${stata_output}DID_listedfirm-level.dta, clear

xtset ListedCoID year

replace subsidy = 0 if subsidy < 0 | subsidy == .
gen subsidy_adj = subsidy / 100000000

gen F1_subsidy_adj = F1.subsidy_adj
gen F2_f_cite_science_num_w = F2.f_cite_science_num_w
gen F2_ln_f_cite_science_num = F2.ln_f_cite_science_num
gen F2_f_cite_science_num = F2.f_cite_science_num

global controls cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ academic_experience


********************************************************************************
*** (1) Winsorized outcome
********************************************************************************

* define common sample using the full mediation model
reghdfe F2_f_cite_science_num_w did F1_subsidy_adj whether_pat $controls, ///
    absorb(year ListedCoID)

gen byte sample_w = e(sample)

* X -> Y
reghdfe F2_f_cite_science_num_w did whether_pat $controls if sample_w, ///
    absorb(year ListedCoID) vce(r)
est store M1

* X -> M
reghdfe F1_subsidy_adj did whether_pat $controls if sample_w, ///
    absorb(year ListedCoID) vce(r)
est store M2

* X + M -> Y
reghdfe F2_f_cite_science_num_w did F1_subsidy_adj whether_pat $controls if sample_w, ///
    absorb(year ListedCoID) vce(r)
est store M3


********************************************************************************
*** (2) Log outcome
********************************************************************************

reghdfe F2_ln_f_cite_science_num did F1_subsidy_adj whether_pat $controls, ///
    absorb(year ListedCoID)

gen byte sample_ln = e(sample)

* X -> Y
reghdfe F2_ln_f_cite_science_num did whether_pat $controls if sample_ln, ///
    absorb(year ListedCoID) vce(r)
est store M4

* X -> M
reghdfe F1_subsidy_adj did whether_pat $controls if sample_ln, ///
    absorb(year ListedCoID) vce(r)
est store M5

* X + M -> Y
reghdfe F2_ln_f_cite_science_num did F1_subsidy_adj whether_pat $controls if sample_ln, ///
    absorb(year ListedCoID) vce(r)
est store M6


********************************************************************************
*** (3) Poisson outcome
********************************************************************************

ppmlhdfe F2_f_cite_science_num did F1_subsidy_adj whether_pat $controls, ///
    absorb(year ListedCoID)

gen byte sample_pois = e(sample)

* X -> Y
ppmlhdfe F2_f_cite_science_num did whether_pat $controls if sample_pois, ///
    absorb(year ListedCoID) vce(r)
est store M7

* X -> M
reghdfe F1_subsidy_adj did whether_pat $controls if sample_pois, ///
    absorb(year ListedCoID) vce(r)
est store M8

* X + M -> Y
ppmlhdfe F2_f_cite_science_num did F1_subsidy_adj whether_pat $controls if sample_pois, ///
    absorb(year ListedCoID) vce(r)
est store M9


esttab M1 M2 M3 M4 M5 M6 M7 M8 M9 using ${table_output}main_listed_me_gov.rtf, ///
    replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did F1_subsidy_adj) ///
    b(%20.3f) se(%7.3f) r2(%9.3f) ///
    stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
    mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6" "Model 7" "Model 8" "Model 9") ///
    mgroups("winsor" "ln" "poisson", pattern(1 0 0 1 0 0 1 0 0)) ///
    drop(whether_pat) nonotes



********************************************************************************
********************* 1. Heterogeneity analysis: Oversea ratio *****************
********************************************************************************

use ${stata_output}DID_listedfirm_mo.dta, clear
xtset Symbol year

replace subsidy=0 if subsidy<0|subsidy==.
gen subsidy_adj = subsidy / 1000000000 //10000w

gen F1_subsidy_adj = F1.subsidy_adj
gen F2_f_cite_science_num_w = F2.f_cite_science_num_w
gen F2_ln_f_cite_science_num = F2.ln_f_cite_science_num
gen F2_f_cite_science_num = F2.f_cite_science_num

global controls cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ academic_experience

sum pre_oversea_ratio, d
gen high_lev = pre_oversea_ratio >= 15.05215 if !missing(pre_oversea_ratio)

gen sample_low = !missing(F2_f_cite_science_num_w, F1_subsidy_adj, did, whether_pat, cash, RDSpendSumRatio, ROA, AssetLiabilityRatio, TobinQ, academic_experience) if high_lev==0

gen sample_high = !missing(F2_f_cite_science_num_w, F1_subsidy_adj, did, whether_pat, cash, RDSpendSumRatio, ROA, AssetLiabilityRatio, TobinQ, academic_experience) if high_lev==1


******************************** Low oversea ratio *****************************
*** X -> Y
reghdfe F2_f_cite_science_num_w did whether_pat $controls if sample_low==1, absorb(year ListedCoID) vce(r)
est store M1
*** X -> M
reghdfe F1_subsidy_adj did $controls if sample_low==1, absorb(year ListedCoID) vce(r)
est store M2
*** add mediator
reghdfe F2_f_cite_science_num_w did F1_subsidy_adj whether_pat $controls if sample_low==1, absorb(year ListedCoID) vce(r)
est store M3
	

******************************** High oversea ratio *****************************
*** X -> Y
reghdfe F2_f_cite_science_num_w did whether_pat $controls if sample_high==1, absorb(year ListedCoID) vce(r)
est store M4
*** X -> M
reghdfe F1_subsidy_adj did $controls if sample_high==1, absorb(year ListedCoID) vce(r)
est store M5
*** add mediator
reghdfe F2_f_cite_science_num_w did F1_subsidy_adj whether_pat $controls if sample_high==1, absorb(year ListedCoID) vce(r)
est store M6


esttab M1 M2 M3 M4 M5 M6 using ${table_output}main_listed_me_gov_oversea.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
	mgroups("Low oversea ratio" "High oversea ratio", pattern(1 0 0 1 0 0)) ///
	drop(whether_pat) nonotes

	
********************************************************************************
********************* 2. Heterogeneity analysis: Reliance on US tech ***********
********************************************************************************
	
use ${stata_output}DID_listedfirm_mo.dta, clear
xtset Symbol year

sum pre_uspat_ratio2 if pre_uspat_ratio2<., meanonly
gen dummy_uspat = pre_uspat_ratio2 >= r(mean)

replace subsidy=0 if subsidy<0|subsidy==.
gen subsidy_adj = subsidy / 1000000000 //10000w

gen F1_subsidy_adj = F1.subsidy_adj
gen F2_f_cite_science_num_w = F2.f_cite_science_num_w
gen F2_ln_f_cite_science_num = F2.ln_f_cite_science_num
gen F2_f_cite_science_num = F2.f_cite_science_num

global controls cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ academic_experience

gen sample_low = !missing(F2_f_cite_science_num_w, F1_subsidy_adj, did, whether_pat, cash, RDSpendSumRatio, ROA, AssetLiabilityRatio, TobinQ, academic_experience) if dummy_uspat==0

gen sample_high = !missing(F2_f_cite_science_num_w, F1_subsidy_adj, did, whether_pat, cash, RDSpendSumRatio, ROA, AssetLiabilityRatio, TobinQ, academic_experience) if dummy_uspat==1


******************************** Low reliance on US tech ***********************
*** X -> Y
reghdfe F2_f_cite_science_num_w did whether_pat $controls if sample_low==1, absorb(year ListedCoID) vce(r)
est store M1
*** X -> M
reghdfe F1_subsidy_adj did $controls if sample_low==1, absorb(year ListedCoID) vce(r)
est store M2
*** add mediator
reghdfe F2_f_cite_science_num_w did F1_subsidy_adj whether_pat $controls if sample_low==1, absorb(year ListedCoID) vce(r)
est store M3
	

******************************** High reliance on US tech **********************
*** X -> Y
reghdfe F2_f_cite_science_num_w did whether_pat $controls if sample_high==1, absorb(year ListedCoID) vce(r)
est store M4
*** X -> M
reghdfe F1_subsidy_adj did $controls if sample_high==1, absorb(year ListedCoID) vce(r)
est store M5
*** add mediator
reghdfe F2_f_cite_science_num_w did F1_subsidy_adj whether_pat $controls if sample_high==1, absorb(year ListedCoID) vce(r)
est store M6


esttab M1 M2 M3 M4 M5 M6 using ${table_output}main_listed_me_gov_relianceUS.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
	mgroups("Low reliance on US tech" "High reliance on US tech", pattern(1 0 0 1 0 0)) ///
	drop(whether_pat) nonotes


