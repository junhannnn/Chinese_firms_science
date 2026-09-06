/*******************************************************************************
Project: Science-linked patents—Chinese-firm analysis
Script:  01_DID_panel.do

Purpose:
  Produce sample summaries, pre-treatment means, baseline difference-in-
  differences (DID) estimates, and coarsened-exact-matching (CEM) balance
  diagnostics for the Chinese-firm panel.

Main inputs:
  - ${stata_output}DID_allfirm-level.dta (full firm-year panel)
  - ${stata_output}DID_allfirm-level_cem.dta (CEM panel and weights)

Main outputs:
  - ${table_output}main_summary_stats.doc
  - ${table_output}main_did.rtf
  - ${table_output}main_cem_balance.doc

Required setup:
  The master runner defines stata_output and table_output before calling this
  file. The script also requires the community-contributed commands asdoc,
  reghdfe, ppmlhdfe, and esttab.
*******************************************************************************/

* ==============================================================================
* 1. Produce descriptive statistics and sample counts
* ==============================================================================

* Load the full firm-year analysis panel.
use ${stata_output}DID_allfirm-level.dta, clear

* Define outcomes, treatment measures, and baseline firm characteristics.
global summary_statistics ///
    f_cite_science_num f_cite_cn_sci_num f_cite_foreign_sci_num f_cite_us_sci_num f_cite_nonus_foreign_sci_num /// Outcomes
    did whether_pat /// Treatment and patent-activity indicators
    state_owned before_patent before_sci_patent // Baseline characteristics

* Create the summary-statistics document; subsequent panels append to this file.
asdoc tabstat $summary_statistics, ///
    save(${table_output}main_summary_stats.doc) replace ///
    stat(N mean sd min max)

* Append the correlation matrix.
asdoc cor $summary_statistics, ///
    save(${table_output}main_summary_stats.doc) append

* Append treatment-group counts at the firm-year level.
tab entity_list
asdoc tab entity_list, ///
    save(${table_output}main_summary_stats.doc) append ///
    title(Firm-year level)

* Reduce to one observation per firm and append firm-level treatment counts.
keep firm_id entity_list
duplicates drop
tab entity_list
asdoc tab entity_list, ///
    save(${table_output}main_summary_stats.doc) append ///
    title(Firm level)

* ==============================================================================
* 2. Calculate pre-treatment means for treated firms
* ==============================================================================

* Calculate the full-sample mean before each treated firm's listing year.
use ${stata_output}DID_allfirm-level.dta, clear
keep if entity_list==1 & year<list_year
quietly summarize f_cite_science_num_w
scalar m_base = r(mean)

* Calculate the corresponding mean among CEM-matched treated observations.
use ${stata_output}DID_allfirm-level_cem.dta, clear
keep if cem_matched==1
keep if entity_list==1 & year<list_year
quietly summarize f_cite_science_num_w
scalar m_cem = r(mean)

* Build a two-row reporting dataset containing the stored means.
clear
input str64 group double mean_f_cite_science_num_w
"pre-treatment mean (all sample)" .
"pre-treatment mean (after CEM)"      .
end
replace mean_f_cite_science_num_w = m_base in 1
replace mean_f_cite_science_num_w = m_cem in 2

* Print a diagnostic path; the asdoc command below appends to main_summary_stats.doc.
di as txt "Writing to: " "${table_output}summary_stats_main.doc"

asdoc list group mean_f_cite_science_num_w, ///
    save(${table_output}main_summary_stats.doc) append ///
    title(Pre-treatment means of f_cite_science_num_w) ///
    dec(3)

* ==============================================================================
* 3. Estimate baseline DID models for the full sample
* ==============================================================================

use ${stata_output}DID_allfirm-level.dta, clear

* Model 1: linear specification for winsorized science-linked patent counts.
reghdfe f_cite_science_num_w did whether_pat, absorb(firm_id year) vce(r) 
est store M1

* Model 2: linear specification for log-transformed counts.
reghdfe ln_f_cite_science_num did whether_pat, absorb(firm_id year) vce(r)
est store M2

* Model 3: Poisson specification for counts.
ppmlhdfe f_cite_science_num did whether_pat, absorb(firm_id year) vce(r)
est store M3

* ==============================================================================
* 4. Estimate baseline DID models for the CEM sample
* ==============================================================================

use ${stata_output}DID_allfirm-level_cem.dta, clear

keep if cem_matched==1

* Model 4: CEM-weighted linear specification for winsorized counts.
reghdfe f_cite_science_num_w did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r)
est store M4

* Model 5: CEM-weighted linear specification for log-transformed counts.
reghdfe ln_f_cite_science_num did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r)
est store M5

* Model 6: CEM-weighted Poisson specification for counts.
ppmlhdfe f_cite_science_num did whether_pat [pweight=cem_weights], absorb(firm_id year) vce(r)
est store M6

* Export full-sample and matched-sample estimates in one table.
esttab M1 M2 M3 M4 M5 M6 using ${table_output}main_did.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ///
	b(%20.3f) se(%7.3f) r2(%9.3f) drop("whether_pat") ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
	nonotes

* ==============================================================================
* 5. Assess covariate balance before and after matching
* ==============================================================================

use ${stata_output}DID_allfirm-level_cem.dta, clear

* Compare unweighted covariate means before matching.
mean log_before_patent log_before_sci_patent state_owned industry_id province, over(entity_list)

