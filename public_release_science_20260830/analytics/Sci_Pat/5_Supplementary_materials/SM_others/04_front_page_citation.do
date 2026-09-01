/*******************************************************************************
Project: Background Supplementary Materials (SM04)
Script: SM_others/04_front_page_citation.do

Purpose
  - Recompute science-reliance trends using front-page-only citation definitions.
  - Re-plot three patent groups:
    (1) CN patents filed by CN firms,
    (2) US patents filed by CN firms,
    (3) US patents filed by US firms.

Main Inputs
  - ${stata_output}CNpatents_reliance_frontonly_science.dta
  - ${stata_output}Chinese_patents_whether_cite_science_basednation.dta
  - ${stata_output}USpatents_filedby_CNfirms.dta
  - ${USpatents_stata}USpatent_type_onlyUS.dta
  - ${USpatents_stata}USpatents_grtyr.dta
  - ${PCS}_pcs_oa.csv

Outputs
  - Figure: ${figure_output}front_page_CNfirm_CNIPA.gph
  - Figure: ${figure_output}front_page_CNfirm_USPTO.gph
  - Figure: ${figure_output}front_page_USfirm_USPTO.gph
  - Intermediate datasets:
    ${stata_output}USpatents_reliance_science_CNfirmfront.dta
    ${stata_output}USpatents_reliance_science_USfirmfront.dta
  - Temp files are removed at the end of each block.

Dependencies
  - Expected to be called by SM_others/00_run_all.do, which defines all globals.
  - If run standalone, define required globals before execution.
*******************************************************************************/

********************************************************************************
******************** Use front-page citations to re-plot ***********************
********************************************************************************

********************************************************************************
*************************** CN patents filed by CN firms ***********************
********************************************************************************
use ${stata_output}CNpatents_reliance_frontonly_science.dta, clear

bys patent_id: gen cite_paper_num = _N
keep patent_id cite_paper_num

rename patent_id apn
duplicates drop
save ${temp_output}merge_frontonly_science.dta, replace //var: apn cite_paper_num



use ${stata_output}Chinese_patents_whether_cite_science_basednation.dta, clear

merge 1:1 apn using ${temp_output}merge_frontonly_science.dta
replace cite_science=0 if _merge==1 & cite_science==1
drop _merge

rename grtyr year
keep if type==1 // filed by firm
bys year: gen patent_grtyr = _N
bys year: egen sci_reliant_patent_grtyr = sum(cite_science)

* Number of firms each year
bys year (fapp): gen firm_tag = fapp
bys year: egen unique_firm_yr = total(firm_tag != firm_tag[_n-1])

* Number of firms with science-reliant patents each year
bysort year fapp: egen has_citesci = max(cite_science)
bysort year fapp: gen tag = has_citesci if _n == 1
bysort year: egen unique_citesci_firm_yr = total(tag)

keep year sci_reliant_patent_grtyr unique_firm_yr unique_citesci_firm_yr patent_grtyr
duplicates drop

gen sci_reliant_ratio_grtyr = sci_reliant_patent_grtyr / patent_grtyr

gen sci_reliant_patent_grtyr_adj1 = sci_reliant_patent_grtyr / unique_firm_yr
gen sci_reliant_patent_grtyr_adj2 = sci_reliant_patent_grtyr / unique_citesci_firm_yr

keep if year>=2010 & year<=2022


