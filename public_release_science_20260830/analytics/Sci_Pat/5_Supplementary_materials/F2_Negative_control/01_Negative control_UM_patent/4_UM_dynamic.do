********************************************************************************
* Public-release polish: formatting/comments adjusted only; original logic unchanged.
********************************************************************************

/*******************************************************************************
Project: Reviewer Robustness — Negative Control (Utility Model Patents)
Script: 4_UM_dynamic.do

Purpose
  - Run placebo event-study specifications for utility-model outcomes.
  - Generate four event-study graphs (full/matched; all/listed firms).
  - Extract event-time coefficients into a table dataset and plot a combined
    comparison figure.

Inputs (from ${stata_output})
  - DID_allfirm_UM.dta
  - DID_allfirm_UM_cem.dta
  - DID_listedfirm_UM.dta

Outputs
  - Graph files under ${figure_output} (e.g., dynamic1.gph to dynamic4.gph)
  - ${table_output}ROS_event_table_UM.dta

Notes
  - Requires `eventdd` and related graph-edit commands available in Stata.
*******************************************************************************/

* Paths are managed centrally by `5_Supplementary_materials/00_run_all.do`.
* Required globals (e.g., `${stata_output}`, `${figure_output}`,
* `${table_output}`) should be defined before calling this script.


********************************************************************************
************************* A. All Firms (Full Sample) ***************************
********************************************************************************

use ${stata_output}DID_allfirm_UM.dta, clear

* Graph A: event study for all firms (full sample)

eventdd UM_num_w, timevar(dif_year) ///
    method(hdfe, absorb(firm_id year)) ///
    baseline(0) vce(r) level(95) ///
    graph_op(ytitle("# of Chinese utility model patents") ///
             xtitle("Event Year") ///
             title("(A) Chinese firms (full sample)", size(medium)) ///
             xscale(range(-3 3)) ///
             legend(off) ///
             graphregion(color(white)) ///
             bgcolor(white) ///
             scheme(journal))
gr_edit .xaxis1.reset_rule -3 3 1 , tickset(major) ruletype(range) 
gr_edit .plotregion1._xylines[1].style.editstyle linestyle(pattern(dash)) editcopy
gr_edit .plotregion1._xylines[1].style.editstyle linestyle(width(thin)) editcopy
gr_edit .plotregion1._xylines[1].DragBy 0 1

est store M1

graph save ${figure_output}dynamic1.gph, replace



use ${stata_output}DID_allfirm_UM_cem.dta, clear

* Graph B: event study for all firms (matched sample)

keep if cem_matched==1

eventdd UM_num_w, timevar(dif_year) ///
    method(hdfe, absorb(firm_id year)) ///
    baseline(0) vce(r) level(95) ///
    graph_op(ytitle("# of Chinese utility model patents") ///
             xtitle("Event Year") ///
             title("(B) Chinese firms (matched sample)", size(medium)) ///
             xscale(range(-3 3)) ///
             legend(off) ///
             graphregion(color(white)) ///
             bgcolor(white) ///
             scheme(journal))
gr_edit .xaxis1.reset_rule -3 3 1 , tickset(major) ruletype(range) 
gr_edit .plotregion1._xylines[1].style.editstyle linestyle(pattern(dash)) editcopy
gr_edit .plotregion1._xylines[1].style.editstyle linestyle(width(thin)) editcopy
gr_edit .plotregion1._xylines[1].DragBy 0 1

est store M2

graph save ${figure_output}dynamic2.gph, replace


********************************************************************************
************************ B. Public Listed Firms ********************************
********************************************************************************

use ${stata_output}DID_listedfirm_UM.dta, clear

* Graph C: event study for listed firms (full sample)

eventdd UM_num_w, timevar(dif_year) ///
    method(hdfe, absorb(firm_id year)) ///
    baseline(0) vce(r) level(95) ///
    graph_op(ytitle("# of Chinese utility model patents") ///
             xtitle("Event Year") ///
             title("(C) Chinese listed firms (full sample)", size(medium)) ///
             xscale(range(-3 3)) ///
             legend(off) ///
             graphregion(color(white)) ///
             bgcolor(white) ///
             scheme(journal))
gr_edit .xaxis1.reset_rule -3 3 1 , tickset(major) ruletype(range) 
gr_edit .plotregion1._xylines[1].style.editstyle linestyle(pattern(dash)) editcopy
gr_edit .plotregion1._xylines[1].style.editstyle linestyle(width(thin)) editcopy
gr_edit .plotregion1._xylines[1].DragBy 0 1

est store M3

graph save ${figure_output}dynamic3.gph, replace



use ${stata_output}DID_listedfirm_UM.dta, clear

* Graph D: event study for listed firms (matched sample)
gen major_indus=substr(IndustryCode,1,1)
cem firm_age firm_size major_indus PROVINCE RDInvest, treatment(entity_list)

keep if cem_matched==1

eventdd UM_num_w [aweight=cem_weights], timevar(dif_year) ///
    method(hdfe, absorb(firm_id year)) ///
    baseline(0) vce(r) level(95) ///
    graph_op(ytitle("# of Chinese utility model patents") ///
             xtitle("Event Year") ///
             title("(D) Chinese listed firms (matched sample)", size(medium)) ///
             xscale(range(-3 3)) ///
             legend(off) ///
             graphregion(color(white)) ///
             bgcolor(white) ///
             scheme(journal))
gr_edit .xaxis1.reset_rule -3 3 1 , tickset(major) ruletype(range) 
gr_edit .plotregion1._xylines[1].style.editstyle linestyle(pattern(dash)) editcopy
gr_edit .plotregion1._xylines[1].style.editstyle linestyle(width(thin)) editcopy
gr_edit .plotregion1._xylines[1].DragBy 0 1

