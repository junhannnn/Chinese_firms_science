/*******************************************************************************
Project: Robustness Checks - USPTO Patents Filed by Chinese Firms (Main DID)
Script: 05_DID_USPTO.do

Purpose
  - Build a firm-year DID panel from USPTO patent records filed by Chinese
    firms.
  - Merge U.S.-citation reliance measures and construct firm-year outcomes
    (science-reliant patent counts, shares, source splits, and lag measures).
  - Expand to balanced firm-year panels (`tsfill`) and conditionally trim to
    each firm's active patenting window when boundary 3-year blocks are all
    zero-patent years.
  - Generate DID/event-time variables and transformed outcomes used in
    robustness regressions.
  - Estimate baseline DID regressions for science-reliant USPTO patents.
  - Produce a dynamic event-study figure for the USPTO-based sample.

Inputs
  - ${python_output}USpat_citepat_country.csv
  - ${stata_output}US_patents_filed_by_EL_otherCNfirms.dta
  - Upstream fields already merged into the patent-level sample (e.g.,
    science-citation indicators and paper-year metadata)

Outputs (saved under ${stata_output})
  - USpat_citepat_country.dta
  - USpatents_DID_allfirm.dta

Tables (saved under ${table_output})
  - robust_USPTO.rtf

Figures (saved under ${figure_output})
  - robust_USPTO_dynamic.gph

Notes
  - This script depends on upstream USPTO preprocessing/matching steps in this
    subfolder (including `04_Entity_list_match_patent_USPTO.do`).
  - User-written Stata commands required here include `winsor2`, `reghdfe`,
    `ppmlhdfe`, `eventdd`, and `esttab`.
*******************************************************************************/
* Run via `00_run_all_6.do` (depends on shared path globals set by the runner).

/*
Key outputs in this script:
  - ${stata_output}USpatents_DID_allfirm.dta
  - ${table_output}robust_USPTO.rtf
  - ${figure_output}robust_USPTO_dynamic.gph
  - Console check: pre-treatment mean for treated observations is displayed
*/

********************************************************************************
******************* A. Build Firm-Year Panel From USPTO Patents ****************
********************************************************************************
import delimited ${python_output}USpat_citepat_country.csv, clear
rename pct_us_citations us_ratio
rename num_us_citations us_pat_num
duplicates drop patent_id, force
save ${stata_output}USpat_citepat_country.dta, replace //var: patent_id us_ratio us_pat_num


use ${stata_output}US_patents_filed_by_EL_otherCNfirms.dta, clear

egen firm_id=group(organization)
rename EL entity_list
replace entity_list=. if entity_list==0

gen int year = .
foreach cand in grtyr appyr {
    capture confirm variable `cand'
    if !_rc replace year = `cand' if missing(year)
}

*** (1) merge CV
rename city city_temp
bysort firm_id city_temp: gen count1 = _N
bysort firm_id (count1): gen city = city_temp[_N]
by firm_id: replace city = city[_N]

bysort firm_id wipo_field_id: gen count2 = _N
bysort firm_id (count2): gen industry = wipo_field_id[_N]
by firm_id: replace industry = industry[_N]

*** merge moderator: citation of US patents
merge 1:1 patent_id using ${stata_output}USpat_citepat_country.dta
drop if _merge==2
drop _merge

*** reliance on US tech
bys firm_id year: egen f_us_ratio1 = median(us_ratio)
bys firm_id year: egen f_us_ratio2 = mean(us_ratio)
bys firm_id year: egen f_us_ratio3 = max(us_ratio)

replace us_pat_num = 0 if us_pat_num==.
replace us_pat_num = 1 if us_pat_num>1
bys firm_id year: egen f_us_num    = sum(us_pat_num) // count of patents citing US patents


*** (2) modify
bys firm_id: egen list_time2 = min(list_time) //Some companies changed their names before and after, resulting in some patents being included in the Entity List, while others were not. Fill in the blanks based on the ones that are missing.
format list_time2 %td
drop list_time
rename list_time2 list_time

