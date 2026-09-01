/*******************************************************************************
Project: Background Supplementary Materials (SM03A)
Script: SM_others/03_Publicly listed firms/1_US_DISCERN_plot.do

Purpose
  - Build publication trends for U.S. publicly listed firms using DISCERN data.
  - Compare three denominator definitions and produce comparison figures.

Main Inputs
  - ${discern}discern_firm_panel_1980_2021.dta

Outputs
  - Figure: ${figure_output}compare_US_Discern.gph
  - Temp files (deleted at end): temp_WOS_A/B/C.dta under ${temp_output}

Notes
  - The script includes exploratory plotting blocks and graph editor adjustments.
  - Variable names pub_WOS_* are reused for DISCERN-based series.

Dependencies
  - Expected to be called by SM_others/00_run_all.do, which defines all globals.
  - If run standalone, define required globals before execution.
*******************************************************************************/

	
********************************************************************************
****************************** DISCERN (US firm) *******************************
********************************************************************************

***************** (A) All firms with at least one publication ******************

use ${discern}discern_firm_panel_1980_2021.dta, clear 
keep permno_adj pub_fyear fyear
rename permno_adj firm_id
rename pub_fyear pub_num
rename fyear year

bys year: egen pub_num_y = sum(pub_num)
bys year (firm_id): gen firm_tag = firm_id
bys year: egen unique_firm_yr = total(firm_tag != firm_tag[_n-1])
keep pub_num_y year unique_firm_yr 
duplicates drop
gen pub_num_y_adj = pub_num_y / unique_firm_yr
keep year pub_num_y_adj
rename pub_num_y_adj pub_WOS_A
keep if year>=2010 & year<=2022

save ${temp_output}temp_WOS_A.dta, replace //year pub_WOS_A


******************* (B) Firms with more than two publications ******************

use ${discern}discern_firm_panel_1980_2021.dta, clear 
keep permno_adj pub_fyear fyear
rename permno_adj firm_id
rename pub_fyear pub_num
rename fyear year

bys firm_id: egen all_paper=sum(pub_num)
keep if all_paper>2

bys year: egen pub_num_y = sum(pub_num)
bys year (firm_id): gen firm_tag = firm_id
bys year: egen unique_firm_yr = total(firm_tag != firm_tag[_n-1])
keep pub_num_y year unique_firm_yr 
duplicates drop
gen pub_num_y_adj = pub_num_y / unique_firm_yr
keep year pub_num_y_adj
rename pub_num_y_adj pub_WOS_B
keep if year>=2010 & year<=2022

save ${temp_output}temp_WOS_B.dta, replace //year pub_WOS_B


***************** (C) Firms with publications in a given year ******************

use ${discern}discern_firm_panel_1980_2021.dta, clear 
keep permno_adj pub_fyear fyear
rename permno_adj firm_id
rename pub_fyear pub_num
rename fyear year

drop if pub_num==0 // Exclude firm-years with zero publications

bys year: egen pub_num_y = sum(pub_num)
bys year (firm_id): gen firm_tag = firm_id
bys year: egen unique_firm_yr = total(firm_tag != firm_tag[_n-1])
keep pub_num_y year unique_firm_yr 
duplicates drop
gen pub_num_y_adj = pub_num_y / unique_firm_yr
keep year pub_num_y_adj
rename pub_num_y_adj pub_WOS_C
keep if year>=2010 & year<=2022

save ${temp_output}temp_WOS_C.dta, replace //year pub_WOS_C



	
	
*-----------------------------------------------*
* Load and merge data                           *
*-----------------------------------------------*
use ${temp_output}temp_WOS_A.dta, clear
merge 1:1 year using ${temp_output}temp_WOS_B.dta
drop _merge
merge 1:1 year using ${temp_output}temp_WOS_C.dta
drop _merge

format pub_WOS_A pub_WOS_B pub_WOS_C %9.2f

*-----------------------------------------------*
* Get values for 2010                           *
*-----------------------------------------------*
quietly summarize pub_WOS_A if year == 2010, meanonly
local A2010 = r(mean)

quietly summarize pub_WOS_B if year == 2010, meanonly
local B2010 = r(mean)

quietly summarize pub_WOS_C if year == 2010, meanonly
local C2010 = r(mean)

*-----------------------------------------------*
* Get values for 2021                           *
*-----------------------------------------------*
quietly summarize pub_WOS_A if year == 2021, meanonly
local A2021 = r(mean)

quietly summarize pub_WOS_B if year == 2021, meanonly
local B2021 = r(mean)

quietly summarize pub_WOS_C if year == 2021, meanonly
local C2021 = r(mean)

