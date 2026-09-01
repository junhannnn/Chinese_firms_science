/*******************************************************************************
Project: Background Supplementary Materials (SM03C)
Script: SM_others/03_Publicly listed firms/3_6_CN_WOS_plot.do

Purpose
  - Build publication trends for Chinese publicly listed firms using WOS data.
  - Integrate listed-firm subsidiary publication additions before plotting.
  - Compare three denominator definitions and produce a comparison figure.

Main Inputs
  - ${python_output}CN_listed_subs_add.csv
  - ${stata_output}CN_WOS_DID_listed.dta

Outputs
  - Dataset: ${stata_output}WOS_CN_listed_with_subs.dta
  - Figure: ${figure_output}compare_WOS_CNpublicfirm.gph
  - Temp files (deleted at end): temp_WOS_A/B/C.dta and CN_listed_subs_add.dta

Dependencies
  - Expected to be called by SM_others/00_run_all.do, which defines all globals.
  - If run standalone, define required globals before execution.
*******************************************************************************/

	
********************************************************************************
******************* WOS (Chinese publicly listed firm) *************************
********************************************************************************

import delimited ${python_output}CN_listed_subs_add.csv, clear

rename symbol Symbol
keep if year>=2010 & year<=2022

save ${temp_output}CN_listed_subs_add.dta, replace //var: Symbol year subs_add subs_frac_add




use ${stata_output}CN_WOS_DID_listed.dta, clear
keep Symbol year pub_num_fractional // Use fractional publication counts for consistency with DISCERN

merge 1:1 Symbol year using ${temp_output}CN_listed_subs_add.dta
drop if _merge==2
replace subs_add=0 if _merge==1
replace subs_frac_add=0 if _merge==1
drop _merge

gen pub_num_all = pub_num_fractional + subs_frac_add
keep Symbol year pub_num_all
rename pub_num_all pub_num
rename Symbol firm_id

save ${stata_output}WOS_CN_listed_with_subs.dta, replace //var: firm_id year pub_num


***************** (A) All firms with at least one publication ******************

use ${stata_output}WOS_CN_listed_with_subs.dta, clear

/* If focusing only on publicly listed firms (excluding subsidiary additions)

use ${stata_output}CN_WOS_DID_listed.dta, clear
keep Symbol year pub_num
rename Symbol firm_id

*/


bys year: egen pub_num_y = sum(pub_num)
bys year (firm_id): gen firm_tag = firm_id
bys year: egen unique_firm_yr = total(firm_tag != firm_tag[_n-1])
keep pub_num_y year unique_firm_yr 
duplicates drop
gen pub_num_y_adj = pub_num_y / unique_firm_yr
keep year pub_num_y_adj
rename pub_num_y_adj pub_WOS_A
keep if year>=2010 & year<=2021

save ${temp_output}temp_WOS_A.dta, replace //year pub_WOS_A


******************* (B) Firms with more than two publications ******************

use ${stata_output}WOS_CN_listed_with_subs.dta, clear

/* If focusing only on publicly listed firms (excluding subsidiary additions)

use ${stata_output}CN_WOS_DID_listed.dta, clear
keep Symbol year pub_num
rename Symbol firm_id

*/

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
keep if year>=2010 & year<=2021

save ${temp_output}temp_WOS_B.dta, replace //year pub_WOS_B


***************** (C) Firms with publications in a given year ******************

use ${stata_output}WOS_CN_listed_with_subs.dta, clear

/* If focusing only on publicly listed firms (excluding subsidiary additions)

use ${stata_output}CN_WOS_DID_listed.dta, clear
keep Symbol year pub_num
rename Symbol firm_id

*/

drop if pub_num==0 // Exclude firm-years with zero publications