bys firm_id: egen entity_list2 = max(entity_list) //EL Same as above
drop entity_list
rename entity_list2 entity_list


*** (3) generate dependent variables

* f_cite_science
bys firm_id year: egen f_cite_science = max(cite_science)
label var f_cite_science "Mark whether a firm's patent citing science in a given year"

* f_cite_science_ratio
bys firm_id year: egen f_cite_science_num = sum(cite_science)
bys firm_id year: gen f_patent_num = _N
gen f_cite_science_ratio = f_cite_science_num/f_patent_num
label var f_cite_science_num "Num of sci-reliant patents of the firm in a given year"
label var f_patent_num "Num of all patents of the firm in a given year"
label var f_cite_science_ratio "% of sci-reliant patents among all patents of the firm in a given year"

* f_cite_paper_num
bys firm_id year: egen f_cite_paper_num = mean(cite_paper_num)
label var f_cite_paper_num "Average num of papers cited by the firm's patents in a given year"

* f_sci_cite_paper_num
bys firm_id year: egen f_sci_cite_paper_num = mean(cond(cite_paper_num != 0, cite_paper_num, .)) // Missing if the firm has no science-reliant patents in that year
label var f_sci_cite_paper_num "Average num of papers cited by the firm's sci-reliant patents in a given year"

* (1) foreign science
bys firm_id year: egen f_cite_foreign_sci_num = sum(cite_foreign_sci)
label var f_cite_foreign_sci_num "Num of foreign sci-reliant patents of the firm in a given year"

gen f_cite_foreign_sci_ratio1 = f_cite_foreign_sci_num/f_patent_num // Share of all patents that cite foreign science
gen f_cite_foreign_sci_ratio2 = f_cite_foreign_sci_num/f_cite_science_num // Share of science-reliant patents that cite foreign science

* (1a) US science
bys firm_id year: egen f_cite_us_sci_num = sum(cite_us_sci)
label var f_cite_us_sci_num "Num of US sci-reliant patents of the firm in a given year"

gen f_cite_us_sci_ratio1 = f_cite_us_sci_num/f_patent_num // Share of all patents that cite U.S. science
gen f_cite_us_sci_ratio2 = f_cite_us_sci_num/f_cite_science_num // Share of science-reliant patents that cite U.S. science

* (1b) non-US foreign science
bys firm_id year: egen f_cite_nonus_foreign_sci_num = sum(cite_nonus_foreign_sci)
label var f_cite_nonus_foreign_sci_num "Num of non-US foreign sci-reliant patents of the firm in a given year"

gen f_cite_nonus_foreign_sci_ratio1 = f_cite_nonus_foreign_sci_num/f_patent_num // Share of all patents that cite non-U.S. foreign science
gen f_cite_nonus_foreign_sci_ratio2 = f_cite_nonus_foreign_sci_num/f_cite_science_num // Share of science-reliant patents that cite non-U.S. foreign science

* (2) Chinese science
bys firm_id year: egen f_cite_cn_sci_num = sum(cite_cn_sci)
label var f_cite_cn_sci_num "Num of Chinese sci-reliant patents of the firm in a given year"

gen f_cite_cn_sci_ratio1 = f_cite_cn_sci_num/f_patent_num // Share of all patents that cite Chinese science
gen f_cite_cn_sci_ratio2 = f_cite_cn_sci_num/f_cite_science_num // Share of science-reliant patents that cite Chinese science

* f_relative_ratio
bys firm_id year: egen f_relative_ratio = median(relative_ratio)


*** cite science older
gen lag_mean = year - paperyear_mean
gen lag_med = year - paperyear_med
gen lag_max = year - paperyear_min
gen lag_min = year - paperyear_max

