/*******************************************************************************
Project: Background Supplementary Materials (SM01)
Script: SM_others/01_ROS_US_firm.do

Purpose
  - Build yearly trends of science-reliant USPTO patents filed by U.S. firms.
  - Plot both level (count) and share metrics for 2010-2022.

Main Inputs
  - ${USpatents}g_assignee_disambiguated.tsv
  - ${PCS}_pcs_oa.csv
  - ${USpatents_stata}USpatent_type_onlyUS.dta
  - ${USpatents_stata}USpatents_appyr.dta
  - ${USpatents_stata}USpatents_grtyr.dta

Outputs
  - Figure: ${figure_output}time_trend_USfirm_USPTO.gph
  - Temp files (deleted at end): ${temp_output}temp1.dta, ${temp_output}temp2.dta

Dependencies
  - Expected to be called by SM_others/00_run_all.do, which defines all globals.
  - If run standalone, define required globals before execution.
*******************************************************************************/

************** Number and percentage of U.S. science-reliant patents ***********

import delimited ${USpatents}g_assignee_disambiguated.tsv, clear
keep if assignee_sequence==0
keep patent_id disambig_assignee_organization
duplicates drop
save ${temp_output}temp1.dta, replace



import delimited ${PCS}_pcs_oa.csv, clear
gen pat_country = substr(patent, 1, 2)
keep if pat_country == "us"
gen patent_id = regexs(1) if regexm(patent, "-([0-9]+)-")

keep patent_id
duplicates drop
gen cite_science=1

* (1) merge type
merge m:1 patent_id using ${USpatents_stata}USpatent_type_onlyUS.dta //_merge==1: US patents citing science but not filed by U.S. entities, _merge==2: US patents filed by U.S. entities but not citing science, _merge==3: US patents filed by U.S. entities and citing science
drop if _merge==1
drop _merge
label var type "The type of US patents"
replace cite_science=0 if cite_science==.

* (2) merge application year
merge m:1 patent_id using ${USpatents_stata}USpatents_appyr.dta
drop if _merge==2
drop _merge


* (3) merge grant year
merge m:1 patent_id using ${USpatents_stata}USpatents_grtyr.dta
drop if _merge==2
drop _merge

* (4) merge firm name
merge m:1 patent_id using ${temp_output}temp1.dta
drop if _merge==2
drop _merge


save ${temp_output}temp2.dta, replace



*** (2) Build annual series by grant year

use ${temp_output}temp2.dta, clear
keep if type==2 //US firms
rename grtyr year

bys year: gen patent_grtyr = _N
bys year: egen sci_reliant_patent_grtyr = sum(cite_science)

* Number of firms with science-reliant patents each year
bysort year disambig_assignee_organization: egen has_citesci = max(cite_science)
bysort year disambig_assignee_organization: gen tag = has_citesci if _n == 1   // 1 = this firm cited science in this year
bysort year: egen unique_citesci_firm_yr = total(tag)

keep year sci_reliant_patent_grtyr patent_grtyr unique_citesci_firm_yr
duplicates drop

gen sci_reliant_ratio_grtyr = sci_reliant_patent_grtyr / patent_grtyr
gen sci_reliant_patent_grtyr_adj2 = sci_reliant_patent_grtyr / unique_citesci_firm_yr

keep if year>=2010 & year<=2022


*-------------------------------
* 1) Split endpoints into two indicators
*-------------------------------
gen byte ep2010 = (year==2010)
gen byte ep2022 = (year==2022)

*-------------------------------
* 2) Generate label strings
*-------------------------------
gen str num_label = string(sci_reliant_patent_grtyr, "%9.0fc")
gen str pct_label = string(sci_reliant_ratio_grtyr*100, "%9.2f") + "%"

*-------------------------------
* 3) Slight x-axis adjustment for endpoint labels
*-------------------------------
gen double year_lbl = year
replace year_lbl = year + 0.5 if year==2010
replace year_lbl = year - 0.5 if year==2022

*-------------------------------
* 4) Plot: two connected series + four scatter layers (2010 and 2022 separately)
*-------------------------------
twoway ///
    (connected sci_reliant_patent_grtyr year, ///
        yaxis(1) lwidth(medium) lcolor(red*1.4) lpattern(solid) ///
        msymbol(square) mcolor(red*1.4)) || ///
    (connected sci_reliant_ratio_grtyr year, ///
        yaxis(2) lwidth(medium) lcolor(ebblue*1.2) lpattern(dash) ///
        msymbol(circle) mcolor(ebblue*1.2)) || ///
    /* Left axis (count): 2010 endpoint label */ ///
    (scatter sci_reliant_patent_grtyr year_lbl if ep2010, ///
        yaxis(1) msymbol(none) ///
        mlabel(num_label) mlabposition(6) mlabgap(1) mlabsize(medsmall) ///
        mlabcolor(red*1.5)) || ///
    /* Left axis (count): 2022 endpoint label */ ///
    (scatter sci_reliant_patent_grtyr year_lbl if ep2022, ///
        yaxis(1) msymbol(none) ///
        mlabel(num_label) mlabposition(6) mlabgap(0) mlabsize(medsmall) ///
        mlabcolor(red*1.5)) || ///
    /* Right axis (share): 2010 endpoint label */ ///
    (scatter sci_reliant_ratio_grtyr year_lbl if ep2010, ///
        yaxis(2) msymbol(none) ///
        mlabel(pct_label) mlabposition(6) mlabgap(1) mlabsize(medsmall) ///
        mlabcolor(ebblue*1.5)) || ///
    /* Right axis (share): 2022 endpoint label */ ///
    (scatter sci_reliant_ratio_grtyr year_lbl if ep2022, ///
        yaxis(2) msymbol(none) ///
        mlabel(pct_label) mlabposition(6) mlabgap(0) mlabsize(medsmall) ///
        mlabcolor(ebblue*1.5)), ///
    ytitle("{bf:Number of science-linked U.S. patents}" ///
           "{bf:filed by U.S. firms}", axis(1) size(medium)) ///
    ytitle("{bf:Share of science-linked U.S. patents}" ///
           "{bf:filed by U.S. firms}", axis(2) size(medium)) ///
    ylabel(20000(20000)80000, axis(1) labsize(medium) format(%9.0f)) ///
    ylabel(0.3 "30%" 0.35 "35%" 0.4 "40%" 0.45 "45%" 0.5 "50%", ///
           axis(2) labsize(medsmall)) ///
    xtitle("{bf:Patent grant year}", size(medium) placement(east)) ///
    xlabel(2010(1)2022, angle(45) labsize(medsmall)) ///
    legend(order(1 "Number (left)" 4 "Ratio (right)") ///legend(off)
           size(medium) position(11) ring(0) row(1)) graphregion(margin(vsmall)) 

graph save ${figure_output}time_trend_USfirm_USPTO.gph, replace		


erase ${temp_output}temp1.dta
erase ${temp_output}temp2.dta
