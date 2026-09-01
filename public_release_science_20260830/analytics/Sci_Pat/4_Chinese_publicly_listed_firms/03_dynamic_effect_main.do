/*******************************************************************************
Project: Chinese Publicly Listed Firms - Dynamic Effects (Main)
Script: 03_dynamic_effect_main.do

Purpose
  - Estimate and visualize dynamic event-study effects for Chinese firms and
    publicly listed firms under the main specifications.
  - Export dynamic-effect figures and event-study result tables.

Inputs (from ${stata_output})
  - DID_allfirm-level.dta
  - DID_allfirm-level_cem.dta
  - DID_listedfirm-level.dta

Outputs
  - Figures saved under ${figure_output}
  - Event-study tables saved in paths used below (e.g., ${table_output})

Notes
  - This script assumes path globals are defined by
    4_Chinese_publicly_listed_firms/00_run_all_4.do.
*******************************************************************************/
* Run via `00_run_all_4.do` (depends on shared path globals set by the runner).




********************************************************************************
********************************* All firms ************************************
********************************************************************************

use ${stata_output}DID_allfirm-level.dta, clear

drop if dif_year!=. & !inrange(dif_year, -3, 3)

eventdd f_cite_science_num_w whether_pat, timevar(dif_year) ///
    method(hdfe, absorb(firm_id year)) ///
    baseline(0) vce(r) level(95) ///
    graph_op(ytitle("# of Chinese science-reliant patents") ///
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

use ${stata_output}DID_allfirm-level_cem.dta, clear

drop if dif_year!=. & !inrange(dif_year, -3, 3)
keep if cem_matched==1

eventdd f_cite_science_num_w whether_pat [aweight=cem_weights], timevar(dif_year) ///
    method(hdfe, absorb(firm_id year)) ///
    baseline(0) vce(r) level(95) ///
    graph_op(ytitle("# of Chinese science-reliant patents") ///
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

use ${stata_output}DID_listedfirm-level.dta, clear

drop if dif_year!=. & !inrange(dif_year, -3, 3)

eventdd f_cite_science_num_w whether_pat, timevar(dif_year) ///
    method(hdfe, absorb(ListedCoID year)) ///
    baseline(0) vce(r) level(95) ///
    graph_op(ytitle("# of Chinese science-reliant patents") ///
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

use ${stata_output}DID_listedfirm-level_cem.dta, clear

drop if dif_year!=. & !inrange(dif_year, -3, 3)
keep if cem_matched==1

eventdd f_cite_science_num_w whether_pat [aweight=cem_weights], timevar(dif_year) ///
    method(hdfe, absorb(ListedCoID year)) ///
    baseline(0) vce(r) level(95) ///
    graph_op(ytitle("# of Chinese science-reliant patents") ///
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

save ${stata_output}ROS_event_table.dta, replace


********************************************************************************
**************************** plot four dynamic effect **************************
********************************************************************************

******************************* two Y-axis *************************************

use ${stata_output}ROS_event_table.dta, clear

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
    yscale(range(-3 3) axis(1)) ylabel(-3(1)3, axis(1) labsize(medsmall)) ///
    yscale(range(-15 15) axis(2)) ylabel(-15(5)15, axis(2) labsize(medsmall)) ///
    /* Axis titles and X-axis */                            ///
    ytitle("{bf:Chinese Firms' Science-Linked Patents}", size(medium) axis(1)) ///
    ytitle("{bf:Chinese Listed Firms' Science-Linked Patents}", size(medium) axis(2)) ///
    xtitle("{bf:Sanction Year}",  size(medium)) xlabel(-3(1)3, labsize(medium))     ///
    /* Legend configuration */                              ///
    legend(order(2 "All firms, full sample (left axis)" ///
                 4 "All firms, matched sample (left axis)" ///
                 6 "Publicly listed firms, full sample (right axis)" ///
                 8 "Publicly listed firms, matched sample (right axis)") ///
           col(1) ring(0) position(11) rowgap(*1.2) size(medsmall) region(margin(zero))) ///    
    /* Reference lines */                                   ///
    yline(0, lpattern(dash) lcolor(gs11))                   ///
    xline(0, lpattern(dash) lcolor(gs11))                   ///
    /* Graph layout */                                      ///
    aspectratio(0.8) graphregion(margin(small)) plotregion(margin(small))

	
graph save ${figure_output}main_dynamic.gph, replace
