

use ${stata_output}DID_allfirm-level.dta, clear

*** merge firm_name
merge m:1 firm_id using ${stata_output}firm_id_fapp_mapping.dta
drop if _merge==2
drop _merge

*** merge US adver export info
merge m:1 fapp using ${stata_output}exp_usadver_merge.dta

replace f_usadver_dummy=0 if _merge==1
replace f_usadver=0 if _merge==1
replace f_usadver_value=0 if _merge==1

replace f_usadver_criarea_dummy=0 if _merge==1
replace f_usadver_criarea=0 if _merge==1
replace f_usadver_value_criarea=0 if _merge==1

drop if _merge==2
drop _merge firm_name


order firm_id year did entity_list list_year dif_year ///
f_usadver_dummy f_usadver f_usadver_value ///
f_usadver_criarea_dummy f_usadver_criarea f_usadver_value_criarea

gen ratio_criarea = f_usadver_value_criarea/f_usadver_value


************************************************************************
* Construct candidate instrumental variables
************************************************************************
gen post_trump = year > 2017

gen export_iv = f_usadver_value/100000000 * post_trump


************************************************************************
* DID analysis (Sanctioned Firms × Post-Trump)
************************************************************************
gen did_new = entity_list * post_trump
	
reghdfe f_cite_science_num_w did_new whether_pat, absorb(firm_id year) vce(r)
est store M0

************************************************************************
* IV: Adversary-State Export Value
************************************************************************
reghdfe did_new export_iv whether_pat, absorb(firm_id year) vce(r) 
est store M1

ivreghdfe f_cite_science_num_w whether_pat (did_new = export_iv), absorb(firm_id year) vce(robust) first
est store M2


************************************************************************
* Magnitude of first-stage effect:
* One SD increase in pre-period adversary-state export exposure
************************************************************************

* First-stage regression
reghdfe did_new export_iv whether_pat, absorb(firm_id year) vce(r)
est store M1

* Save first-stage coefficient
local pi = _b[export_iv]

* Save first-stage estimation sample
gen sample_m1 = e(sample)

* Construct raw pre-period adversary export exposure
* This must use the same unit as export_iv, but WITHOUT multiplying by post_trump
gen adv_export_pre = f_usadver_value / 100000000

* Calculate firm-level SD of pre-period adversary export exposure
* Important: de-duplicate firm-year panel to firm level
preserve
    keep if sample_m1 == 1
    keep firm_id adv_export_pre
    duplicates drop firm_id, force

    sum adv_export_pre
    local sd_adv = r(sd)
restore

* Effect of one SD increase in adversary export exposure
local effect_prob = `pi' * `sd_adv'
local effect_pp   = `effect_prob' * 100

* Baseline probability: full sample mean of did_new
sum did_new if sample_m1 == 1
local mean_full = r(mean)

* Baseline probability: post-Trump sample mean of did_new
sum did_new if sample_m1 == 1 & post_trump == 1
local mean_post = r(mean)

* Relative percentage increases
local pct_full = (`effect_prob' / `mean_full') * 100
local pct_post = (`effect_prob' / `mean_post') * 100

display "First-stage coefficient = " `pi'
display "Firm-level SD of pre-period adversary export exposure = " `sd_adv'
display "Effect in probability = " `effect_prob'
display "Effect in percentage points = " `effect_pp'
display "Relative to full-sample mean of did_new (%) = " `pct_full'
display "Relative to post-Trump mean of did_new (%) = " `pct_post'



esttab M0 M1 M2 using ${table_output}IV_USadver_export.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ///
	b(%20.3f) se(%7.3f) r2(%9.3f) drop(whether_pat) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("DID" "IV: First stage " "IV: 2SLS") ///
	nonotes