gen lag = paperyear_max-paperyear_min
* (1) paper year
bys firm_id year: egen f_paperyear_mean = mean(paperyear_mean)
bys firm_id year: egen f_paperyear_med = median(paperyear_med)
bys firm_id year: egen f_paperyear_min = min(paperyear_min)
bys firm_id year: egen f_paperyear_max = max(paperyear_max)

* (2) year lag (filing year - publication year)
bys firm_id year: egen f_yearlag_mean = mean(lag_mean)
bys firm_id year: egen f_yearlag_med = median(lag_med)
bys firm_id year: egen f_yearlag_min = min(lag_min)
bys firm_id year: egen f_yearlag_max = max(lag_max)

bys firm_id year: egen f_lag = max(lag)


keep firm_id year f_cite_science f_cite_science_ratio f_cite_paper_num f_sci_cite_paper_num ///
f_cite_foreign_sci_num f_cite_nonus_foreign_sci_num f_cite_us_sci_num f_cite_cn_sci_num ///
f_cite_science_num f_patent_num f_relative_ratio  ///
f_cite_foreign_sci_ratio1 f_cite_foreign_sci_ratio2 f_cite_nonus_foreign_sci_ratio1 f_cite_nonus_foreign_sci_ratio2 ///
f_cite_cn_sci_ratio1 f_cite_cn_sci_ratio2 f_cite_us_sci_ratio1 f_cite_us_sci_ratio2 ///
f_paperyear_mean f_paperyear_max f_paperyear_min f_yearlag_mean f_yearlag_max f_yearlag_min f_lag ///
list_time entity_list city industry ///
f_us_ratio1 f_us_ratio2 f_us_ratio3 f_us_num

duplicates drop //patent-level to firm-level

xtset firm_id year
keep if year>=2000 & year<=2022

tsfill, full

* Fill missing values generated by `tsfill` for non-outcome identifiers first.
local svars city industry list_time entity_list

sort firm_id year
foreach v of local svars {
    by firm_id (year): replace `v' = `v'[_n-1] if missing(`v')
}

gen year_1 = 3000-year
sort firm_id year_1
foreach v of local svars {
    by firm_id (year_1): replace `v' = `v'[_n-1] if missing(`v')
}
drop year_1

sort firm_id year


foreach v of varlist f_cite_science f_cite_science_num f_patent_num f_cite_paper_num f_sci_cite_paper_num ///
f_cite_foreign_sci_num f_cite_us_sci_num f_cite_nonus_foreign_sci_num f_cite_cn_sci_num ///
f_us_num {
    replace `v' = 0 if missing(`v')
}


****** Restrict to Each Firm's Active Patenting Window (Entry/Exit Adjustment) ******
* 1) Sort
sort firm_id year

* 2) Compute each firm's first/last year with positive patent counts
bysort firm_id (year): egen first_nonzero = min(cond(f_patent_num>0, year, .))
bysort firm_id (year): egen last_nonzero  = max(cond(f_patent_num>0, year, .))

* 3) Check whether 2010-2012 / 2020-2022 are all zero-patent years
by firm_id: egen head_cnt  = total(inrange(year,2010,2012))
by firm_id: egen head_zero = total(inrange(year,2010,2012) & f_patent_num==0)
gen head_all0 = head_cnt==3 & head_zero==3

by firm_id: egen tail_cnt  = total(inrange(year,2020,2022))
by firm_id: egen tail_zero = total(inrange(year,2020,2022) & f_patent_num==0)
gen tail_all0 = tail_cnt==3 & tail_zero==3

* 4) Conditionally trim only when the corresponding 3-year block is all zeros
gen keep = 1
replace keep = keep & year >= first_nonzero if head_all0
replace keep = keep & year <= last_nonzero if tail_all0

* Drop firms with no positive patent counts in the full period
by firm_id: egen anypos = max(f_patent_num>0)
drop if anypos==0

* 5) Keep remaining rows and clean helper variables
keep if keep
drop first_nonzero last_nonzero head_cnt head_zero tail_cnt tail_zero head_all0 tail_all0 anypos keep


