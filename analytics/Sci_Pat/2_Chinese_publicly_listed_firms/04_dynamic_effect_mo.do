/*******************************************************************************
Project: Science-linked patents—Chinese publicly listed firms
Script:  04_dynamic_effect_mo.do

Purpose:
  Estimate event-study effects separately for firms with low and high dependence
  on U.S. technology. Compare all Chinese firms with publicly listed firms in
  the full and CEM-matched samples, then construct publication-ready plots.

Main inputs (from ${stata_output}):
  - DID_allfirm_mo.dta
  - DID_allfirm_mo_cem.dta
  - DID_listedfirm_mo.dta
  - DID_listedfirm_mo_cem.dta

Main outputs:
  - ${stata_output}ROS_event_table_mo.dta: subgroup event-time estimates and bounds
  - ${figure_output}main_dynamic_low_legendoff.gph: low-dependence plot
  - ${figure_output}main_dynamic_high_legendoff.gph: high-dependence plot

Notes:
  Run through 00_run_all.do so the shared path globals are available. Temporary
  graph files are deleted after use. 
*******************************************************************************/

* ==============================================================================
* 1. Estimate moderator event studies for all Chinese firms
* ==============================================================================

* Full sample.

use ${stata_output}DID_allfirm_mo.dta, clear

drop if dif_year!=. & !inrange(dif_year,-3,3)
			 
eventdd f_cite_science_num_w whether_pat, over(moderator) jitter(0.2) timevar(dif_year) ///
    method(hdfe, absorb(year firm_id)) ///
    baseline(0) vce(r) level(95) ///
    graph_op(ytitle("Chinese firms""(full sample)") ///
             xtitle("Sanction Year") ///
             xscale(range(-3 3)) ///
			 yscale(range(-1 1)) ///
             graphregion(color(white)) ///
             bgcolor(white) ///
			 mcolor("ebblue*1.2" "red*1.4") ///
             scheme(journal) ///
			 legend(order(2 4) rows(2) position(11) ring(0) region(lcolor(none))))

gr_edit .xaxis1.reset_rule -3 3 1 , tickset(major) ruletype(range)
gr_edit .plotregion1._xylines[1].style.editstyle linestyle(pattern(dash)) editcopy
gr_edit .plotregion1._xylines[1].style.editstyle linestyle(width(thin)) editcopy
gr_edit .legend.plotregion1.label[1].text = {}
gr_edit .legend.plotregion1.label[1].text.Arrpush low U.S. tech dependence
gr_edit .legend.plotregion1.label[2].text = {}
gr_edit .legend.plotregion1.label[2].text.Arrpush high U.S. tech dependence
gr_edit .legend.plotregion1.key[2].view.style.editstyle marker(symbol(triangle)) editcopy
gr_edit .plotregion1._xylines[1].DragBy 0 1
gr_edit .plotregion1.plot1.style.editstyle area(linestyle(color(red*1.4))) editcopy
gr_edit .plotregion1.plot3.style.editstyle area(linestyle(color(ebblue*1.2))) editcopy

graph save ${figure_output}dynamic_mo_1.gph, replace

* Store separate low- and high-dependence models for coefficient extraction.
eventdd f_cite_science_num_w whether_pat if moderator == 0, ///
    timevar(dif_year) ///
    method(hdfe, absorb(year firm_id)) ///
    baseline(0) vce(r) level(95)
est store M1

eventdd f_cite_science_num_w whether_pat if moderator == 1, ///
    timevar(dif_year) ///
    method(hdfe, absorb(year firm_id)) ///
    baseline(0) vce(r) level(95)
est store M2
* CEM-matched sample.

use ${stata_output}DID_allfirm_mo_cem.dta, clear

drop if dif_year!=. & !inrange(dif_year,-3,3)
keep if cem_matched==1
		 
eventdd f_cite_science_num_w whether_pat [aweight=cem_weights], over(moderator) jitter(0.2) timevar(dif_year) ///
    method(hdfe, absorb(year firm_id)) ///
    baseline(0) vce(r) level(95) ///
    graph_op(ytitle("Chinese firms""(matched sample)") ///
             xtitle("Sanction Year") ///
             xscale(range(-3 3)) ///
			 yscale(range(-1 1)) ///
             graphregion(color(white)) ///
             bgcolor(white) ///
			 mcolor("ebblue*1.2" "red*1.4") ///
             scheme(journal) ///
			 legend(order(2 4) rows(2) position(11) ring(0) region(lcolor(none))))			 
			 
