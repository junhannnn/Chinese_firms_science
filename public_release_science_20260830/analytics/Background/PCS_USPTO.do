/*
Public-release script
---------------------------------
Purpose:
Generate the figure plot for science-reliant U.S. patents filed by
Chinese firms (grant-year series shown in the final figure).

Main inputs:
${PCS}_pcs_oa.csv
${stata_output}USpatents_filedby_CNfirms.dta
${USpatents_stata}USpatents_appyr.dta
${USpatents_stata}USpatents_grtyr.dta

Intermediate file:
${temp_output}temp_plot.dta (created and removed within this script)

Main output:
${figure_output}fig1b_CNfirm_USpat.gph
*/

********************************************************************************
*********************** US Patents Filed by Chinese Firms **********************
********************************************************************************

* Import PCS (patent-paper citations) and keep U.S. patents only.
import delimited ${PCS}_pcs_oa.csv, clear
gen pat_country = substr(patent, 1, 2)
keep if pat_country == "us"
gen patent_id = regexs(1) if regexm(patent, "-([0-9]+)-")

keep patent_id
duplicates drop
gen cite_science = 1

* (1) Merge filing-firm information (identify patents filed by Chinese firms).
merge m:1 patent_id using ${stata_output}USpatents_filedby_CNfirms.dta //_merge==1: US patents citing scientific papers but not filed by CN firms, _merge==2: US patents filed by CN firms but not citing scientific papers, _merge==3: US patents filed by CN firms and citing scientific papers
drop if _merge == 1
drop _merge
replace cite_science = 0 if cite_science == .

* (2) Merge application year.
merge m:1 patent_id using ${USpatents_stata}USpatents_appyr.dta
drop if _merge == 2
drop _merge

* (3) Merge grant year.
merge m:1 patent_id using ${USpatents_stata}USpatents_grtyr.dta
drop if _merge == 2
drop _merge

* Save merged patent-level panel for reuse in year-specific aggregations.
save ${temp_output}temp_plot.dta, replace

* Build application-year series.
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

* Build grant-year series.
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

* Merge application-year and grant-year series (plot uses grant-year metrics).
use `data1', clear
merge 1:1 year using `data2'

* Endpoint indicators (plotted separately for custom labels).
gen byte ep2010 = (year == 2010)
gen byte ep2022 = (year == 2022)

* Endpoint label strings.
gen str num_label = string(sci_reliant_patent_grtyr, "%9.0fc")
gen str pct_label = string(sci_reliant_ratio_grtyr * 100, "%9.2f") + "%"

* Slight x-axis adjustments (avoid overlap with ticks/borders).
gen double year_lbl_1 = year
replace year_lbl_1 = year + 0.50 if year == 2010
replace year_lbl_1 = year - 0.50 if year == 2022

gen double year_lbl_2 = year
replace year_lbl_2 = year + 0.20 if year == 2010
replace year_lbl_2 = year - 0.20 if year == 2022

* Plot two series and add endpoint labels as separate scatter layers.
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

* Save graph in Stata `.gph` format.
graph save ${figure_output}time_trend_CNfirm_USPTO.gph, replace

* Remove temporary file created above.
erase ${temp_output}temp_plot.dta
