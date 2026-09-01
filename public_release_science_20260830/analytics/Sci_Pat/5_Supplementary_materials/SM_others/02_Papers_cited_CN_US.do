/*******************************************************************************
Project: Background Supplementary Materials (SM02)
Script: SM_others/02_Papers_cited_CN_US.do

Purpose
  - Compute and compare the average number of cited scientific papers per
    science-reliant patent across three groups:
    (1) CN patents filed by CN firms,
    (2) US patents filed by US firms,
    (3) US patents filed by CN firms.
  - Produce results for both all citations and front-page-only citations.

Main Inputs
  - ${stata_output}CNpatents_reliance_science.dta
  - ${stata_output}USpatents_filedby_CNfirms.dta
  - ${USpatents_stata}USpatent_type_onlyUS.dta
  - ${USpatents_stata}USpatents_grtyr.dta
  - ${PCS}_pcs_oa.csv

Outputs
  - Figure (all citations): ${figure_output}ave_paper_cited_CN_US.gph
  - Figure (front-page only): ${figure_output}ave_paper_cited_CN_US_frontpage.gph
  - Intermediate dataset:
    ${stata_output}CNpatents_reliance_frontonly_science.dta
  - Temp files are removed at the end of each block.

Dependencies
  - Expected to be called by SM_others/00_run_all.do, which defines all globals.
  - If run standalone, define required globals before execution.
*******************************************************************************/

********************************************************************************
****************************** Other calculation (all) *************************
********************************************************************************

// 1. Average number of scientific publications cited by Chinese patents that cite science (2022)

use ${stata_output}CNpatents_reliance_science.dta, clear

rename grtyr year
keep if year>=2010 & year<=2022
keep if type==1 // filed by firm

bys patent_id: gen cite_paper_num = _N
keep patent_id year cite_paper_num
duplicates drop


* all years
qui sum cite_paper_num
local mean_cite_allyr1: display %9.2f r(mean)
display `mean_cite_allyr1' //2.01

* annual
bys year: egen paper_cited_yr = mean(cite_paper_num)
keep year paper_cited_yr
duplicates drop

rename paper_cited_yr paper_cited1
save ${temp_output}paper_cited1.dta, replace


// 2. Average number of scientific publications cited by USPTO patents filed by U.S. firms that cite science (2022)

import delimited ${PCS}_pcs_oa.csv, clear
gen pat_country = substr(patent, 1, 2)
keep if pat_country == "us"
gen patent_id = regexs(1) if regexm(patent, "-([0-9]+)-")

merge m:1 patent_id using ${USpatents_stata}USpatents_grtyr.dta
drop if _merge==2
drop _merge

rename grtyr year
keep if year>=2010 & year<=2022
save ${temp_output}temp_us.dta, replace


use ${temp_output}temp_us.dta, clear

merge m:1 patent_id using ${USpatents_stata}USpatent_type_onlyUS.dta //US patents filed by US entities
keep if _merge==3
drop _merge
keep if type==2 //US patents filed US firms

keep patent_id year oaid
duplicates drop

bys patent_id: gen cite_paper_num = _N
keep patent_id cite_paper_num year
duplicates drop

* all years
qui sum cite_paper_num
local mean_cite_allyr2: display %9.2f r(mean)
display `mean_cite_allyr2' //17.47

* annual
bys year: egen paper_cited_yr = mean(cite_paper_num)
keep year paper_cited_yr
duplicates drop

rename paper_cited_yr paper_cited2
save ${temp_output}paper_cited2.dta, replace


// 3. Average number of scientific publications cited by USPTO patents filed by Chinese firms that cite science (2022)

use ${temp_output}temp_us.dta, clear

merge m:1 patent_id using ${stata_output}USpatents_filedby_CNfirms.dta
keep if _merge==3
drop _merge

keep patent_id year oaid
duplicates drop

bys patent_id: gen cite_paper_num = _N
keep patent_id cite_paper_num year
duplicates drop