gr_edit .xaxis1.reset_rule -3 3 1 , tickset(major) ruletype(range)
gr_edit .plotregion1._xylines[1].style.editstyle linestyle(pattern(dash)) editcopy
gr_edit .plotregion1._xylines[1].style.editstyle linestyle(width(thin)) editcopy
gr_edit .legend.plotregion1.label[1].text = {}
gr_edit .legend.plotregion1.label[1].text.Arrpush low U.S. tech dependence
gr_edit .legend.plotregion1.label[2].text = {}
gr_edit .legend.plotregion1.label[2].text.Arrpush high U.S. tech dependence 
gr_edit .legend.plotregion1.key[2].view.style.editstyle marker(symbol(triangle)) editcopy
gr_edit .plotregion1._xylines[1].DragBy 0 1
gr_edit .plotregion1.plot1.style.editstyle area(linestyle(color(red*1.4))) editcopy
gr_edit .plotregion1.plot3.style.editstyle area(linestyle(color(ebblue*1.2))) editcopy

graph save ${figure_output}dynamic_mo_2.gph, replace

* Store weighted subgroup models for coefficient extraction.
eventdd f_cite_science_num_w whether_pat [aweight=cem_weights] if moderator == 0, ///
    timevar(dif_year) ///
    method(hdfe, absorb(year firm_id)) ///
    baseline(0) vce(r) level(95)
est store M3

eventdd f_cite_science_num_w whether_pat [aweight=cem_weights] if moderator == 1, ///
    timevar(dif_year) ///
    method(hdfe, absorb(year firm_id)) ///
    baseline(0) vce(r) level(95)
est store M4
* ==============================================================================
* 2. Estimate moderator event studies for publicly listed firms
* ==============================================================================

* Full sample.

use ${stata_output}DID_listedfirm_mo.dta, clear

global controls firm_size cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ academic_experience

drop if dif_year!=. & !inrange(dif_year,-3,3)


eventdd f_cite_science_num_w whether_pat $controls, over(moderator) jitter(0.2) timevar(dif_year) ///
    method(hdfe, absorb(year firm_id)) ///
    baseline(0) vce(r) level(95) ///
    graph_op(ytitle("Chinese publicly listed firms""(full sample)") ///
             xtitle("Sanction Year") ///
             xscale(range(-3 3)) ///
			 yscale(range(-1 1)) ///
             graphregion(color(white)) ///
             bgcolor(white) ///
			 mcolor("ebblue*1.2" "red*1.4") ///
             scheme(journal) ///
			 legend(order(2 4) rows(2) position(11) ring(0) region(lcolor(none))))

gr_edit .xaxis1.reset_rule -3 3 1 , tickset(major) ruletype(range)
gr_edit .plotregion1._xylines[1].style.editstyle linestyle(pattern(dash)) editcopy
gr_edit .plotregion1._xylines[1].style.editstyle linestyle(width(thin)) editcopy
gr_edit .legend.plotregion1.label[1].text = {}
gr_edit .legend.plotregion1.label[1].text.Arrpush low U.S. tech dependence
gr_edit .legend.plotregion1.label[2].text = {}
gr_edit .legend.plotregion1.label[2].text.Arrpush high U.S. tech dependence
gr_edit .legend.plotregion1.key[2].view.style.editstyle marker(symbol(triangle)) editcopy
gr_edit .plotregion1._xylines[1].DragBy 0 1
gr_edit .plotregion1.plot1.style.editstyle area(linestyle(color(red*1.4))) editcopy
gr_edit .plotregion1.plot3.style.editstyle area(linestyle(color(ebblue*1.2))) editcopy

graph save ${figure_output}dynamic_mo_3.gph, replace

* Store separate low- and high-dependence models for coefficient extraction.
eventdd f_cite_science_num_w whether_pat $controls if moderator == 0, ///
    timevar(dif_year) ///
    method(hdfe, absorb(year firm_id)) ///
    baseline(0) vce(r) level(95)
est store M5

eventdd f_cite_science_num_w whether_pat $controls if moderator == 1, ///
    timevar(dif_year) ///
    method(hdfe, absorb(year firm_id)) ///
    baseline(0) vce(r) level(95)