*-----------------------------------------------*
* Plot with labels at 2010 and 2021             *
*-----------------------------------------------*
twoway ///
    (connected pub_WOS_A year, ///
        lwidth(medium) lcolor(red*1.4) lpattern(solid) ///
        msymbol(square) mcolor(red*1.4)) ///
    (connected pub_WOS_B year, ///
        lwidth(medium) lcolor(ebblue*1.2) lpattern(solid) ///
        msymbol(circle) mcolor(ebblue*1.2)) ///
    (connected pub_WOS_C year, ///
        lwidth(medium) lcolor(red*0.4) lpattern(dash) ///
        msymbol(triangle) mcolor(red*0.4)) ///
    , ///
    ///
    /// text labels for 2010
    text(`A2010' 2010 "`=string(`A2010',"%9.2f")'", ///
         color(red*1.4) size(small) place(ne)) ///
    text(`B2010' 2010 "`=string(`B2010',"%9.2f")'", ///
         color(ebblue*1.2) size(small) place(nw)) ///
    text(`C2010' 2010 "`=string(`C2010',"%9.2f")'", ///
         color(red*0.4) size(small) place(s)) ///
    ///
    /// text labels for 2021
    text(`A2021' 2021 "`=string(`A2021',"%9.2f")'", ///
         color(red*1.4) size(small) place(ne)) ///
    text(`B2021' 2021 "`=string(`B2021',"%9.2f")'", ///
         color(ebblue*1.2) size(small) place(nw)) ///
    text(`C2021' 2021 "`=string(`C2021',"%9.2f")'", ///
         color(red*0.4) size(small) place(s)) ///
    ///
    ytitle("{bf:Number of papers published by}" ///
           "{bf:each U.S. firm (DISCERN)}", size(small)) ///
    ylabel(0(10)50, labsize(small) format(%9.0f)) ///
    xtitle("{bf:Paper publication year}", size(small) placement(east)) ///
    xlabel(2010(1)2021, angle(45) labsize(small)) ///
    legend(order(1 "Firms with at least one publication during 2010-2021" ///
                 2 "Firms with three or more publications during 2010-2021" ///
                 3 "Firms with publications in a given year""(excluding firm-years without publications)") ///
           size(small) position(11) ring(1) row(2) ///
           region(fcolor(none) lstyle(none)) rowgap(*0.6)) ///
    aspectratio(0.8) graphregion(margin(vsmall))

	
	
twoway ///
    (connected pub_WOS_A year, ///
        lwidth(medium) lcolor(red*1.4) lpattern(solid) ///
        msymbol(square) mcolor(red*1.4)) ///
    (connected pub_WOS_B year, ///
        lwidth(medium) lcolor(ebblue*1.2) lpattern(solid) ///
        msymbol(circle) mcolor(ebblue*1.2)) ///
    (connected pub_WOS_C year, ///
        lwidth(medium) lcolor(red*0.4) lpattern(dash) ///
        msymbol(triangle) mcolor(red*0.4)) ///
    , ///
    ///
    /// text labels for 2010
    text(`A2010' 2010 "`=string(`A2010',"%9.2f")'", ///
         color(red*1.4) size(small) place(ne)) ///
    text(`B2010' 2010 "`=string(`B2010',"%9.2f")'", ///
         color(ebblue*1.2) size(small) place(nw)) ///
    text(`C2010' 2010 "`=string(`C2010',"%9.2f")'", ///
         color(red*0.4) size(small) place(s)) ///
    ///
    /// text labels for 2021
    text(`A2021' 2021 "`=string(`A2021',"%9.2f")'", ///
         color(red*1.4) size(small) place(ne)) ///
    text(`B2021' 2021 "`=string(`B2021',"%9.2f")'", ///
         color(ebblue*1.2) size(small) place(nw)) ///
    text(`C2021' 2021 "`=string(`C2021',"%9.2f")'", ///
         color(red*0.4) size(small) place(s)) ///
    ///
    ytitle("{bf:Number of papers published by}" ///
           "{bf:each U.S. firm (DISCERN)}", size(small)) ///
    ylabel(0(10)40, labsize(small) format(%9.0f)) ///
    xtitle("{bf:Paper publication year}", size(small) placement(east)) ///
    xlabel(2010(1)2021, angle(45) labsize(small)) ///
    legend(off) ///
    aspectratio(0.8) graphregion(margin(vsmall))
	
	
gr_edit .plotregion1.textbox1.DragBy -2.93474474626306 -.0931420627666433
gr_edit .plotregion1.textbox4.DragBy -2.838523607041323 -.7112666611270966
gr_edit .plotregion1.textbox5.DragBy -2.838523607041318 .0677396820121051
gr_edit .plotregion1.textbox2.DragBy -2.597970758986977 .7282015816301269
gr_edit .plotregion1.textbox3.DragBy -1.058432531439163 .3386984100605245
gr_edit .plotregion1.textbox6.DragBy -.7697691137739161 -.330230949809006


