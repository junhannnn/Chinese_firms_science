/*******************************************************************************
Project: Science-linked patents—Chinese publicly listed firms
Script:  03_dynamic_effect_main.do

Purpose:
  Estimate event-study effects around the sanction year for all Chinese firms
  and for publicly listed firms. Compare full and CEM-matched samples, assemble
  the stored estimates into a reusable dataset, and plot the four series.

Main inputs (from ${stata_output}):
  - DID_allfirm-level.dta
  - DID_allfirm-level_cem.dta
  - DID_listedfirm-level.dta
  - DID_listedfirm-level_cem.dta

Main outputs:
  - ${stata_output}ROS_event_table.dta: event-time estimates and confidence bounds
  - ${figure_output}main_dynamic.gph: combined event-study plot

Notes:
  Run through 00_run_all.do so the shared path globals are available. Temporary
  sample-specific graph files are deleted after they are combined.
*******************************************************************************/

* ==============================================================================
* 1. Estimate event-study models for all Chinese firms
* ==============================================================================

* Full sample.

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


* CEM-matched sample.

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


* ==============================================================================
* 2. Estimate event-study models for publicly listed firms
* ==============================================================================

* Full sample.

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


* CEM-matched sample.

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
* ==============================================================================
* 3. Combine the sample-specific event-study graphs
* ==============================================================================

graph combine ${figure_output}dynamic1.gph ${figure_output}dynamic2.gph ///
${figure_output}dynamic3.gph ${figure_output}dynamic4.gph

erase ${figure_output}dynamic1.gph
erase ${figure_output}dynamic2.gph
erase ${figure_output}dynamic3.gph
erase ${figure_output}dynamic4.gph
* ==============================================================================
* 4. Assemble event-study estimates into an analysis dataset
* ==============================================================================

* Map the four stored models to plot groups A–D.
local models M1 M2 M3 M4
local groups A B C D

tempname posth
tempfile  out
postfile `posth' str1 group x y ci_low ci_high using `out', replace

* Use the standard-normal critical value for 95% confidence intervals.
local z = invnormal(0.975) // 90% CI: invnormal(0.95); 95% CI: invnormal(0.975)

local k = 0
foreach m of local models {
    local ++k
    local g : word `k' of `groups'
    estimates restore `m'

    * Retrieve the coefficient names from the restored model.
    local names : colnames e(b)

    * Extract coefficients whose names identify event-time leads or lags.
    foreach nm of local names {
        * Normalize case before matching the coefficient name.
        local nm_low = lower("`nm'")

        local matched = 0
        local x = .

        * Map leadK coefficients to negative event time.
        quietly if regexm("`nm_low'","lead([0-9]+)") {
            local K = real(regexs(1))
            local x = -`K'
            local matched = 1
        }

        * Map lagK coefficients to positive event time.
        quietly if (`matched'==0) & regexm("`nm_low'","lag([0-9]+)") {
            local K = real(regexs(1))
            local x = `K'
            local matched = 1
        }

        if (`matched') {
            * Calculate confidence bounds from the coefficient and standard error.
            capture scalar b  = _b[`nm']
            capture scalar se = _se[`nm']
            if (_rc==0) {
                scalar lo = b - `z'*se
                scalar hi = b + `z'*se
                post `posth' ("`g'") (`x') (b) (lo) (hi)
            }
        }
    }

    * Add the omitted baseline at event time zero.
    post `posth' ("`g'") (0) (0) (0) (0)
}
postclose `posth'

use `out', clear
order group x y ci_low ci_high
sort group x

save ${stata_output}ROS_event_table.dta, replace
* ==============================================================================
* 5. Plot all four event-study series using two y-axes
* ==============================================================================

use ${stata_output}ROS_event_table.dta, clear

* Offset event-time positions slightly so overlapping series remain visible.
gen double x_plot = x + ///
        cond(group=="A", -0.24, ///
        cond(group=="B", -0.08, ///
        cond(group=="C",  0.08, ///
                          0.24)))   // D

* Assign a distinct color to each sample and population combination.
local colA green*1
local colB ebblue*1.5
local colC purple*1.5
local colD red*1.5

* Assign a distinct marker to each sample and population combination.
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