* all years
qui sum cite_paper_num
local mean_cite_allyr3: display %9.2f r(mean)
display `mean_cite_allyr3' //5.22

* annual
bys year: egen paper_cited_yr = mean(cite_paper_num)
keep year paper_cited_yr
duplicates drop

rename paper_cited_yr paper_cited3
save ${temp_output}paper_cited3.dta, replace


// 4. Merge and plot
use ${temp_output}paper_cited1.dta, clear
merge 1:1 year using ${temp_output}paper_cited2.dta
drop _merge
merge 1:1 year using ${temp_output}paper_cited3.dta
drop _merge


twoway ///
    (connected paper_cited1 year, sort lwidth(medium) lcolor(red*1.5) lpattern(solid) msymbol(square) mcolor(red*1.5)) ///
    (connected paper_cited2 year, sort lwidth(medium) lcolor(ebblue*1.5) lpattern(dash) msymbol(circle) mcolor(ebblue*1.5)) ///
    (connected paper_cited3 year, sort lwidth(medium) lcolor(green*1) lpattern(dash) msymbol(triangle) mcolor(green*1)), ///
    xlabel(2010(1)2022, angle(45) labsize(medsmall)) ///
    xtitle("{bf:Patent grant year}", size(medsmall) placement(east)) ///
    ytitle("{bf:Average scientific publication references}""{bf:per science-linked patent}", size(medsmall)) ///
    legend( ///
      label(1 "CN patents filed by CN firms (overall: 2.01)")  ///  
      label(2 "US patents filed by US firms (overall: 17.47)")  ///  
      label(3 "US patents filed by CN firms (overall: 5.22)")  ///
      cols(1) ring(0) pos(9)) ///
	  aspectratio(0.7) graphregion(margin(vsmall)) 
	  
gr_edit .legend.DragBy 9 0

graph save ${figure_output}ave_paper_cited_CN_US.gph, replace

erase ${temp_output}paper_cited1.dta
erase ${temp_output}paper_cited2.dta
erase ${temp_output}paper_cited3.dta
erase ${temp_output}temp_us.dta


********************************************************************************
****************************** Other calculation (front-page only) *************
********************************************************************************

import delimited ${PCS}_pcs_oa.csv, clear 
keep if substr(patent,1,2) == "cn"
gen patent_id = ""
replace patent_id = ustrregexs(1) if ustrregexm(patent, "^[^-]+-([^-]+)-") 
keep patent_id oaid wherefound
duplicates drop
order patent_id oaid wherefound
sort patent_id

rename patent_id pub_id

bysort pub_id oaid (wherefound): gen tag = _N
replace wherefound = "both" if tag > 1
drop tag
duplicates drop

save ${temp_output}temp.dta, replace


use ${stata_output}CNpatents_reliance_science.dta, clear
rename paperid oaid
merge m:1 pub_id oaid using ${temp_output}temp.dta
drop if _merge==2
drop _merge

order patent_id pub_id oaid paperyear source wherefound
replace wherefound="frontonly" if source=="IncoPat"

keep if wherefound=="bodyonly" | wherefound=="both"

keep patent_id oaid wherefound
duplicates drop
rename oaid paperid
save ${temp_output}CNpatents_reliance_science_bodyonly.dta, replace //var: patent_id paperid wherefound


use ${stata_output}CNpatents_reliance_science.dta, clear
merge m:1 patent_id paperid using ${temp_output}CNpatents_reliance_science_bodyonly.dta
drop if _merge==3 // Matched records are body-only citations and should be excluded
drop _merge
save ${stata_output}CNpatents_reliance_frontonly_science.dta, replace


erase ${temp_output}temp.dta
erase ${temp_output}CNpatents_reliance_science_bodyonly.dta


// 1. Average number of scientific publications cited by Chinese patents that cite science

use ${stata_output}CNpatents_reliance_frontonly_science.dta, clear

rename grtyr year
keep if year>=2010 & year<=2022
keep if type==1 // filed by firm

bys patent_id: gen cite_paper_num = _N
keep patent_id year cite_paper_num
duplicates drop


* all years
qui sum cite_paper_num
local mean_cite_allyr1: display %9.2f r(mean)
display `mean_cite_allyr1' //2.01

