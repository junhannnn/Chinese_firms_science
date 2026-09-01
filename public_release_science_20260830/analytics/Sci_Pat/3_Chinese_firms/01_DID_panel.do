

********************************************************************************
************************* summary statistics ***********************************
********************************************************************************

* Load the main firm-year dataset
use ${stata_output}DID_allfirm-level.dta, clear

* Define variables to include in summary tables
global summary_statistics ///
    f_cite_science_num f_cite_cn_sci_num f_cite_foreign_sci_num f_cite_us_sci_num f_cite_nonus_foreign_sci_num /// DV
    did whether_pat /// IV and moderator
    state_owned before_patent before_sci_patent // others

* Table 1: Variable definitions & summary statistics (saved to a new .doc; later tables append)
asdoc tabstat $summary_statistics, ///
    save(${table_output}main_summary_stats.doc) replace ///
    stat(N mean sd min max)

* Table 2: Correlation matrix (append to the same Word file)
asdoc cor $summary_statistics, ///
    save(${table_output}main_summary_stats.doc) append

* Firm-year level counts by entity_list
tab entity_list
asdoc tab entity_list, ///
    save(${table_output}main_summary_stats.doc) append ///
    title(Firm-year level)

* Collapse to firm level and report counts by entity_list
keep firm_id entity_list
duplicates drop
tab entity_list
asdoc tab entity_list, ///
    save(${table_output}main_summary_stats.doc) append ///
    title(Firm level)



********************************************************************************
********************* pretreatment means (treated group) ***********************
********************************************************************************

* Compute pretreatment mean in the baseline sample:
* treated firms (entity_list==1) before their listing year
use ${stata_output}DID_allfirm-level.dta, clear
keep if entity_list==1 & year<list_year
quietly summarize f_cite_science_num_w
scalar m_base = r(mean)

* Compute pretreatment mean in the CEM-matched sample:
* matched observations among treated firms before listing
use ${stata_output}DID_allfirm-level_cem.dta, clear
keep if cem_matched==1
keep if entity_list==1 & year<list_year
quietly summarize f_cite_science_num_w
scalar m_cem = r(mean)

* Build a tiny 2-row dataset and append the table to the same Word file
clear
input str64 group double mean_f_cite_science_num_w
"pre-treatment mean (all sample)" .
"pre-treatment mean (after CEM)"      .
end
replace mean_f_cite_science_num_w = m_base in 1
replace mean_f_cite_science_num_w = m_cem in 2

* Sanity check: the path must match earlier asdoc calls exactly
di as txt "Writing to: " "${table_output}summary_stats_main.doc"

asdoc list group mean_f_cite_science_num_w, ///
    save(${table_output}main_summary_stats.doc) append ///
    title(Pre-treatment means of f_cite_science_num_w) ///
    dec(3)

********************************************************************************
************************* Staggered DID analysis: cite science *****************
********************************************************************************
	
use ${stata_output}DID_allfirm-level.dta, clear

* OLS
reghdfe f_cite_science_num_w did whether_pat, absorb(firm_id year) vce(r) 
est store M1

* ln and OLS
reghdfe ln_f_cite_science_num did whether_pat, absorb(firm_id year) vce(r)
est store M2

* Poisson
ppmlhdfe f_cite_science_num did whether_pat, absorb(firm_id year) vce(r)
est store M3


********************************* regression ***********************************

use ${stata_output}DID_allfirm-level_cem.dta, clear

keep if cem_matched==1

* OLS
reghdfe f_cite_science_num_w did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r)
est store M4

* ln and OLS
reghdfe ln_f_cite_science_num did whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r)
est store M5

* Poisson
ppmlhdfe f_cite_science_num did whether_pat [pweight=cem_weights], absorb(firm_id year) vce(r)
est store M6


esttab M1 M2 M3 M4 M5 M6 using ${table_output}main_did.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
	nonotes


********************************************************************************			 
********************************** Other ***************************************
********************************************************************************


******************************* The quality of matching ************************

use ${stata_output}DID_allfirm-level_cem.dta, clear

* before matching
mean log_before_patent log_before_sci_patent state_owned industry_id province, over(entity_list)

* after matching
mean log_before_patent log_before_sci_patent state_owned industry_id province [pweight=cem_weights], over(entity_list)


regress before_patent entity_list [pweight=cem_weights], robust //not significant
regress before_sci_patent entity_list [pweight=cem_weights], robust //not significant
regress state_owned entity_list [pweight=cem_weights], robust //not significant
regress industry_id entity_list [pweight=cem_weights], robust //not significant
regress province entity_list [pweight=cem_weights], robust //not significant



*---------------------------------------------------------------------------
* Balance table: pre- vs post-matching (two groups)
* Fix: use robust label mapping so "Variable" shows full names, not split words
*---------------------------------------------------------------------------

clear all
set more off