*graph save ${figure_output}WOS_US_Discern_three_types.gph, replace	
	
	
*-----------------------------------------------*
* Compute A and B values for 2010 and 2021      *
* (run after your data are already in memory)   *
*-----------------------------------------------*
quietly summarize pub_WOS_A if year == 2010, meanonly
local A2010 = r(mean)

quietly summarize pub_WOS_B if year == 2010, meanonly
local B2010 = r(mean)

quietly summarize pub_WOS_A if year == 2021, meanonly
local A2021 = r(mean)

quietly summarize pub_WOS_B if year == 2021, meanonly
local B2021 = r(mean)

*-----------------------------------------------*
* Plot with numeric labels at 2010 and 2021     *
*-----------------------------------------------*

twoway ///
    (connected pub_WOS_A year, ///
        lwidth(medium) lcolor(ebblue*1.5) lpattern(solid) ///
        msymbol(square) mcolor(ebblue*1.5)) ///
    (connected pub_WOS_B year, ///
        lwidth(medium) lcolor(red*1.5) lpattern(solid) ///
        msymbol(circle) mcolor(red*1.5)) ///
    , ///
    ///
    /// Labels at 2010
    text(`A2010' 2010 "`=string(`A2010',"%4.2f")'", ///
         color(ebblue*1.5) size(small) place(ne)) ///
    text(`B2010' 2010 "`=string(`B2010',"%4.2f")'", ///
         color(red*1.5) size(small) place(nw)) ///
    ///
    /// Labels at 2021
    text(`A2021' 2021 "`=string(`A2021',"%4.2f")'", ///
         color(ebblue*1.5) size(small) place(ne)) ///
    text(`B2021' 2021 "`=string(`B2021',"%4.2f")'", ///
         color(red*1.5) size(small) place(nw)) ///
    ///
    ytitle("{bf:Number of papers published by}" ///
           "{bf:each U.S. firm (DISCERN)}", size(small)) ///
    ylabel(0(10)40, labsize(small) format(%9.0f)) ///
    xtitle("{bf:Paper publication year}", size(small) placement(east)) ///
    xlabel(2010(1)2021, angle(45) labsize(small)) ///
    legend(order(1 "Firms with at least one publication during 2010-2021" ///
                 2 "Firms with three or more publications during 2010-2021") ///
           size(small) position(11) ring(1) row(1) ///
           region(fcolor(none) lstyle(none)) rowgap(*0.6)) ///
    aspectratio(0.8) graphregion(margin(vsmall))
	
	
twoway ///
    (connected pub_WOS_A year, ///
        lwidth(medium) lcolor(ebblue*1.5) lpattern(solid) ///
        msymbol(square) mcolor(ebblue*1.5)) ///
    (connected pub_WOS_B year, ///
        lwidth(medium) lcolor(red*1.5) lpattern(solid) ///
        msymbol(circle) mcolor(red*1.5)) ///
    , ///
    ///
    /// Labels at 2010
    text(`A2010' 2010 "`=string(`A2010',"%4.2f")'", ///
         color(ebblue*1.5) size(medium) place(ne)) ///
    text(`B2010' 2010 "`=string(`B2010',"%4.2f")'", ///
         color(red*1.5) size(medium) place(nw)) ///
    ///
    /// Labels at 2021
    text(`A2021' 2021 "`=string(`A2021',"%4.2f")'", ///
         color(ebblue*1.5) size(medium) place(ne)) ///
    text(`B2021' 2021 "`=string(`B2021',"%4.2f")'", ///
         color(red*1.5) size(medium) place(nw)) ///
    ///
    ytitle("{bf:Number of papers published by}" ///
           "{bf:each U.S. firm (DISCERN)}", size(medium)) ///
    ylabel(0(10)40, labsize(medium) format(%9.0f)) ///
    xtitle("{bf:Paper publication year}", size(medium) placement(east)) ///
    xlabel(2010(1)2021, angle(45) labsize(medium)) ///
    legend(off) ///
    aspectratio(0.8) graphregion(margin(vsmall))


gr_edit .plotregion1.textbox1.DragBy -2.906558011314347 -.1328712915358301
gr_edit .plotregion1.textbox2.DragBy 1.245667719134714 1.054665876565651
gr_edit .plotregion1.textbox4.DragBy .7172026261684824 .1162623800938473
gr_edit .plotregion1.textbox3.DragBy .9436876660111569 -.9965346865187269



graph save ${figure_output}compare_US_Discern.gph, replace


erase ${temp_output}temp_WOS_A.dta
erase ${temp_output}temp_WOS_B.dta
erase ${temp_output}temp_WOS_C.dta