bys year: egen pub_num_y = sum(pub_num)
bys year (firm_id): gen firm_tag = firm_id
bys year: egen unique_firm_yr = total(firm_tag != firm_tag[_n-1])
keep pub_num_y year unique_firm_yr 
duplicates drop
gen pub_num_y_adj = pub_num_y / unique_firm_yr
keep year pub_num_y_adj
rename pub_num_y_adj pub_WOS_C
keep if year>=2010 & year<=2021

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
        lwidth(medium) lcolor(ebblue*1.4) lpattern(solid) ///
        msymbol(square) mcolor(ebblue*1.4)) ///
    (connected pub_WOS_B year, ///
        lwidth(medium) lcolor(ebblue*0.8) lpattern(solid) ///
        msymbol(circle) mcolor(ebblue*0.8)) ///
    (connected pub_WOS_C year, ///
        lwidth(medium) lcolor(ebblue*0.4) lpattern(dash) ///
        msymbol(triangle) mcolor(ebblue*0.4)) ///
    , ///
    ///
    /// text labels for 2010
    text(`A2010' 2010 "`=string(`A2010',"%9.2f")'", ///
         color(ebblue*1.4) size(small) place(ne)) ///
    text(`B2010' 2010 "`=string(`B2010',"%9.2f")'", ///
         color(ebblue*0.8) size(small) place(nw)) ///
    text(`C2010' 2010 "`=string(`C2010',"%9.2f")'", ///
         color(ebblue*0.4) size(small) place(s)) ///
    ///
    /// text labels for 2021
    text(`A2021' 2021 "`=string(`A2021',"%9.2f")'", ///
         color(ebblue*1.4) size(small) place(ne)) ///
    text(`B2021' 2021 "`=string(`B2021',"%9.2f")'", ///
         color(ebblue*0.8) size(small) place(nw)) ///
    text(`C2021' 2021 "`=string(`C2021',"%9.2f")'", ///
         color(ebblue*0.4) size(small) place(s)) ///
    ///
    ytitle("{bf:Number of papers published by}" ///
           "{bf:each Chinese publicly listed firm (WOS)}", size(small)) ///
    ylabel(0(10)40, labsize(small) format(%9.0f)) ///
    xtitle("{bf:Paper publication year}", size(small) placement(east)) ///
    xlabel(2010(1)2021, angle(45) labsize(small)) ///
    legend(off) ///
    aspectratio(0.8) graphregion(margin(vsmall))

gr_edit .plotregion1.textbox1.DragBy -1.116165214972181 -.076207142263618
gr_edit .plotregion1.textbox2.DragBy .3848845568869586 .5249825355938126
gr_edit .plotregion1.textbox3.DragBy -.3848845568869598 .2201539665393401
gr_edit .plotregion1.textbox4.DragBy .4618614682643507 -.5334499958453215
gr_edit .plotregion1.textbox5.DragBy .3463961011982705 .0338698410060556
gr_edit .plotregion1.textbox6.DragBy 1.077676759283497 -.3556333305635503

*graph save ${figure_output}WOS_CNpublicfirm_three_types.gph, replace	
	
	
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
           "{bf:each Chinese publicly listed firm (WOS)}", size(medium)) ///
    ylabel(0(2)10, labsize(medium) format(%9.0f)) ///
    xtitle("{bf:Paper publication year}", size(medium) placement(east)) ///
    xlabel(2010(1)2021, angle(45) labsize(medium)) ///
    legend(off) ///
    aspectratio(0.8) graphregion(margin(vsmall))

gr_edit .plotregion1.textbox1.DragBy -.6983288728482522 -.0830445572098942
gr_edit .plotregion1.textbox2.DragBy .2736694231432346 .7806188377730007
gr_edit .plotregion1.textbox3.DragBy .1604269032219026 -.7806188377730012
gr_edit .plotregion1.textbox4.DragBy .1887375332022314 .0581311900469268

graph save ${figure_output}compare_WOS_CNpublicfirm.gph, replace


erase ${temp_output}temp_WOS_A.dta
erase ${temp_output}temp_WOS_B.dta
erase ${temp_output}temp_WOS_C.dta
erase ${temp_output}CN_listed_subs_add.dta