* annual
bys year: egen paper_cited_yr = mean(cite_paper_num)
keep year paper_cited_yr
duplicates drop

rename paper_cited_yr paper_cited1
save ${temp_output}paper_cited1.dta, replace


// 2. Average number of scientific publications cited by USPTO patents filed by U.S. firms that cite science

import delimited ${PCS}_pcs_oa.csv, clear
gen pat_country = substr(patent, 1, 2)
keep if pat_country == "us"
gen patent_id = regexs(1) if regexm(patent, "-([0-9]+)-")

keep if wherefound=="frontonly"

merge m:1 patent_id using ${USpatents_stata}USpatents_grtyr.dta
drop if _merge==2
drop _merge

rename grtyr year
keep if year>=2010 & year<=2022
save ${temp_output}temp_us.dta, replace


use ${temp_output}temp_us.dta, clear

merge m:1 patent_id using ${USpatents_stata}USpatent_type_onlyUS.dta //US patents filed by US entities
keep if _merge==3
drop _merge
keep if type==2 //US patents filed US firms

keep patent_id year oaid
duplicates drop

bys patent_id: gen cite_paper_num = _N
keep patent_id cite_paper_num year
duplicates drop

* all years
qui sum cite_paper_num
local mean_cite_allyr2: display %9.2f r(mean)
display `mean_cite_allyr2' //13.60

* annual
bys year: egen paper_cited_yr = mean(cite_paper_num)
keep year paper_cited_yr
duplicates drop

rename paper_cited_yr paper_cited2
save ${temp_output}paper_cited2.dta, replace


// 3. Average number of scientific publications cited by USPTO patents filed by Chinese firms that cite science

use ${temp_output}temp_us.dta, clear

merge m:1 patent_id using ${stata_output}USpatents_filedby_CNfirms.dta
keep if _merge==3
drop _merge

keep patent_id year oaid
duplicates drop

bys patent_id: gen cite_paper_num = _N
keep patent_id cite_paper_num year
duplicates drop

* all years
qui sum cite_paper_num
local mean_cite_allyr3: display %9.2f r(mean)
display `mean_cite_allyr3' //4.08

* annual
bys year: egen paper_cited_yr = mean(cite_paper_num)
keep year paper_cited_yr
duplicates drop

rename paper_cited_yr paper_cited3
save ${temp_output}paper_cited3.dta, replace


// 4. Merge and plot
use ${temp_output}paper_cited1.dta, clear
merge 1:1 year using ${temp_output}paper_cited2.dta
drop _merge
merge 1:1 year using ${temp_output}paper_cited3.dta
drop _merge


twoway ///
    (connected paper_cited1 year, sort lwidth(medium) lcolor(red*1.5) lpattern(solid) msymbol(square) mcolor(red*1.5)) ///
    (connected paper_cited2 year, sort lwidth(medium) lcolor(ebblue*1.5) lpattern(dash) msymbol(circle) mcolor(ebblue*1.5)) ///
    (connected paper_cited3 year, sort lwidth(medium) lcolor(green*1) lpattern(dash) msymbol(triangle) mcolor(green*1)), ///
    xlabel(2010(1)2022, angle(45) labsize(medsmall)) ///
    xtitle("{bf:Patent grant year}", size(medsmall) placement(east)) ///
    ytitle("{bf:Average scientific publication references}""{bf:per science-linked patent (front-page only)}", size(small)) ///
    legend( ///
      label(1 "CN patents filed by CN firms (overall: 2.01)")  ///  
      label(2 "US patents filed by US firms (overall: 13.60)")  ///  
      label(3 "US patents filed by CN firms (overall: 4.08)")  ///
      cols(1) ring(0) pos(9)) ///
	  aspectratio(0.7) graphregion(margin(vsmall)) 
	  
gr_edit .legend.DragBy 9 0

graph save ${figure_output}ave_paper_cited_CN_US_frontpage.gph, replace

erase ${temp_output}paper_cited1.dta
erase ${temp_output}paper_cited2.dta
erase ${temp_output}paper_cited3.dta
erase ${temp_output}temp_us.dta
