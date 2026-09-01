
/*******************************************************************************
Project: Robustness Checks - USPTO Patents Filed by Chinese Firms (Moderator)
Script: 06_moderator_USPTO.do

Purpose
  - Construct firm-level pre-treatment moderator variables from the USPTO
    DID panel (baseline U.S.-technology reliance measures).
  - Merge moderator variables back into the DID panel and estimate
    heterogeneity regressions with `did##dummy_uspat`.
  - Produce a grouped dynamic-event figure by low/high U.S.-tech dependence.

Inputs (from ${stata_output})
  - USpatents_DID_allfirm.dta

Outputs (saved under ${stata_output})
  - USpatents_DID_allfirm_mo.dta

Tables (saved under ${table_output})
  - robust_USPTO_mo.rtf

Figures (saved under ${figure_output})
  - robust_USPTO_mo_dynamic.gph

Temporary files (saved under ${temp_output}, deleted in-script)
  - pre_allfirm_mo.dta

Notes
  - This script does not initialize paths at the top. It assumes `${stata_output}`,
    `${table_output}`, and `${temp_output}` have already been defined by the
    caller (for example, a master runner or prior setup script).
  - User-written Stata commands required here include `reghdfe`, `ppmlhdfe`,
    `eventdd`, and `esttab`.
*******************************************************************************/
* Run via `00_run_all_6.do` (depends on shared path globals set by the runner).


********************************************************************************
**************** A. Construct Pre-Treatment Moderator Measures *****************
********************************************************************************

* For moderators that may be affected by treatment, use the pre-treatment mean.

use ${stata_output}USpatents_DID_allfirm.dta, clear


preserve

    replace dif_year = year-2022 if dif_year==.
    keep if dif_year>=-10 & dif_year<=-1

    bys firm_id: egen pre_uspat_ratio1 = mean(f_us_ratio1)
    bys firm_id: egen pre_uspat_ratio2 = mean(f_us_ratio2)
    bys firm_id: egen pre_uspat_ratio3 = mean(f_us_ratio3)


    keep firm_id pre_uspat_ratio1 pre_uspat_ratio2 pre_uspat_ratio3
    duplicates drop

    save ${temp_output}pre_allfirm_mo.dta, replace //var: firm_id pre_

restore

merge m:1 firm_id using ${temp_output}pre_allfirm_mo.dta // _merge==2 is zero
drop _merge

save ${stata_output}USpatents_DID_allfirm_mo.dta, replace

erase ${temp_output}pre_allfirm_mo.dta


**************************** B. Full-Sample Heterogeneity **********************

use ${stata_output}USpatents_DID_allfirm_mo.dta, clear

sum pre_uspat_ratio2 if pre_uspat_ratio2<., meanonly
gen dummy_uspat = pre_uspat_ratio2 >= r(mean)

* OLS
reghdfe f_cite_science_num_w did##dummy_uspat whether_pat, absorb(firm_id year) vce(r)
est store M1

* ln and OLS
reghdfe ln_f_cite_science_num did##dummy_uspat whether_pat, absorb(firm_id year) vce(r)
est store M2

* Poisson
ppmlhdfe f_cite_science_num did##dummy_uspat whether_pat, absorb(firm_id year) vce(r)
est store M3

esttab M1 M2 M3 using ${table_output}robust_USPTO_mo.rtf, ///
    replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ///
    b(%20.3f) se(%7.3f) r2(%9.3f) ///
    stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
    nobaselevels drop("1.dummy_uspat") ///
    mtitles("Model 1" "Model 2" "Model 3") ///
    nonotes
	
	
******************************** C. Dynamic Effect *****************************
	
use ${stata_output}USpatents_DID_allfirm_mo.dta, clear

sum pre_uspat_ratio2 if pre_uspat_ratio2<., meanonly
gen dummy_uspat = pre_uspat_ratio2 >= r(mean)

replace dif_year=3 if dif_year>3 & dif_year!=.
drop if dif_year!=. & !inrange(dif_year,-3,3)
			 
eventdd ln_f_cite_science_num whether_pat, over(dummy_uspat) jitter(0.2) timevar(dif_year) ///
    method(hdfe, absorb(year firm_id)) ///
    baseline(0) vce(r) level(95) ///
    graph_op(ytitle("{bf: Science-Linked USPTO Patents}""{bf: Filed by Chinese Firms}") ///
             xtitle("{bf: Sanction Year}") ///
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
gr_edit .legend.plotregion1.label[1].text.Arrpush Low U.S. tech dependence
gr_edit .legend.plotregion1.label[2].text = {}
gr_edit .legend.plotregion1.label[2].text.Arrpush High U.S. tech dependence 
gr_edit .legend.plotregion1.key[2].view.style.editstyle marker(symbol(triangle)) editcopy
gr_edit .plotregion1._xylines[1].DragBy 0 1
gr_edit .plotregion1.plot1.style.editstyle area(linestyle(color(red*1.4))) editcopy
gr_edit .plotregion1.plot3.style.editstyle area(linestyle(color(ebblue*1.2))) editcopy
gr_edit .yaxis1.reset_rule -3 3 1 , tickset(major) ruletype(range) 
gr_edit .plotregion1.plot1.style.editstyle area(linestyle(width(thick))) editcopy
gr_edit .plotregion1.plot3.style.editstyle area(linestyle(width(thick))) editcopy

graph save ${figure_output}robust_USPTO_mo_dynamic.gph, replace