est store M6
* CEM-matched sample.

use ${stata_output}DID_listedfirm_mo_cem.dta, clear

global controls firm_size cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ academic_experience

drop if dif_year!=. & !inrange(dif_year,-3,3)
keep if cem_matched==1

eventdd f_cite_science_num_w whether_pat $controls [aweight=cem_weights], over(moderator) jitter(0.2) timevar(dif_year) ///
    method(hdfe, absorb(year firm_id)) ///
    baseline(0) vce(r) level(95) ///
    graph_op(ytitle("Chinese publicly listed firms""(matched sample)") ///
             xtitle("Sanction Year") ///
             xscale(range(-3 3)) ///
			 yscale(range(-1 1)) ///
             graphregion(color(white)) ///
             bgcolor(white) ///
			 mcolor("ebblue*1.2" "red*1.4") ///
             scheme(journal) ///
			 legend(order(2 4) rows(2) position(11) ring(0) region(lcolor(none))))			 
			 
gr_edit .xaxis1.reset_rule -3 3 1 , tickset(major) ruletype(range)
gr_edit .plotregion1._xylines[1].style.editstyle linestyle(pattern(dash)) editcopy
gr_edit .plotregion1._xylines[1].style.editstyle linestyle(width(thin)) editcopy
gr_edit .legend.plotregion1.label[1].text = {}
gr_edit .legend.plotregion1.label[1].text.Arrpush low U.S. tech dependence
gr_edit .legend.plotregion1.label[2].text = {}
gr_edit .legend.plotregion1.label[2].text.Arrpush high U.S. tech dependence
gr_edit .legend.plotregion1.key[2].view.style.editstyle marker(symbol(triangle)) editcopy
gr_edit .plotregion1._xylines[1].DragBy 0 1
gr_edit .plotregion1.plot1.style.editstyle area(linestyle(color(red*1.4))) editcopy
gr_edit .plotregion1.plot3.style.editstyle area(linestyle(color(ebblue*1.2))) editcopy

graph save ${figure_output}dynamic_mo_4.gph, replace

* Store weighted subgroup models for coefficient extraction.
eventdd f_cite_science_num_w whether_pat $controls [aweight=cem_weights] if moderator == 0, ///
    timevar(dif_year) ///
    method(hdfe, absorb(year firm_id)) ///
    baseline(0) vce(r) level(95)
est store M7

eventdd f_cite_science_num_w whether_pat $controls [aweight=cem_weights] if moderator == 1, ///
    timevar(dif_year) ///
    method(hdfe, absorb(year firm_id)) ///
    baseline(0) vce(r) level(95)
est store M8

* ==============================================================================
* 3. Combine sample-specific moderator graphs and remove temporary files
* ==============================================================================

graph combine ${figure_output}dynamic_mo_1.gph ${figure_output}dynamic_mo_2.gph ///
${figure_output}dynamic_mo_3.gph ${figure_output}dynamic_mo_4.gph

erase ${figure_output}dynamic_mo_1.gph
erase ${figure_output}dynamic_mo_2.gph
erase ${figure_output}dynamic_mo_3.gph
erase ${figure_output}dynamic_mo_4.gph
* ==============================================================================
* 4. Assemble subgroup event-study estimates into an analysis dataset
* ==============================================================================

local models M1 M2 M3 M4 M5 M6 M7 M8
local groups A  A  B  B  C  C  D  D
local dep    low high low high low high low high

tempname posth
tempfile  out

* Store numeric results as doubles to avoid precision loss.
postfile `posth' ///
    str1   group ///
    str4   dep   ///
    double x     ///
    double y     ///
    double ci_low double ci_high ///
    using `out', replace

* Use the standard-normal critical value for 95% confidence intervals.
local z95 = invnormal(0.975)   // 95% CI