gen did = 0
gen list_year = year(list_time)
replace did = 1 if (year>list_year & entity_list==1)

gen dif_year = year-list_year

global allcontrols year city industry firm_id

foreach var of global allcontrols {
    drop if missing(`var')
}

* lag and take ln transformation
gen ln_f_cite_science_num = ln(f_cite_science_num+1)
gen ln_f_cite_foreign_sci_num = ln(f_cite_foreign_sci_num+1)
gen ln_f_cite_us_sci_num=ln(f_cite_us_sci_num+1)
gen ln_f_cite_nonus_foreign_sci_num=ln(f_cite_nonus_foreign_sci_num+1)
gen ln_f_cite_cn_sci_num=ln(f_cite_cn_sci_num+1)

winsor2 f_cite_science_num f_cite_foreign_sci_num f_cite_us_sci_num f_cite_nonus_foreign_sci_num f_cite_cn_sci_num, cuts(0 99.5)

gen whether_pat = 0
replace whether_pat =1 if f_patent_num>0

order firm_id year whether_pat

save ${stata_output}USpatents_DID_allfirm.dta, replace

********************************************************************************
*********************** B. Baseline DID Estimates & Event Study ****************
********************************************************************************


********************************************************************************
************************* summary statistics ***********************************
********************************************************************************

use ${stata_output}USpatents_DID_allfirm.dta, clear

keep firm_id entity_list list_time
duplicates drop
replace entity_list=0 if entity_list==.
tab entity_list


use ${stata_output}USpatents_DID_allfirm.dta, clear
keep if entity_list==1 & year<list_year // pre-treatment observations of treated firms
sum f_cite_science_num_w, meanonly
display "pre-treatment observations of treated firms is: " %6.3f r(mean)


********************************************************************************
*********************** Staggered DID analysis: cite science *******************
********************************************************************************

use ${stata_output}USpatents_DID_allfirm.dta, clear

* OLS
reghdfe f_cite_science_num_w did whether_pat, absorb(year firm_id) vce(r)
est store M1

* ln and OLS
reghdfe ln_f_cite_science_num did whether_pat, absorb(year firm_id) vce(r)
est store M2

* Poisson
ppmlhdfe f_cite_science_num did whether_pat, absorb(year firm_id) vce(r)
est store M3


esttab M1 M2 M3 using ${table_output}robust_USPTO.rtf, ///
    replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ///
    b(%20.3f) se(%7.3f) r2(%9.3f) ///
    stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
    mtitles("Model 1" "Model 2" "Model 3") ///
    nonotes


**************************** Dynamic Event Study ********************************

use ${stata_output}USpatents_DID_allfirm.dta, clear

replace dif_year=3 if dif_year>3 & dif_year!=.
drop if dif_year!=. & !inrange(dif_year,-3,3)

eventdd f_cite_science_num_w, timevar(dif_year) ///
    method(hdfe, absorb(firm_id year)) ///
    baseline(0) vce(r) level(95) ///
    graph_op(ytitle("{bf: Science-Linked USPTO Patents}""{bf: Filed by Chinese Firms}") ///
             xtitle("{bf: Sanction Year}") ///
             xscale(range(-3 .)) ///
             legend(off) ///
             graphregion(color(white)) ///
             bgcolor(white) ///
             scheme(journal))
gr_edit .yaxis1.reset_rule -3 3 1 , tickset(major) ruletype(range)
gr_edit .xaxis1.reset_rule -3 3 1 , tickset(major) ruletype(range)
gr_edit .plotregion1._xylines[1].style.editstyle linestyle(pattern(dash)) editcopy
gr_edit .plotregion1._xylines[1].style.editstyle linestyle(width(thin)) editcopy
gr_edit .plotregion1._xylines[1].DragBy 0 1
gr_edit .plotregion1.plot1.style.editstyle area(linestyle(width(thick))) editcopy

graph save ${figure_output}robust_USPTO_dynamic.gph, replace