twoway (connected sci_reliant_patent_grtyr year, yaxis(1) lwidth(medium) lcolor(red*1.4) lpattern(solid) msymbol(square) mcolor(red*1.4)) || ///
       (connected sci_reliant_ratio_grtyr year, yaxis(2) lwidth(medium) lcolor(ebblue*1.2) lpattern(dash) msymbol(circle) mcolor(ebblue*1.2)), ///
    ytitle("{bf:Number of science-reliant Chinese patents}" /// 
	"{bf:filed by Chinese firms}", axis(1) size(small)) ///
    ytitle("{bf:Share of science-reliant Chinese patents}" ///
	"{bf:filed by Chinese firms}", axis(2) size(small)) ///
    ylabel(, axis(1) labsize(small) format(%9.0f)) ///
    ylabel(0 0.1 "10%" 0.2 "20%" 0.3 "30%" 0.4 "40%", axis(2) labsize(small)) ///
    xtitle("{bf:Patent grant year}", size(small) placement(east)) ///
    xlabel(2010(1)2022, angle(45) labsize(small)) ///
    legend(order(1 "Number (left)" 2 "Ratio (right)") ///
           size(medsmall) position(11) ring(0) row(1)) ///
	graphregion(margin(vsmall)) aspectratio(0.8) 

graph save ${figure_output}front_page_CNfirm_CNIPA.gph, replace

erase ${temp_output}merge_frontonly_science.dta


********************************************************************************
*************************** US patents filed by CN firms ***********************
********************************************************************************
use ${stata_output}USpatents_filedby_CNfirms.dta, clear
keep patent_id country
duplicates drop
save ${temp_output}temp_CNfirm.dta, replace


import delimited ${PCS}_pcs_oa.csv, clear 

keep if uspto==1

keep patent oaid wherefound
duplicates drop

order patent oaid
sort patent oaid

gen patent_id = ""
replace patent_id = ustrregexs(1) if ustrregexm(patent, "^[^-]+-([^-]+)-") 
sort patent_id
keep patent_id oaid wherefound
duplicates drop
order patent_id oaid wherefound

save ${temp_output}temp1.dta, replace


use ${temp_output}temp1.dta, clear
merge m:1 patent_id using ${temp_output}temp_CNfirm.dta
keep if _merge==3
drop _merge

tab wherefound // Based on the Reliance on Science database

keep if wherefound=="frontonly"

keep patent_id wherefound
duplicates drop
save ${stata_output}USpatents_reliance_science_CNfirmfront.dta, replace




import delimited ${PCS}_pcs_oa.csv, clear
gen pat_country = substr(patent, 1, 2)
keep if pat_country == "us"
gen patent_id = regexs(1) if regexm(patent, "-([0-9]+)-")

keep patent_id
duplicates drop
gen cite_science=1


* (1) merge type
merge m:1 patent_id using ${stata_output}USpatents_filedby_CNfirms.dta //_merge==1: US patents citing scientific papers but not filed by CN firms, _merge==2: US patents filed by CN firms but not citing scientific papers, _merge==3: US patents filed by CN firms and citing scientific papers
drop if _merge==1
drop _merge
replace cite_science=0 if cite_science==.

* (2) Merge front-page indicator
merge m:1 patent_id using ${stata_output}USpatents_reliance_science_CNfirmfront.dta
replace cite_science=0 if _merge==1 & cite_science==1
drop _merge

* (3) merge grant year
merge m:1 patent_id using ${USpatents_stata}USpatents_grtyr.dta
drop if _merge==2
drop _merge

rename grtyr year

bys year: gen patent_grtyr = _N
bys year: egen sci_reliant_patent_grtyr = sum(cite_science)

keep year sci_reliant_patent_grtyr patent_grtyr
duplicates drop
gen sci_reliant_ratio_grtyr = sci_reliant_patent_grtyr / patent_grtyr
keep if year>=2010 & year<=2022



twoway (connected sci_reliant_patent_grtyr year, yaxis(1) lwidth(medium) lcolor(red*1.4) lpattern(solid) msymbol(square) mcolor(red*1.4)) || ///
       (connected sci_reliant_ratio_grtyr year, yaxis(2) lwidth(medium) lcolor(ebblue*1.2) lpattern(dash) msymbol(circle) mcolor(ebblue*1.2)), ///
    ytitle("{bf:Number of science-reliant U.S. patents}" /// 
	"{bf:filed by Chinese firms}", axis(1) size(small)) ///
    ytitle("{bf:Share of science-reliant U.S. patents}" ///
	"{bf:filed by Chinese firms}", axis(2) size(small)) ///
    ylabel(0(1000)6000, axis(1) labsize(small) format(%9.0f)) ///
    ylabel(0 0.05 "5%" 0.1 "10%" 0.15 "15%" 0.2 "20%" 0.25 "25%" 0.3 "30%", axis(2) labsize(small)) ///
    xtitle("{bf:Patent grant year}", size(small) placement(east)) ///
    xlabel(2010(1)2022, angle(45) labsize(small)) ///
    legend(order(1 "Number (left)" 2 "Ratio (right)") ///
           size(medsmall) position(11) ring(0) row(1)) ///
	graphregion(margin(vsmall)) aspectratio(0.8) 

