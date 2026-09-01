/*
Public-release script
---------------------------------
Purpose:
Generate the figure plot for science-reliant Chinese patents filed by
Chinese firms (grant-year series, 2010-2022).

Main input:
${stata_output}Chinese_patents_filed_by_EL_otherfirms.dta

Main output:
${figure_output}fig1a_CNfirm_CNpat.gph
*/

********************************************************************************
*********************** CN Patents Filed by Chinese Firms **********************
********************************************************************************

* Load Chinese patents filed by Chinese firms and prepare grant-year metrics.
use ${stata_output}Chinese_patents_filed_by_EL_otherfirms.dta, clear
rename grtyr year

bys year: gen patent_grtyr = _N
bys year: egen sci_reliant_patent_grtyr = sum(cite_science)

* Count unique firms in each year.
bys year (fapp_standard): gen firm_tag = fapp_standard
bys year: egen unique_firm_yr = total(firm_tag != firm_tag[_n-1])

* Count unique firms with at least one science-reliant patent in each year.
bysort year fapp_standard: egen has_citesci = max(cite_science)
bysort year fapp_standard: gen tag = has_citesci if _n == 1   // 1 = firm cited science in that year
bysort year: egen unique_citesci_firm_yr = total(tag)

keep year sci_reliant_patent_grtyr unique_firm_yr unique_citesci_firm_yr patent_grtyr
duplicates drop

gen sci_reliant_ratio_grtyr = sci_reliant_patent_grtyr / patent_grtyr

gen sci_reliant_patent_grtyr_adj1 = sci_reliant_patent_grtyr / unique_firm_yr
gen sci_reliant_patent_grtyr_adj2 = sci_reliant_patent_grtyr / unique_citesci_firm_yr

keep if year >= 2010 & year <= 2022

* Endpoint indicators (plotted separately for custom labels).
gen byte ep2010 = (year == 2010)
gen byte ep2022 = (year == 2022)

* Endpoint label strings.
gen str num_label = string(sci_reliant_patent_grtyr, "%9.0fc")
gen str pct_label = string(sci_reliant_ratio_grtyr * 100, "%9.2f") + "%"

* Slight x-axis adjustments for endpoint labels.
gen double year_lbl_1 = year
replace year_lbl_1 = year + 0.50 if year == 2010
replace year_lbl_1 = year - 0.50 if year == 2022

gen double year_lbl_2 = year
replace year_lbl_2 = year + 0.20 if year == 2010
replace year_lbl_2 = year - 0.20 if year == 2022

* Plot two series and add endpoint labels as separate scatter layers.
twoway ///
    (connected sci_reliant_patent_grtyr year, ///
        yaxis(1) lwidth(medium) lcolor(red*1.4) lpattern(solid) ///
        msymbol(square) mcolor(red*1.5)) || ///
    (connected sci_reliant_ratio_grtyr year, ///
        yaxis(2) lwidth(medium) lcolor(ebblue*1.2) lpattern(dash) ///
        msymbol(circle) mcolor(ebblue*1.5)) || ///
    /* Left axis: 2010 endpoint label */ ///
    (scatter sci_reliant_patent_grtyr year_lbl_1 if ep2010, ///
        yaxis(1) msymbol(none) ///
        mlabel(num_label) mlabposition(6) mlabgap(0) ///
        mlabsize(medium) mlabcolor(red*1.5)) || ///
    /* Left axis: 2022 endpoint label */ ///
    (scatter sci_reliant_patent_grtyr year_lbl_2 if ep2022, ///
        yaxis(1) msymbol(none) ///
        mlabel(num_label) mlabposition(11) mlabgap(-1) ///
        mlabsize(medium) mlabcolor(red*1.5)) || ///
    /* Right axis: 2010 endpoint label */ ///
    (scatter sci_reliant_ratio_grtyr year_lbl_1 if ep2010, ///
        yaxis(2) msymbol(none) ///
        mlabel(pct_label) mlabposition(6) mlabgap(1) ///
        mlabsize(medium) mlabcolor(ebblue*1.5)) || ///
    /* Right axis: 2022 endpoint label */ ///
    (scatter sci_reliant_ratio_grtyr year_lbl_1 if ep2022, ///
        yaxis(2) msymbol(none) ///
        mlabel(pct_label) mlabposition(12) mlabgap(1) ///
        mlabsize(medium) mlabcolor(ebblue*1.5)), ///
    ytitle("{bf:Number of science-linked Chinese patents}" ///
        "{bf:filed by Chinese firms}", axis(1) size(medium)) ///
    ytitle("{bf:Share of science-linked Chinese patents}" ///
        "{bf:filed by Chinese firms}", axis(2) size(medium)) ///
    ylabel(, axis(1) labsize(medsmall) format(%9.0f)) ///
    ylabel(0 0.1 "10%" 0.2 "20%" 0.3 "30%" 0.4 "40%", ///
        axis(2) labsize(medsmall)) ///
    xtitle("{bf:Patent grant year}", size(medium) placement(east)) ///
    xlabel(2010(1)2022, angle(45) labsize(medsmall)) ///
	legend(order(1 "Number (left)" 4 "Ratio (right)") size(medium) position(11) ring(0) row(1)) /// legend(off)
    graphregion(margin(vsmall))

* Save graph in Stata `.gph` format.
graph save ${figure_output}time_trend_CNfirm_CNIPA.gph, replace