local k = 0
foreach m of local models {
    local ++k
    local g : word `k' of `groups'
    local d : word `k' of `dep'

	local z_model = `z95'

    estimates restore `m'

    local names : colnames e(b)

    foreach nm of local names {
        local nm_low = lower("`nm'")

        local matched = 0
        local x = .

        * Map leadK coefficients to negative event time.
        quietly if regexm("`nm_low'", "lead([0-9]+)") {
            local K = real(regexs(1))
            local x = -`K'
            local matched = 1
        }

        * Map lagK coefficients to positive event time.
        quietly if (`matched'==0) & regexm("`nm_low'", "lag([0-9]+)") {
            local K = real(regexs(1))
            local x = `K'
            local matched = 1
        }

        if (`matched') {
            capture scalar b  = _b[`nm']
            capture scalar se = _se[`nm']
            if (_rc == 0) {
                scalar lo = b - `z_model'*se
                scalar hi = b + `z_model'*se
                post `posth' ("`g'") ("`d'") (`x') (b) (lo) (hi)
            }
        }
    }

    * Add the omitted baseline at event time zero.
    post `posth' ("`g'") ("`d'") (0) (0) (0) (0)
}

postclose `posth'

use `out', clear
order group dep x y ci_low ci_high
sort dep group x

save ${stata_output}ROS_event_table_mo.dta, replace
* ==============================================================================
* 5. Plot event studies by technology-dependence group using two y-axes
* ==============================================================================

use ${stata_output}ROS_event_table_mo.dta, clear

local colA green*1
local colB ebblue*1.5
local colC purple*1.5
local colD red*1.5

local markA circle
local markB square
local markC triangle
local markD diamond

* Low U.S. technology dependence.
preserve
keep if dep=="low"

gen double x_plot = x + ///
        cond(group=="A", -0.24, ///
        cond(group=="B", -0.08, ///
        cond(group=="C",  0.08, ///
                          0.24)))   // D

twoway                                                      ///
    /* Group A: left axis */                                     ///
    (rcap  ci_low ci_high x_plot if group=="A", lcolor(`colA') lwidth(thick) yaxis(1)) ///
    (scatter y x_plot if group=="A", mcolor(`colA') msymbol(`markA') msize(medsmall) yaxis(1)) ///
    /* Group B: left axis */                                     ///
    (rcap  ci_low ci_high x_plot if group=="B", lcolor(`colB') lwidth(thick) yaxis(1)) ///
    (scatter y x_plot if group=="B", mcolor(`colB') msymbol(`markB') msize(medsmall) yaxis(1)) ///
    /* Group C: right axis */                                     ///
    (rcap  ci_low ci_high x_plot if group=="C", lcolor(`colC') lwidth(thick) yaxis(2)) ///
    (scatter y x_plot if group=="C", mcolor(`colC') msymbol(`markC') msize(medsmall) yaxis(2)) ///
    /* Group D: right axis */                                     ///
    (rcap  ci_low ci_high x_plot if group=="D", lcolor(`colD') lwidth(thick) yaxis(2)) ///
    (scatter y x_plot if group=="D", mcolor(`colD') msymbol(`markD') msize(medsmall) yaxis(2)) ///
    ,                                                       ///
    /* left axis: range and title */                                    ///
    yscale(range(-3 3) axis(1))                             ///
    ylabel(-3(1)3, labsize(medsmall) axis(1))               ///
    ytitle("{bf: Chinese Firms' Science-Linked Patents}", axis(1) size(medium)) ///
    /* right axis: range and title */      ///
    yscale(range(-15 15) axis(2))                             ///
    ylabel(-15(5)15, labsize(medsmall) axis(2))               ///
    ytitle("{bf: Chinese Listed Firms' Science-Linked Patents}", axis(2) size(medsmall) orientation(vertical))                                     ///
    /* X */                                              ///
    xtitle("{bf: Sanction Year}", size(medium)) xlabel(-3(1)3, labsize(medium))     ///
    /* legend */                                              ///
    legend(order(2 "Chinese firms, full sample (left axis)"             ///
                 4 "Chinese firms, matched sample (left axis)"          ///
                 6 "Chinese listed firms, full sample (right axis)"      ///
                 8 "Chinese listed firms, matched sample (right axis)")  ///
           ring(0) pos(11) col(1) size(vsmall) region(margin(zero))) ///
    /* reference line */                           ///
    yline(0, lpattern(dash) lcolor(gs11) axis(1))           ///
    yline(0, lpattern(dash) lcolor(gs11) axis(2))           ///
    xline(0, lpattern(dash) lcolor(gs11))                   ///
    /* layout */                                              ///
    aspectratio(0.8) graphregion(margin(vsmall))            ///
    title("{bf: (1) Low U.S. tech dependence}", size(medsmall))

graph save ${figure_output}main_dynamic_low.gph, replace

* Create a legend-free version for use in a combined figure.
twoway                                                      ///
    /* Group A: left axis */                                     ///
    (rcap  ci_low ci_high x_plot if group=="A", lcolor(`colA') lwidth(thick) yaxis(1)) ///
    (scatter y x_plot if group=="A", mcolor(`colA') msymbol(`markA') msize(medsmall) yaxis(1)) ///
    /* Group B: left axis */                                     ///
    (rcap  ci_low ci_high x_plot if group=="B", lcolor(`colB') lwidth(thick) yaxis(1)) ///
    (scatter y x_plot if group=="B", mcolor(`colB') msymbol(`markB') msize(medsmall) yaxis(1)) ///
    /* Group C: right axis */                                     ///
    (rcap  ci_low ci_high x_plot if group=="C", lcolor(`colC') lwidth(thick) yaxis(2)) ///
    (scatter y x_plot if group=="C", mcolor(`colC') msymbol(`markC') msize(medsmall) yaxis(2)) ///
    /* Group D: right axis */                                     ///
    (rcap  ci_low ci_high x_plot if group=="D", lcolor(`colD') lwidth(thick) yaxis(2)) ///
    (scatter y x_plot if group=="D", mcolor(`colD') msymbol(`markD') msize(medsmall) yaxis(2)) ///
    ,                                                       ///
    /* left axis: range and title */                                    ///
    yscale(range(-3 3) axis(1))                             ///
    ylabel(-3(1)3, labsize(medsmall) axis(1))               ///
    ytitle("{bf: Chinese Firms' Science-Linked Patents}", axis(1) size(medium)) ///
    /* right axis: range and title */      ///
    yscale(range(-15 15) axis(2))                             ///
    ylabel(-15(5)15, labsize(medsmall) axis(2))               ///
    ytitle("{bf: Chinese Listed Firms' Science-Linked Patents}", axis(2) size(medsmall) orientation(vertical))                                     ///
    /* X */                                              ///
    xtitle("{bf: Sanction Year}", size(medium)) xlabel(-3(1)3, labsize(medium))     ///
    /* legend */                                              ///
    legend(off) ///
    /* reference line */                           ///
    yline(0, lpattern(dash) lcolor(gs11) axis(1))           ///
    yline(0, lpattern(dash) lcolor(gs11) axis(2))           ///
    xline(0, lpattern(dash) lcolor(gs11))                   ///
    /* layout */                                              ///
    aspectratio(0.8) graphregion(margin(vsmall))            ///
    title("{bf: (1) Low U.S. tech dependence}", size(medsmall))

graph save ${figure_output}main_dynamic_low_legendoff.gph, replace

restore
* High U.S. technology dependence.
preserve
keep if dep=="high"

gen double x_plot = x + ///
        cond(group=="A", -0.24, ///
        cond(group=="B", -0.08, ///
        cond(group=="C",  0.08, ///
                          0.24)))   // D

twoway                                                      ///
    /* Group A: left axis */                                     ///
    (rcap  ci_low ci_high x_plot if group=="A", lcolor(`colA') lwidth(thick) yaxis(1)) ///
    (scatter y x_plot if group=="A", mcolor(`colA') msymbol(`markA') msize(medsmall) yaxis(1)) ///
    /* Group B: left axis */                                     ///
    (rcap  ci_low ci_high x_plot if group=="B", lcolor(`colB') lwidth(thick) yaxis(1)) ///
    (scatter y x_plot if group=="B", mcolor(`colB') msymbol(`markB') msize(medsmall) yaxis(1)) ///
    /* Group C: right axis */                                     ///
    (rcap  ci_low ci_high x_plot if group=="C", lcolor(`colC') lwidth(thick) yaxis(2)) ///
    (scatter y x_plot if group=="C", mcolor(`colC') msymbol(`markC') msize(medsmall) yaxis(2)) ///
    /* Group D: right axis */                                     ///
    (rcap  ci_low ci_high x_plot if group=="D", lcolor(`colD') lwidth(thick) yaxis(2)) ///
    (scatter y x_plot if group=="D", mcolor(`colD') msymbol(`markD') msize(medsmall) yaxis(2)) ///
    ,                                                       ///
    /* left axis */                                              ///
    yscale(range(-3 3) axis(1))                             ///
    ylabel(-3(1)3, labsize(medsmall) axis(1))               ///
    ytitle("{bf: Chinese Firms' Science-Linked Patents}", axis(1) size(medium)) ///
    /* right axis */                                              ///
    yscale(range(-15 15) axis(2))                             ///
    ylabel(-15(5)15, labsize(medsmall) axis(2))               ///
    ytitle("{bf: Chinese Listed Firms' Science-Linked Patents}", axis(2) size(medsmall) orientation(vertical))                                     ///
    /* X  */                                              ///
    xtitle("{bf: Sanction Year}", size(medium)) xlabel(-3(1)3, labsize(medium))     ///
    /* legend */                                              ///
    legend(order(2 "Chinese firms, full sample (left axis)"             ///
                 4 "Chinese firms, matched sample (left axis)"          ///
                 6 "Chinese listed firms, full sample (right axis)"      ///
                 8 "Chinese listed firms, matched sample (right axis)")  ///
           ring(0) pos(11) col(1) size(vsmall) region(margin(zero))) ///
    /* reference line */                                             ///
    yline(0, lpattern(dash) lcolor(gs11) axis(1))           ///
    yline(0, lpattern(dash) lcolor(gs11) axis(2))           ///
    xline(0, lpattern(dash) lcolor(gs11))                   ///
    aspectratio(0.8) graphregion(margin(vsmall))            ///
    title("{bf: (2) High U.S. tech dependence}", size(medsmall))

graph save ${figure_output}main_dynamic_high.gph, replace

* Create a legend-free version for use in a combined figure.
twoway                                                      ///
    /* Group A: left axis */                                     ///
    (rcap  ci_low ci_high x_plot if group=="A", lcolor(`colA') lwidth(thick) yaxis(1)) ///
    (scatter y x_plot if group=="A", mcolor(`colA') msymbol(`markA') msize(medsmall) yaxis(1)) ///
    /* Group B: left axis */                                     ///
    (rcap  ci_low ci_high x_plot if group=="B", lcolor(`colB') lwidth(thick) yaxis(1)) ///
    (scatter y x_plot if group=="B", mcolor(`colB') msymbol(`markB') msize(medsmall) yaxis(1)) ///
    /* Group C: right axis */                                     ///
    (rcap  ci_low ci_high x_plot if group=="C", lcolor(`colC') lwidth(thick) yaxis(2)) ///
    (scatter y x_plot if group=="C", mcolor(`colC') msymbol(`markC') msize(medsmall) yaxis(2)) ///
    /* Group D: right axis */                                     ///
    (rcap  ci_low ci_high x_plot if group=="D", lcolor(`colD') lwidth(thick) yaxis(2)) ///
    (scatter y x_plot if group=="D", mcolor(`colD') msymbol(`markD') msize(medsmall) yaxis(2)) ///
    ,                                                       ///
    /* left axis */                                              ///
    yscale(range(-3 3) axis(1))                             ///
    ylabel(-3(1)3, labsize(medsmall) axis(1))               ///
    ytitle("{bf: Chinese Firms' Science-Linked Patents}", axis(1) size(medium)) ///
    /* right axis */                                              ///
    yscale(range(-15 15) axis(2))                             ///
    ylabel(-15(5)15, labsize(medsmall) axis(2))               ///
    ytitle("{bf: Chinese Listed Firms' Science-Linked Patents}", axis(2) size(medsmall) orientation(vertical))                                     ///
    /* X  */                                              ///
    xtitle("{bf: Sanction Year}", size(medium)) xlabel(-3(1)3, labsize(medium))     ///
    /* legend */                                              ///
    legend(off) ///
    /* reference line */                                             ///
    yline(0, lpattern(dash) lcolor(gs11) axis(1))           ///
    yline(0, lpattern(dash) lcolor(gs11) axis(2))           ///
    xline(0, lpattern(dash) lcolor(gs11))                   ///
    aspectratio(0.8) graphregion(margin(vsmall))            ///
    title("{bf: (2) High U.S. tech dependence}", size(medsmall))

graph save ${figure_output}main_dynamic_high_legendoff.gph, replace

restore
* ==============================================================================
* 6. Clean temporary graphs
* ==============================================================================

* Remove the temporary versions that include legends.
erase ${figure_output}main_dynamic_low.gph
erase ${figure_output}main_dynamic_high.gph