graph save ${figure_output}front_page_CNfirm_USPTO.gph, replace

list sci_reliant_patent_grtyr sci_reliant_ratio_grtyr ///
    if inlist(year, 2010, 2022)
	
erase ${temp_output}temp_CNfirm.dta
erase ${temp_output}temp1.dta


********************************************************************************
*************************** US patents filed by US firms ***********************
********************************************************************************

import delimited ${PCS}_pcs_oa.csv, clear 

keep if uspto==1

keep patent oaid wherefound
duplicates drop

order patent oaid
sort patent oaid

gen patent_id = ""
replace patent_id = ustrregexs(1) if ustrregexm(patent, "^[^-]+-([^-]+)-") 
sort patent_id
keep patent_id oaid wherefound
duplicates drop
order patent_id oaid wherefound

tab wherefound // Based on the Reliance on Science database

keep if wherefound=="frontonly"

keep patent_id wherefound
duplicates drop
save ${stata_output}USpatents_reliance_science_USfirmfront.dta, replace



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


* (2) merge grant year
merge m:1 patent_id using ${USpatents_stata}USpatents_grtyr.dta
drop if _merge==2
drop _merge

keep if type==2 //US firms

* (3) Merge front-page indicator
merge m:1 patent_id using ${stata_output}USpatents_reliance_science_USfirmfront.dta
drop if _merge==2
replace cite_science=0 if _merge==1 & cite_science==1
drop _merge

rename grtyr year

bys year: gen patent_grtyr = _N
bys year: egen sci_reliant_patent_grtyr = sum(cite_science)


keep year sci_reliant_patent_grtyr patent_grtyr 
duplicates drop

gen sci_reliant_ratio_grtyr = sci_reliant_patent_grtyr / patent_grtyr


keep if year>=2010 & year<=2022


		
twoway (connected sci_reliant_patent_grtyr year, yaxis(1) lwidth(medium) lcolor(red*1.4) lpattern(solid) msymbol(square) mcolor(red*1.4)) || ///
       (connected sci_reliant_ratio_grtyr year, yaxis(2) lwidth(medium) lcolor(ebblue*1.2) lpattern(dash) msymbol(circle) mcolor(ebblue*1.2)), ///
    ytitle("{bf:Number of science-reliant U.S. patents}" /// 
	"{bf:filed by U.S. firms}", axis(1) size(small)) ///
    ytitle("{bf:Share of science-reliant U.S. patents}" ///
	"{bf:filed by U.S. firms}", axis(2) size(small)) ///
    ylabel(20000(10000)80000, axis(1) labsize(small) format(%9.0f)) ///
    ylabel(0.3 "30%" 0.35 "35%" 0.4 "40%" 0.45 "45%" 0.5 "50%", axis(2) labsize(small)) ///
    xtitle("{bf:Patent grant year}", size(small) placement(east)) ///
    xlabel(2010(1)2022, angle(45) labsize(small)) ///
    legend(order(1 "Number (left)" 2 "Ratio (right)") ///
           size(medsmall) position(11) ring(0) row(1)) graphregion(margin(vsmall)) aspectratio(0.8) 
		
graph save ${figure_output}front_page_USfirm_USPTO.gph, replace

list sci_reliant_patent_grtyr sci_reliant_ratio_grtyr ///
    if inlist(year, 2010, 2022)