est store M4

graph save ${figure_output}dynamic4.gph, replace


********************************************************************************
********************** C. Export Event-Study Coefficients **********************
********************************************************************************

* Extract event-time coefficients from the four stored event-study models
local models M1 M2 M3 M4
local groups A B C D

tempname posth
tempfile  out
postfile `posth' str1 group x y ci_low ci_high using `out', replace

* z-value for 95% confidence interval
local z = invnormal(0.975) // 90% CI: invnormal(0.95); 95% CI: invnormal(0.975)

local k = 0
foreach m of local models {
    local ++k
    local g : word `k' of `groups'
    estimates restore `m'

    * Get the list of coefficient names
    local names : colnames e(b)

    * Loop over all coefficient names and extract those matching lead/lag patterns
    foreach nm of local names {
        * Convert the name to lowercase for easier matching
        local nm_low = lower("`nm'")

        local matched = 0
        local x = .

        * Match leadK (K>0)
        quietly if regexm("`nm_low'","lead([0-9]+)") {
            local K = real(regexs(1))
            local x = -`K'
            local matched = 1
        }

        * Match lagK (K>0)
        quietly if (`matched'==0) & regexm("`nm_low'","lag([0-9]+)") {
            local K = real(regexs(1))
            local x = `K'
            local matched = 1
        }


        if (`matched') {
            matrix bmat = e(b)
            matrix Vmat = e(V)

            local col = colnumb(bmat, "`nm'")
            if (`col' < .) {
            scalar b  = bmat[1, `col']
            scalar se = sqrt(Vmat[`col', `col'])
            scalar lo = b - `z'*se
            scalar hi = b + `z'*se
            post `posth' ("`g'") (`x') (b) (lo) (hi)
            }
        }

    }

    * Add the baseline point x=0 (relative base = 0)
    post `posth' ("`g'") (0) (0) (0) (0)
}
postclose `posth'

use `out', clear
order group x y ci_low ci_high
sort group x

save ${table_output}ROS_event_table_UM.dta, replace


********************************************************************************
********************** D. Plot Combined Dynamic Effects ************************
********************************************************************************

********************** D1. Two-Axis Comparison Figure **************************

use ${table_output}ROS_event_table_UM.dta, clear

* Adjust x position slightly for spacing by group
gen double x_plot = x + ///
        cond(group=="A", -0.24, ///
        cond(group=="B", -0.08, ///
        cond(group=="C",  0.08, ///
                          0.24)))   // D

* Define colors
local colA green*1
local colB ebblue*1.5
local colC purple*1.5
local colD red*1.5

* Define markers
local markA circle
local markB square
local markC triangle
local markD diamond


twoway                                                      ///
    /* Group A — left Y-axis */                             ///
    (rcap  ci_low ci_high x_plot if group=="A", lcolor(`colA') yaxis(1)) ///
    (scatter y x_plot if group=="A", mcolor(`colA') msymbol(`markA') msize(small) yaxis(1)) ///
    /* Group B — left Y-axis */                             ///
    (rcap  ci_low ci_high x_plot if group=="B", lcolor(`colB') yaxis(1)) ///
    (scatter y x_plot if group=="B", mcolor(`colB') msymbol(`markB') msize(small) yaxis(1)) ///
    /* Group C — right Y-axis */                            ///
    (rcap  ci_low ci_high x_plot if group=="C", lcolor(`colC') yaxis(2)) ///
    (scatter y x_plot if group=="C", mcolor(`colC') msymbol(`markC') msize(small) yaxis(2)) ///
    /* Group D — right Y-axis */                            ///
    (rcap  ci_low ci_high x_plot if group=="D", lcolor(`colD') yaxis(2)) ///
    (scatter y x_plot if group=="D", mcolor(`colD') msymbol(`markD') msize(small) yaxis(2)) ///
    ,                                                       ///
    /* Y-axis scales and labels */                          ///
    yscale(range(-30 30) axis(1)) ylabel(-30(15)30, axis(1) labsize(medsmall)) ///
    yscale(range(-60 60) axis(2)) ylabel(-60(30)60, axis(2) labsize(medsmall)) ///
    /* Axis titles and X-axis */                            ///
    ytitle("{bf:Chinese Firms' Utility Model Patents}", size(medium) axis(1)) ///
    ytitle("{bf:Chinese Listed Firms' Utility Model Patents}", size(medium) axis(2)) ///
    xtitle("{bf:Sanction Year}",  size(medium)) xlabel(-3(1)3, labsize(medium))     ///
    /* Legend configuration */                              ///
    legend(order(2 "Chinese firms, full sample (left axis)" ///
                 4 "Chinese firms, matched sample (left axis)" ///
                 6 "Chinese listed firms, full sample (right axis)" ///
                 8 "Chinese listed firms, matched sample (right axis)") ///
           col(1) ring(0) position(11) rowgap(*1.2) size(medsmall) region(margin(zero))) ///   
    /* Reference lines */                                   ///
    yline(0, lpattern(dash) lcolor(gs11))                   ///
    xline(0, lpattern(dash) lcolor(gs11))                   ///
    /* Graph layout */                                      ///
    aspectratio(0.8) graphregion(margin(vsmall))

/*
    /* Legend configuration */                              ///
    legend(off) ///
*/
    
graph save ${figure_output}placebo_UM_patent.gph, replace



graph combine ${figure_output}dynamic1.gph ${figure_output}dynamic2.gph ///
${figure_output}dynamic3.gph ${figure_output}dynamic4.gph 


erase ${figure_output}dynamic1.gph
erase ${figure_output}dynamic2.gph
erase ${figure_output}dynamic3.gph
erase ${figure_output}dynamic4.gph
erase ${table_output}ROS_event_table_UM.dta
