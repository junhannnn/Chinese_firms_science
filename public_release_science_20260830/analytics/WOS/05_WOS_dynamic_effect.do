/*******************************************************************************
Project: WOS Pipeline - Dynamic Event-Study Effects
Script: 05_WOS_dynamic_effect.do

Purpose
  - Estimate dynamic treatment effects for WOS outcomes using event-study DID.
  - Generate figures for full and matched samples (all firms and listed firms).
  - Build and export an event-study plotting table.

Inputs
  - `${stata_output}CN_WOS_DID.dta`
  - `${stata_output}CN_WOS_DID_cem.dta`
  - `${stata_output}CN_WOS_DID_listed.dta`

Outputs
  - `${figure_output}dynamic1.gph` to `${figure_output}dynamic4.gph`
  - `${table_output}WOS_event_table.dta`
  - `${figure_output}fig2f_WOS_dynamic.gph`

Instructions
  - Run after `02_WOS_DID.do` and `04_WOS_DID_listed.do`.
  - Keep the current event window (`-3` to `3`) consistent across panels.
*******************************************************************************/

* Path globals are defined centrally in `00_run_all.do`.


********************************************************************************
********************************* All firms ************************************
********************************************************************************

use ${stata_output}CN_WOS_DID.dta, clear

gen dif_year = year-list_year
drop if dif_year!=. & !inrange(dif_year, -3, 3)

eventdd pub_num_w, timevar(dif_year) ///
    method(hdfe, absorb(firm_id year)) ///
    baseline(0) vce(r) level(95) ///
    graph_op(ytitle("# of publications indexed by WOS") ///
             xtitle("Sanction Year") ///
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


*** CEM

use ${stata_output}CN_WOS_DID_cem.dta, clear

keep if cem_matched==1
gen dif_year = year-list_year
drop if dif_year!=. & !inrange(dif_year, -3, 3)

eventdd pub_num_w [aweight=cem_weights], timevar(dif_year) ///
    method(hdfe, absorb(firm_id year)) ///
    baseline(0) vce(r) level(95) ///
    graph_op(ytitle("# of publications indexed by WOS") ///
             xtitle("Sanction Year") ///
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
***************************** Public Listed firms ******************************
********************************************************************************

use ${stata_output}CN_WOS_DID_listed.dta, clear

gen dif_year = year-list_year
drop if dif_year!=. & !inrange(dif_year, -3, 3)

eventdd pub_num_w, timevar(dif_year) ///
    method(hdfe, absorb(firm_id year)) ///
    baseline(0) vce(r) level(95) ///
    graph_op(ytitle("# of publications indexed by WOS") ///
             xtitle("Sanction Year") ///
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


*** CEM

use ${stata_output}CN_WOS_DID_listed_cem.dta, clear

keep if cem_matched==1
gen dif_year = year-list_year
drop if dif_year!=. & !inrange(dif_year, -3, 3)

eventdd pub_num_w [aweight=cem_weights], timevar(dif_year) ///
    method(hdfe, absorb(firm_id year)) ///
    baseline(0) vce(r) level(95) ///
    graph_op(ytitle("# of publications indexed by WOS") ///
             xtitle("Sanction Year") ///
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



graph combine ${figure_output}dynamic1.gph ${figure_output}dynamic2.gph ///
${figure_output}dynamic3.gph ${figure_output}dynamic4.gph

erase ${figure_output}dynamic1.gph
erase ${figure_output}dynamic2.gph
erase ${figure_output}dynamic3.gph
erase ${figure_output}dynamic4.gph


********************************************************************************
********************************* To table *************************************
********************************************************************************

* Assume four models have been stored as M1 M2 M3 M4
local models M1 M2 M3 M4
local groups A B C D

tempname posth
tempfile  out
postfile `posth' str1 group x y ci_low ci_high using `out', replace
local z = invnormal(0.975)
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
            * Extract coefficient and standard error (using the actual variable name)
            capture scalar b  = _b[`nm']
            capture scalar se = _se[`nm']
            if (_rc==0) {
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

save ${stata_output}WOS_event_table.dta, replace


********************************************************************************
**************************** plot four dynamic effect **************************
********************************************************************************

******************************* two Y-axis *************************************

use ${stata_output}WOS_event_table.dta, clear

gen double x_plot = x + ///
        cond(group=="A", -0.24, ///
        cond(group=="B", -0.08, ///
        cond(group=="C",  0.08, ///
                          0.24)))   // D

local colA green*1
local colB ebblue*1.5
local colC purple*1.5
local colD red*1.5

local markA circle
local markB square
local markC triangle
local markD diamond


twoway                                                      ///
    /* Group A — left Y-axis */                             ///
    (rcap  ci_low ci_high x_plot if group=="A", lcolor(`colA') lwidth(thick) yaxis(1)) ///
    (scatter y x_plot if group=="A", mcolor(`colA') msymbol(`markA') msize(medsmall) yaxis(1)) ///
    /* Group B — left Y-axis */                             ///
    (rcap  ci_low ci_high x_plot if group=="B", lcolor(`colB') lwidth(thick) yaxis(1)) ///
    (scatter y x_plot if group=="B", mcolor(`colB') msymbol(`markB') msize(medsmall) yaxis(1)) ///
    /* Group C — right Y-axis */                            ///
    (rcap  ci_low ci_high x_plot if group=="C", lcolor(`colC') lwidth(thick) yaxis(2)) ///
    (scatter y x_plot if group=="C", mcolor(`colC') msymbol(`markC') msize(medsmall) yaxis(2)) ///
    /* Group D — right Y-axis */                            ///
    (rcap  ci_low ci_high x_plot if group=="D", lcolor(`colD') lwidth(thick) yaxis(2)) ///
    (scatter y x_plot if group=="D", mcolor(`colD') msymbol(`markD') msize(medsmall) yaxis(2)) ///
    ,                                                       ///
    /* Y-axis scales and labels */                          ///
    yscale(axis(1)) ylabel(-1(0.5)1, axis(1) labsize(medsmall)) ///
    yscale(axis(2)) ylabel(-10(5)10, axis(2) labsize(medsmall)) ///
    /* Axis titles and X-axis */                            ///
    ytitle("{bf: Chinese Firms'}""{bf: International Scientific Production}", size(medium) axis(1)) ///
    ytitle("{bf: Chinese Listed Firms'}""{bf: International Scientific Production}", size(medium) axis(2)) ///
    xtitle("{bf: Sanction Year}", size(medium)) xlabel(-3(1)3, labsize(medium))     ///
    /* Legend configuration */                              ///
    legend(order(2 "Chinese firms, full sample (left axis)" ///
                 4 "Chinese firms, matched sample (left axis)" ///
                 6 "Chinese listed firms, full sample (right axis)" ///
                 8 "Chinese listed firms, matched sample (right axis)") ///
           ring(0) pos(11) col(1) rowgap(*1.2) size(medsmall) region(margin(zero))) ///
    /* Reference lines */                                   ///
    yline(0, lpattern(dash) lcolor(gs11))                   ///
    xline(0, lpattern(dash) lcolor(gs11))                   ///
    /* Graph layout */                                      ///
    aspectratio(0.8) graphregion(margin(vsmall))


graph save ${figure_output}WOS_dynamic.gph, replace

