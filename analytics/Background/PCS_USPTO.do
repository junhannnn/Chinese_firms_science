/*******************************************************************************
Project: Background figures
Script:  PCS_USPTO.do

Purpose:
  Create a grant-year figure for U.S. patents filed by Chinese firms. The
  figure reports the annual number of patents linked to scientific papers and
  their share of all U.S. patents filed by Chinese firms for 2010-2022.

Main inputs:
  - ${PCS}_pcs_oa.csv (patent-to-paper citation links)
  - ${stata_output}USpatents_filedby_CNfirms.dta (filing-firm classification)
  - ${USpatents_stata}USpatents_appyr.dta (application years)
  - ${USpatents_stata}USpatents_grtyr.dta (grant years)

Intermediate file:
  ${temp_output}temp_plot.dta (created during processing and removed at the end)

Main output:
  ${figure_output}time_trend_CNfirm_USPTO.gph

Required setup:
  00_run_all.do defines PCS, stata_output, USpatents_stata, temp_output, and
  figure_output before calling this file.
*******************************************************************************/

* ==============================================================================
* 1. Assemble the U.S. patent-level analysis file
* ==============================================================================

* Import patent-to-paper citation links and retain U.S. patents.
import delimited ${PCS}_pcs_oa.csv, clear
gen pat_country = substr(patent, 1, 2)
keep if pat_country == "us"
gen patent_id = regexs(1) if regexm(patent, "-([0-9]+)-")

keep patent_id
duplicates drop
gen cite_science = 1

* Merge filing-firm classifications and retain patents filed by Chinese firms.
merge m:1 patent_id using ${stata_output}USpatents_filedby_CNfirms.dta // Match codes distinguish citation-only records, firm-only records, and matched records.
drop if _merge == 1
drop _merge
replace cite_science = 0 if cite_science == .

* Attach application years; exclude year records not present in the patent sample.
merge m:1 patent_id using ${USpatents_stata}USpatents_appyr.dta
drop if _merge == 2
drop _merge

* Attach grant years; exclude year records not present in the patent sample.
merge m:1 patent_id using ${USpatents_stata}USpatents_grtyr.dta
drop if _merge == 2
drop _merge

* Save the assembled patent-level data for both annual aggregations below.
save ${temp_output}temp_plot.dta, replace

* ==============================================================================
* 2. Construct application-year and grant-year series
* ==============================================================================

* Aggregate patent counts and science-linked shares by application year.
use ${temp_output}temp_plot.dta, clear
rename appyr year

bys year: gen patent_appyr = _N
bys year: egen sci_reliant_patent_appyr = sum(cite_science)

keep year sci_reliant_patent_appyr patent_appyr
duplicates drop
gen sci_reliant_ratio_appyr = sci_reliant_patent_appyr / patent_appyr
keep if year >= 2000 & year <= 2022

tempfile data1
save `data1'

* Aggregate patent counts and science-linked shares by grant year.
use ${temp_output}temp_plot.dta, clear
rename grtyr year

bys year: gen patent_grtyr = _N
bys year: egen sci_reliant_patent_grtyr = sum(cite_science)

keep year sci_reliant_patent_grtyr patent_grtyr
duplicates drop
gen sci_reliant_ratio_grtyr = sci_reliant_patent_grtyr / patent_grtyr
keep if year >= 2000 & year <= 2022

tempfile data2
save `data2'

* Combine both annual series; the figure below uses the grant-year measures.
use `data1', clear
merge 1:1 year using `data2'

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
        yaxis(1) lwidth(medium) lcolor(red*1.5) lpattern(solid) ///
        msymbol(square) mcolor(red*1.5)) || ///
    (connected sci_reliant_ratio_grtyr year, ///
        yaxis(2) lwidth(medium) lcolor(ebblue*1.5) lpattern(dash) ///
        msymbol(circle) mcolor(ebblue*1.5)) || ///
    /* Left-axis series: 2010 endpoint label */ ///
    (scatter sci_reliant_patent_grtyr year_lbl_2 if ep2010, ///
        yaxis(1) msymbol(none) ///
        mlabel(num_label) mlabposition(6) mlabgap(0) ///
        mlabsize(medium) mlabcolor(red*1.5)) || ///
    /* Left-axis series: 2022 endpoint label */ ///
    (scatter sci_reliant_patent_grtyr year_lbl_2 if ep2022, ///
        yaxis(1) msymbol(none) ///
        mlabel(num_label) mlabposition(9) mlabgap(-1) ///
        mlabsize(medium) mlabcolor(red*1.5)) || ///
    /* Right-axis series: 2010 endpoint label */ ///
    (scatter sci_reliant_ratio_grtyr year_lbl_1 if ep2010, ///
        yaxis(2) msymbol(none) ///
        mlabel(pct_label) mlabposition(6) mlabgap(1) ///
        mlabsize(medium) mlabcolor(ebblue*1.5)) || ///
    /* Right-axis series: 2022 endpoint label */ ///
    (scatter sci_reliant_ratio_grtyr year_lbl_1 if ep2022, ///
        yaxis(2) msymbol(none) ///
        mlabel(pct_label) mlabposition(12) mlabgap(1) ///
        mlabsize(medium) mlabcolor(ebblue*1.5)) ///
    if year >= 2010, ///
    ytitle("{bf:Number of science-linked U.S. patents}" ///
        "{bf:filed by Chinese firms}", axis(1) size(medium)) ///
    ytitle("{bf:Share of science-linked U.S. patents}" ///
        "{bf:filed by Chinese firms}", axis(2) size(medium)) ///
    ylabel(, axis(1) labsize(medsmall) format(%9.0f)) ///
    ylabel(0 0.1 "10%" 0.2 "20%" 0.3 "30%" 0.4 "40%", axis(2) labsize(medsmall)) ///
    xtitle("{bf:Patent grant year}", size(medium) placement(east)) ///
    xlabel(2010(1)2022, angle(45) labsize(medsmall)) ///
	legend(order(1 "Number (left)" 4 "Ratio (right)") size(medium) position(11) ring(0) row(1)) /// legend(off) 
    graphregion(margin(vsmall))

* ==============================================================================
* 5. Save the graph and remove the intermediate file
* ==============================================================================

graph save ${figure_output}time_trend_CNfirm_USPTO.gph, replace

* Delete the on-disk intermediate; Stata-managed tempfiles are removed automatically.
erase ${temp_output}temp_plot.dta