* Compare CEM-weighted covariate means after matching.
mean log_before_patent log_before_sci_patent state_owned industry_id province [pweight=cem_weights], over(entity_list)

* Test CEM-weighted differences between treated and control observations.
regress before_patent entity_list [pweight=cem_weights], robust // Patent-history balance.
regress before_sci_patent entity_list [pweight=cem_weights], robust // Science-history balance.
regress state_owned entity_list [pweight=cem_weights], robust // Ownership balance.
regress industry_id entity_list [pweight=cem_weights], robust // Industry balance.
regress province entity_list [pweight=cem_weights], robust // Province balance.

* ==============================================================================
* 6. Construct and export the detailed CEM balance table
* ==============================================================================

clear all
set more off

* Use the same CEM panel to calculate unweighted and weighted statistics.
local prefile  "${stata_output}DID_allfirm-level_cem.dta"
local postfile "${stata_output}DID_allfirm-level_cem.dta"

* Define the covariates and their reporting order.
local vars log_before_patent log_before_sci_patent state_owned industry_id province

* Assign one display label to each covariate in the same order.
local label1 "Log (number of patents filed before listing+1)"
local label2 "Log (Prior scientific foundations+1)"
local label3 "Firm ownership (SOEs=1, non-SOEs=0)"
local label4 "Industry id"
local label5 "Province id"

* Define a reusable helper for posting two-group mean statistics.
capture program drop _post_mean_two_groups
program define _post_mean_two_groups, rclass
    syntax, Varname(name) Varlab(string) Handle(name) Stage(string)
    tempname T
    matrix `T' = r(table)
    // Post statistics for control observations (entity_list==0).
    post ``Handle'' ("`Varlab'") ("Control") ///
        ( `T'[1,1] ) ( `T'[2,1] ) ( `T'[5,1] ) ( `T'[6,1] ) ("`Stage'")
    // Post statistics for treated observations (entity_list==1).
    post ``Handle'' ("`Varlab'") ("Treatment") ///
        ( `T'[1,2] ) ( `T'[2,2] ) ( `T'[5,2] ) ( `T'[6,2] ) ("`Stage'")
end

* Calculate unweighted pre-matching means and confidence intervals by group.
use `prefile', clear

tempname preh
tempfile pretmp
postfile `preh' str80 Variable str10 Group ///
    double pre_mean pre_se pre_ll pre_ul ///
    using `pretmp', replace

local i = 0
foreach v of local vars {
    local ++i
    local vlab `label`i''        // Map each covariate to its display label.
    quietly mean `v', over(entity_list)
    tempname T
    matrix `T' = r(table)
    // Post control-group statistics.
    post `preh' ("`vlab'") ("Control") ///
        (`T'[1,1]) (`T'[2,1]) (`T'[5,1]) (`T'[6,1])
    // Post treatment-group statistics.
    post `preh' ("`vlab'") ("Treatment") ///
        (`T'[1,2]) (`T'[2,2]) (`T'[5,2]) (`T'[6,2])
}
postclose `preh'

use `pretmp', clear
tempfile predata
save `predata', replace

* Calculate CEM-weighted post-matching statistics by group.
use `postfile', clear

tempname posth
tempfile posttmp
postfile `posth' str80 Variable str10 Group ///
    double post_mean post_se post_ll post_ul ///
    using `posttmp', replace

local i = 0
foreach v of local vars {
    local ++i
    local vlab `label`i''        // Map each covariate to its display label.
    quietly mean `v' [pweight=cem_weights], over(entity_list)
    tempname T
    matrix `T' = r(table)
    // Post control-group statistics.
    post `posth' ("`vlab'") ("Control") ///
        (`T'[1,1]) (`T'[2,1]) (`T'[5,1]) (`T'[6,1])
    // Post treatment-group statistics.
    post `posth' ("`vlab'") ("Treatment") ///
        (`T'[1,2]) (`T'[2,2]) (`T'[5,2]) (`T'[6,2])
}
postclose `posth'

use `posttmp', clear
tempfile postdata
save `postdata', replace

* Merge pre- and post-matching statistics by covariate and treatment group.
use `predata', clear
merge 1:1 Variable Group using `postdata', nogen

order Variable Group pre_mean pre_se pre_ll pre_ul post_mean post_se post_ll post_ul
sort Variable Group

* Restore the covariate order defined above.
gen order = .
replace order = 1 if Variable == "`label1'"
replace order = 2 if Variable == "`label2'"
replace order = 3 if Variable == "`label3'"
replace order = 4 if Variable == "`label4'"
replace order = 5 if Variable == "`label5'"
sort order Group
drop order

* Format confidence intervals and export the final balance table.
preserve
    * Format confidence intervals as bracketed strings with three decimals.
    gen str20 pre_ci  = "[" + string(pre_ll,  "%9.3f") + ", " + string(pre_ul,  "%9.3f") + "]"
    gen str20 post_ci = "[" + string(post_ll, "%9.3f") + ", " + string(post_ul, "%9.3f") + "]"

    * Export selected pre- and post-matching columns with descriptive labels.
    asdoc list ///
        Variable Group ///
        pre_mean pre_se pre_ci ///
        post_mean post_se post_ci, ///
        save(${table_output}main_cem_balance.doc) replace ///
        title(Balance: Pre- vs Post-Matching) ///
        dec(3)
restore