*---------------------------------------------------------------------------
* Inputs (adjust paths/macros as needed)
*---------------------------------------------------------------------------
local prefile  "${stata_output}DID_allfirm-level_cem.dta"
local postfile "${stata_output}DID_allfirm-level_cem.dta"

* Variables to report (order matters)
local vars log_before_patent log_before_sci_patent state_owned industry_id province

* Pretty display names (one macro per variable, same order as `vars`)
local label1 "Log (number of patents filed before listing+1)"
local label2 "Log (Prior scientific foundations+1)"
local label3 "Firm ownership (SOEs=1, non-SOEs=0)"
local label4 "Industry id"
local label5 "Province id"

*---------------------------------------------------------------------------
* (Optional helper; not strictly needed but kept for completeness)
*---------------------------------------------------------------------------
capture program drop _post_mean_two_groups
program define _post_mean_two_groups, rclass
    syntax, Varname(name) Varlab(string) Handle(name) Stage(string)
    tempname T
    matrix `T' = r(table)
    // Control (entity_list==0)
    post ``Handle'' ("`Varlab'") ("Control") ///
        ( `T'[1,1] ) ( `T'[2,1] ) ( `T'[5,1] ) ( `T'[6,1] ) ("`Stage'")
    // Treatment (entity_list==1)
    post ``Handle'' ("`Varlab'") ("Treatment") ///
        ( `T'[1,2] ) ( `T'[2,2] ) ( `T'[5,2] ) ( `T'[6,2] ) ("`Stage'")
end

*---------------------------------------------------------------------------
* 1) PRE-MATCHING: unweighted means by entity_list
*---------------------------------------------------------------------------
use `prefile', clear

tempname preh
tempfile pretmp
postfile `preh' str80 Variable str10 Group ///
    double pre_mean pre_se pre_ll pre_ul ///
    using `pretmp', replace

local i = 0
foreach v of local vars {
    local ++i
    local vlab `label`i''        // <-- robust label mapping
    quietly mean `v', over(entity_list)
    tempname T
    matrix `T' = r(table)
    // Control
    post `preh' ("`vlab'") ("Control") ///
        (`T'[1,1]) (`T'[2,1]) (`T'[5,1]) (`T'[6,1])
    // Treatment
    post `preh' ("`vlab'") ("Treatment") ///
        (`T'[1,2]) (`T'[2,2]) (`T'[5,2]) (`T'[6,2])
}
postclose `preh'

use `pretmp', clear
tempfile predata
save `predata', replace

*---------------------------------------------------------------------------
* 2) POST-MATCHING: weighted means by entity_list (pweights = cem_weights)
*---------------------------------------------------------------------------
use `postfile', clear

tempname posth
tempfile posttmp
postfile `posth' str80 Variable str10 Group ///
    double post_mean post_se post_ll post_ul ///
    using `posttmp', replace

local i = 0
foreach v of local vars {
    local ++i
    local vlab `label`i''        // <-- robust label mapping
    quietly mean `v' [pweight=cem_weights], over(entity_list)
    tempname T
    matrix `T' = r(table)
    // Control
    post `posth' ("`vlab'") ("Control") ///
        (`T'[1,1]) (`T'[2,1]) (`T'[5,1]) (`T'[6,1])
    // Treatment
    post `posth' ("`vlab'") ("Treatment") ///
        (`T'[1,2]) (`T'[2,2]) (`T'[5,2]) (`T'[6,2])
}
postclose `posth'

use `posttmp', clear
tempfile postdata
save `postdata', replace

*---------------------------------------------------------------------------
* 3) Merge PRE and POST into final table (one row per Variable × Group)
*---------------------------------------------------------------------------
use `predata', clear
merge 1:1 Variable Group using `postdata', nogen

order Variable Group pre_mean pre_se pre_ll pre_ul post_mean post_se post_ll post_ul
sort Variable Group

* Sort by label order
gen order = .
replace order = 1 if Variable == "`label1'"
replace order = 2 if Variable == "`label2'"
replace order = 3 if Variable == "`label3'"
replace order = 4 if Variable == "`label4'"
replace order = 5 if Variable == "`label5'"
sort order Group
drop order

*---------------------------------------------------------------------------
* 4) Format and export (asdoc required)
*---------------------------------------------------------------------------
preserve
    * Create pretty CI strings like [ll, uu] with 3 decimals
    gen str20 pre_ci  = "[" + string(pre_ll,  "%9.3f") + ", " + string(pre_ul,  "%9.3f") + "]"
    gen str20 post_ci = "[" + string(post_ll, "%9.3f") + ", " + string(post_ul, "%9.3f") + "]"

    * Display columns (matches your example layout, with fixed Variable labels)
    asdoc list ///
        Variable Group ///
        pre_mean pre_se pre_ci ///
        post_mean post_se post_ci, ///
        save(${table_output}main_cem_balance.doc) replace ///
        title(Balance: Pre- vs Post-Matching) ///
        dec(3)
restore
