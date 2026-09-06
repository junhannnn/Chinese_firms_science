/*******************************************************************************
Project: Background figures
Script:  PCS_CNIPA.do

Purpose:
  Create a 2010-2022 grant-year figure for Chinese patents filed by Chinese
  firms. The figure reports the annual number of patents linked to scientific
  papers and their share of all patents in the analysis sample.

Main input:
  ${stata_output}Chinese_patents_filed_by_EL_otherfirms.dta

Main output:
  ${figure_output}time_trend_CNfirm_CNIPA.gph

Required setup:
  00_run_all.do defines stata_output and figure_output before calling this file.
*******************************************************************************/

* ==============================================================================
* 1. Load the Chinese patent-level data
* ==============================================================================

use ${stata_output}Chinese_patents_filed_by_EL_otherfirms.dta, clear
rename grtyr year

* ==============================================================================
* 2. Construct annual patent measures
* ==============================================================================

* Count all patents and science-linked patents within each grant year.
bys year: gen patent_grtyr = _N
bys year: egen sci_reliant_patent_grtyr = sum(cite_science)

* Count distinct filing firms within each grant year.
bys year (fapp_standard): gen firm_tag = fapp_standard
bys year: egen unique_firm_yr = total(firm_tag != firm_tag[_n-1])

* Count distinct firms with at least one science-linked patent in each year.
bysort year fapp_standard: egen has_citesci = max(cite_science)
bysort year fapp_standard: gen tag = has_citesci if _n == 1   // Marks one firm-year record; its value indicates any science link.
bysort year: egen unique_citesci_firm_yr = total(tag)

* Collapse to one record per year before deriving shares and per-firm averages.
keep year sci_reliant_patent_grtyr unique_firm_yr unique_citesci_firm_yr patent_grtyr
duplicates drop

gen sci_reliant_ratio_grtyr = sci_reliant_patent_grtyr / patent_grtyr

gen sci_reliant_patent_grtyr_adj1 = sci_reliant_patent_grtyr / unique_firm_yr
gen sci_reliant_patent_grtyr_adj2 = sci_reliant_patent_grtyr / unique_citesci_firm_yr

keep if year >= 2010 & year <= 2022

* ==============================================================================
* 3. Prepare endpoint labels for the figure
* ==============================================================================

* Create separate endpoint indicators so labels can be positioned independently.
gen byte ep2010 = (year == 2010)
gen byte ep2022 = (year == 2022)

* Format labels for the count and share series.
gen str num_label = string(sci_reliant_patent_grtyr, "%9.0fc")
gen str pct_label = string(sci_reliant_ratio_grtyr * 100, "%9.2f") + "%"

* Shift label coordinates slightly inward to reduce overlap at plot boundaries.
gen double year_lbl_1 = year
replace year_lbl_1 = year + 0.50 if year == 2010
replace year_lbl_1 = year - 0.50 if year == 2022

gen double year_lbl_2 = year
replace year_lbl_2 = year + 0.20 if year == 2010
replace year_lbl_2 = year - 0.20 if year == 2022

* ==============================================================================
* 4. Plot annual patent trends
* ==============================================================================

* Draw count and share series; marker-only layers supply the endpoint labels.
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

* ==============================================================================
* 5. Save the graph
* ==============================================================================

graph save ${figure_output}time_trend_CNfirm_CNIPA.gph, replace
