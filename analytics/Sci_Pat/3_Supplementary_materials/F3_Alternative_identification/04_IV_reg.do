/*******************************************************************************
Project: Science-linked patents—supplementary alternative identification
Script:  4_IV_reg.do

Purpose:
  Estimate an instrumental-variable specification in which post-2017 exposure
  to exports to U.S. adversary states instruments for the alternative sanction
  treatment. Report the baseline DID, first-stage, and two-stage least-squares
  estimates and summarize the magnitude of the first-stage relationship.

Main inputs (from ${stata_output}):
  - DID_allfirm-level.dta
  - firm_id_fapp_mapping.dta
  - exp_usadver_merge.dta

Main output (under ${table_output}):
  - IV_USadver_export.rtf: baseline DID, first-stage, and 2SLS estimates

Notes:
  Run through 3_Supplementary_materials/00_run_all.do so the shared path globals
  are available.
*******************************************************************************/

* ==============================================================================
* 1. Assemble the firm-year IV analysis panel
* ==============================================================================

use ${stata_output}DID_allfirm-level.dta, clear

* Attach the patent-applicant name associated with each firm identifier.
merge m:1 firm_id using ${stata_output}firm_id_fapp_mapping.dta
drop if _merge==2
drop _merge

* Attach adversary-state export exposure by patent-applicant name.
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
* ==============================================================================
* 2. Construct the alternative treatment and instrumental variable
* ==============================================================================
gen post_trump = year > 2017

gen export_iv = f_usadver_value/100000000 * post_trump
gen did_new = entity_list * post_trump

* ==============================================================================
* 3. Estimate the baseline DID, first stage, and 2SLS models
* ==============================================================================

reghdfe f_cite_science_num_w did_new whether_pat, absorb(firm_id year) vce(r)
est store M0

* Estimate the first stage using adversary-state export exposure.
reghdfe did_new export_iv whether_pat, absorb(firm_id year) vce(r) 
est store M1

* Estimate the second stage using the instrumented treatment.
ivreghdfe f_cite_science_num_w whether_pat (did_new = export_iv), absorb(firm_id year) vce(robust) first
est store M2

* ==============================================================================
* 4. Scale the first-stage estimate to one standard deviation of exposure
* ==============================================================================

* Re-estimate the first stage and retain its coefficient and estimation sample.
reghdfe did_new export_iv whether_pat, absorb(firm_id year) vce(r)
est store M1

local pi = _b[export_iv]

gen sample_m1 = e(sample)

* Express pre-period adversary-state export exposure in the instrument's units.
gen adv_export_pre = f_usadver_value / 100000000

* Calculate its firm-level standard deviation after removing repeated firm-years.
preserve
    keep if sample_m1 == 1
    keep firm_id adv_export_pre
    duplicates drop firm_id, force

    sum adv_export_pre
    local sd_adv = r(sd)
restore

* Convert a one-standard-deviation exposure increase to probability-point effects.
local effect_prob = `pi' * `sd_adv'
local effect_pp   = `effect_prob' * 100

* Calculate the treatment mean in the full first-stage estimation sample.
sum did_new if sample_m1 == 1
local mean_full = r(mean)

* Calculate the treatment mean for post-2017 observations in that sample.
sum did_new if sample_m1 == 1 & post_trump == 1
local mean_post = r(mean)

* Express the scaled effect relative to both treatment means.
local pct_full = (`effect_prob' / `mean_full') * 100
local pct_post = (`effect_prob' / `mean_post') * 100

display "First-stage coefficient = " `pi'
display "Firm-level SD of pre-period adversary export exposure = " `sd_adv'
display "Effect in probability = " `effect_prob'
display "Effect in percentage points = " `effect_pp'
display "Relative to full-sample mean of did_new (%) = " `pct_full'
display "Relative to post-Trump mean of did_new (%) = " `pct_post'
* ==============================================================================
* 5. Export the combined IV results table
* ==============================================================================

esttab M0 M1 M2 using ${table_output}IV_USadver_export.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ///
	b(%20.3f) se(%7.3f) r2(%9.3f) drop(whether_pat) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("DID" "IV: First stage " "IV: 2SLS") ///
	nonotes
