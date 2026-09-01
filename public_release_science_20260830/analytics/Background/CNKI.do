/*
Public-release script
---------------------------------
Purpose:
Generate the figure plot using CNKI firm-year publication data,
including total publications and per-firm publication intensity metrics.

Main input:
${stata_output}CNKI_DID.dta

Main output:
${figure_output}fig1c_CNfirm_CNKI.gph
*/

********************************************************************************
*********************************** CNKI ***************************************
********************************************************************************

* Load firm-year publication panel from CNKI.
use ${stata_output}CNKI_DID.dta, clear

* (1) Aggregate yearly totals.
bys year: egen pub_num_y = sum(pub_num)
bys year: egen f_u_colla_num_y = sum(f_u_colla_num)
bys year: egen pub_num_y_h = sum(pub_num_h)
bys year: egen f_u_colla_num_y_h = sum(f_u_colla_num_h)

* (2) Count unique firms in each year.
bys year (firm_id): gen firm_tag = firm_id
bys year: egen unique_firm_yr = total(firm_tag != firm_tag[_n-1])

keep pub_num_y f_u_colla_num_y year pub_num_y_h f_u_colla_num_y_h unique_firm_yr
duplicates drop

gen pub_num_y_adj = pub_num_y / unique_firm_yr
gen f_u_colla_num_y_adj = f_u_colla_num_y / unique_firm_yr
gen pub_num_y_adj_h = pub_num_y_h / unique_firm_yr
gen f_u_colla_num_y_adj_h = f_u_colla_num_y_h / unique_firm_yr

keep if year >= 2010 & year <= 2022

gen colla = f_u_colla_num_y / pub_num_y * 100

* Endpoint indicators (split for separate label placement).
gen byte ep2010 = (year == 2010)
gen byte ep2022 = (year == 2022)

* Endpoint label strings.
gen str pub_label = string(pub_num_y, "%9.0fc")
gen str pub_adj_label = string(pub_num_y_adj, "%9.2f")
gen str pub_adjh_label = string(pub_num_y_adj_h, "%9.2f")

* Slight x-axis adjustments for endpoint labels.
gen double year_lbl_1 = year
replace year_lbl_1 = year + 0.3 if year == 2010
replace year_lbl_1 = year - 0.3 if year == 2022

gen double year_lbl_2 = year
replace year_lbl_2 = year + 0.5 if year == 2010
replace year_lbl_2 = year - 0.5 if year == 2022

* Plot three series and add endpoint labels as separate scatter layers.
twoway ///
    (connected pub_num_y year, yaxis(1) lwidth(medium) lcolor(red*1.5) ///
        lpattern(dash) msymbol(diamond) mcolor(red*1.5)) || ///
    (connected pub_num_y_adj year, yaxis(2) lwidth(medium) lcolor(ebblue*1.5) ///
        lpattern(solid) msymbol(square) mcolor(ebblue*1.5)) || ///
    (connected pub_num_y_adj_h year, yaxis(2) lwidth(medium) lcolor(green*1) ///
        lpattern(shortdash) msymbol(triangle) mcolor(green*1)) || ///
    /* Left axis (pub_num_y): 2010 endpoint label */ ///
    (scatter pub_num_y year_lbl_2 if ep2010, yaxis(1) msymbol(none) ///
        mlabel(pub_label) mlabposition(6) mlabgap(0) mlabsize(medium) ///
        mlabcolor(red*1.5)) || ///
    /* Left axis (pub_num_y): 2022 endpoint label */ ///
    (scatter pub_num_y year_lbl_2 if ep2022, yaxis(1) msymbol(none) ///
        mlabel(pub_label) mlabposition(12) mlabgap(1) mlabsize(medium) ///
        mlabcolor(red*1.5)) || ///
    /* Right axis (pub_num_y_adj): 2010 endpoint label */ ///
    (scatter pub_num_y_adj year_lbl_1 if ep2010, yaxis(2) msymbol(none) ///
        mlabel(pub_adj_label) mlabposition(6) mlabgap(0) mlabsize(medium) ///
        mlabcolor(ebblue*1.5)) || ///
    /* Right axis (pub_num_y_adj): 2022 endpoint label */ ///
    (scatter pub_num_y_adj year_lbl_1 if ep2022, yaxis(2) msymbol(none) ///
        mlabel(pub_adj_label) mlabposition(12) mlabgap(1) mlabsize(medium) ///
        mlabcolor(ebblue*1.5)) || ///
    /* Right axis (pub_num_y_adj_h): 2010 endpoint label */ ///
    (scatter pub_num_y_adj_h year_lbl_1 if ep2010, yaxis(2) msymbol(none) ///
        mlabel(pub_adjh_label) mlabposition(6) mlabgap(0) mlabsize(medium) ///
        mlabcolor(green*1)) || ///
    /* Right axis (pub_num_y_adj_h): 2022 endpoint label */ ///
    (scatter pub_num_y_adj_h year_lbl_1 if ep2022, yaxis(2) msymbol(none) ///
        mlabel(pub_adjh_label) mlabposition(12) mlabgap(1) mlabsize(medium) ///
        mlabcolor(green*1)), ///
    ytitle("{bf:Number of papers published by}" ///
        "{bf:each publishing Chinese firm (CNKI)}", size(medium) axis(2)) ///
    ytitle("{bf:Total number of papers published by}" ///
        "{bf:Chinese firm (CNKI)}", size(medium) axis(1)) ///
    ylabel(0.0(0.1)0.7, labsize(medsmall) format(%9.1f) axis(2)) ///
    ylabel(0(20000)80000, labsize(medsmall) format(%9.0f) axis(1)) ///
    xtitle("{bf:Paper publication year}", size(medium) placement(east)) ///
    xlabel(2010(1)2022, angle(45) labsize(medsmall)) ///
    legend(order(1 "All firms, total papers per year (left)" ///
                 4 "Average papers per firm per year (right)" ///
                 5 "Average high JIF papers per firm per year (right)") ///
           size(medsmall) ring(0) position(11) row(3) ///
           region(fcolor(none) lstyle(none)) rowgap(*1)) /// legend(off) position(6) row(2) rowgap(*0.6) ring(1)
    aspectratio(0.7) ///
    graphregion(margin(vsmall))



* Save graph in Stata `.gph` format.
graph save ${figure_output}time_trend_CNfirm_CNKI.gph, replace
