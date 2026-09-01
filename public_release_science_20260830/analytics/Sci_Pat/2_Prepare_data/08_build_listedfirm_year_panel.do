/*******************************************************************************
Project: Chinese Publicly Listed Firms - DID Panel Construction
Script: 08_build_listedfirm_year_panel.do

Purpose
  - Merge listed-firm patent data with Entity List indicators and science-citation data.
  - Aggregate patent-level records to construct the listed-firm DID panel.

Inputs
  - Processed datasets under ${stata_output}
  - Patent supporting files under ${CN_patents}

Outputs (saved under ${stata_output})
  - DID_listedfirm-level.dta
  - CNpatents_firm.dta

*******************************************************************************/
* Run via `00_run_all_2.do` (depends on shared path globals set by the runner).



**********************************************************************************************
*************************** Patent-Level to Firm-Year Panel Build ****************************
**********************************************************************************************


********** 1. Add Entity List and Science-Citation Indicators at Patent Level **********

use ${stata_output}apn_firmcode.dta, clear // Granted from 1985-2023

merge m:1 apn using ${stata_output}CNpatents_firm_copatent_uni.dta
drop if _merge == 2
replace firm_uni = 0 if _merge == 1
drop _merge


*** (1) Add whether filed by firms on the Entity List

merge m:1 apn using ${stata_output}Entity_List_China_withpatents_manual.dta // Chinese patents filed by Entity List firms (granted 1985-2023). Vars: apn list_time entity_list. Obs: 226k

/*
Matching results:
_merge==1 (468k): Patents filed by Chinese listed firms, but not on the "Entity List".
_merge==2 (213k): Patents filed by firms on the "Entity List", but not Chinese listed firms.
_merge==3 (12k): Patents filed by Chinese listed firms and on the "Entity List".
*/

drop if _merge == 2
replace entity_list = 0 if _merge == 1
drop _merge //Sample: Chinese patents filed by Chinese listed firms (added whether filed by firms on the Entity List)

/* If using parent-level matching, add the following lines
bys fapp_standard: egen list_time2 = min(list_time)
drop list_time
rename list_time2 list_time
format list_time %td
*/

*** (2) Add whether the patent cites science
merge m:1 apn using ${stata_output}Chinese_patents_whether_cite_science_basednation.dta // Patent-level

/*
Matching results:
_merge==1 (95k): Patents filed by Chinese listed firms, but it is not in the period of 2010-2022.
_merge==2 (4657k): Patents filed between the period of 2010-2022, but not filed by Chinese listed firms.
_merge==3 (385k): Patents filed by Chinese listed firms and it is in the period of 2010-2022.
*/

keep if _merge == 3
drop _merge


merge m:1 apn using ${stata_output}CNpatents_mainipc.dta
drop if _merge == 2
drop _merge
bysort Symbol ipc_subclass: gen count = _N
bysort Symbol (count): gen industry = ipc_subclass[_N]
by Symbol: replace industry = industry[_N]

encode industry, gen(industry_id)

save ${stata_output}CNpatents_firm.dta, replace //Sample: Chinese patents filed by Chinese listed firms (added whether filed by firms on the Entity List and whether cite science)

********************************** 2. Generate and Merge Variables ***************************

use ${stata_output}CNpatents_firm.dta, clear


bys Symbol: egen list_time2 = min(list_time) // Some firms changed names over time, so some patents are matched to the Entity List and others are not. Fill missing values using the observed list_time within firm.
format list_time2 %td
drop list_time
rename list_time2 list_time

bys Symbol: egen entity_list2 = max(entity_list) // Same logic as above for the Entity List indicator
drop entity_list
rename entity_list2 entity_list

gen firm_id = Symbol

gen int year = .
foreach cand in appyr grtyr {
    capture confirm variable `cand'
    if !_rc replace year = `cand' if missing(year)
}

bys Symbol year: egen firm_uni_colla = mean(firm_uni)

*** Generate the total number of patent applications (patent stock)
preserve

egen apn_id = group(apn)
collapse (count) n_patents = apn_id, by(firm_id year)
sort firm_id year
bysort firm_id: gen patent_stock = sum(n_patents) - n_patents

save ${temp_output}temp.dta, replace
restore

merge m:1 firm_id year using ${temp_output}temp.dta, nogen

*** (1) Generate dependent variables

* f_cite_science
bys firm_id year: egen f_cite_science = max(cite_science)
label var f_cite_science "Whether the firm has any patent citing science in a given year"

* f_cite_science_ratio
bys firm_id year: egen f_cite_science_num = sum(cite_science)
bys firm_id year: gen f_patent_num = _N
gen f_cite_science_ratio = f_cite_science_num/f_patent_num
label var f_cite_science_num "Number of sci-reliant patents of the firm in a given year"
label var f_patent_num "Number of all patents of the firm in a given year"
label var f_cite_science_ratio "% of sci-reliant patents among all patents of the firm in a given year"

* f_cite_paper_num
bys firm_id year: egen f_cite_paper_num = mean(cite_paper_num)
label var f_cite_paper_num "Average number of papers cited by the firm's patents in a given year"

* f_sci_cite_paper_num
bys firm_id year: egen f_sci_cite_paper_num = mean(cond(cite_paper_num != 0, cite_paper_num, .)) // If the firm has no science-reliant patents in that year, this value is missing
label var f_sci_cite_paper_num "Average number of papers cited by the firm's sci-reliant patents in a given year"

* (1) foreign science
bys firm_id year: egen f_cite_foreign_sci_num = sum(cite_foreign_sci)
label var f_cite_foreign_sci_num "Number of foreign sci-reliant patents of the firm in a given year"

gen f_cite_foreign_sci_ratio1 = f_cite_foreign_sci_num/f_patent_num //Share of patents citing foreign science among all patents
gen f_cite_foreign_sci_ratio2 = f_cite_foreign_sci_num/f_cite_science_num //Share of patents citing foreign science among science-reliant patents

* (1a) US science
bys firm_id year: egen f_cite_us_sci_num = sum(cite_us_sci)
label var f_cite_us_sci_num "Number of US sci-reliant patents of the firm in a given year"


* (1b) non-US foreign science
bys firm_id year: egen f_cite_nonus_foreign_sci_num = sum(cite_nonus_foreign_sci)
label var f_cite_nonus_foreign_sci_num "Number of non-US foreign sci-reliant patents of the firm in a given year"

gen f_cite_nonus_foreign_sci_ratio1 = f_cite_nonus_foreign_sci_num/f_patent_num //Share of patents citing non-US foreign science among all patents
gen f_cite_nonus_foreign_sci_ratio2 = f_cite_nonus_foreign_sci_num/f_cite_science_num //Share of patents citing non-US foreign science among science-reliant patents

* (2) Chinese science
bys firm_id year: egen f_cite_cn_sci_num = sum(cite_cn_sci)
label var f_cite_cn_sci_num "Number of Chinese sci-reliant patents of the firm in a given year"

gen f_cite_cn_sci_ratio1 = f_cite_cn_sci_num/f_patent_num //Share of patents citing Chinese science among all patents
gen f_cite_cn_sci_ratio2 = f_cite_cn_sci_num/f_cite_science_num //Share of patents citing Chinese science among science-reliant patents

* relative ratio
bys firm_id year: egen f_relative_ratio1 = median(relative_ratio1)
bys firm_id year: egen f_relative_ratio2 = median(relative_ratio2)

* Moderator: citation of US patents
merge m:1 apn using ${stata_output}CNpat_cite_uspat.dta
drop if _merge == 2
drop _merge

*** Reliance on US technology
bys firm_id year: egen f_us_sum = sum(us_sum)
bys firm_id year: egen f_us_ratio1 = median(us_ratio)
bys firm_id year: egen f_us_ratio2 = mean(us_ratio)
bys firm_id year: egen f_us_ratio3 = max(us_ratio)


keep firm_id Symbol year f_cite_science f_cite_science_ratio f_cite_paper_num f_sci_cite_paper_num ///
f_cite_foreign_sci_num f_cite_nonus_foreign_sci_num f_cite_us_sci_num f_cite_cn_sci_num ///
f_cite_science_num f_patent_num f_relative_ratio1 f_relative_ratio2  ///
f_cite_foreign_sci_ratio1 f_cite_foreign_sci_ratio2 f_cite_nonus_foreign_sci_ratio1 f_cite_nonus_foreign_sci_ratio2 ///
f_cite_cn_sci_ratio1 f_cite_cn_sci_ratio2 ///
list_time entity_list firm_uni_colla patent_stock ///
f_us_sum f_us_ratio1 f_us_ratio2 f_us_ratio3 industry industry_id

duplicates drop

destring Symbol, replace
xtset Symbol year
keep if year >= 2010 & year <= 2022


tsfill, full

* Fill non-time-varying identifiers after tsfill (forward then backward within firm)
local svars Symbol list_time entity_list firm_id industry industry_id

sort Symbol year
foreach v of local svars {
    by Symbol (year): replace `v' = `v'[_n-1] if missing(`v')
}

gen year_1 = 3000 - year
sort Symbol year_1
foreach v of local svars {
    by Symbol (year_1): replace `v' = `v'[_n-1] if missing(`v')
}
drop year_1

sort Symbol year


foreach v of varlist firm_uni_colla patent_stock f_cite_science f_cite_science_num f_patent_num ///
f_cite_paper_num f_sci_cite_paper_num ///
f_cite_foreign_sci_num f_cite_us_sci_num f_cite_nonus_foreign_sci_num f_cite_cn_sci_num {
    replace `v' = 0 if missing(`v')
}

/* If the patent count in that year is 0, the following variables remain missing and should not be filled with 0
f_cite_science_ratio
f_cite_foreign_sci_ratio1 f_cite_foreign_sci_ratio2
f_cite_nonus_foreign_sci_ratio1 f_cite_nonus_foreign_sci_ratio2
f_cite_cn_sci_ratio1 f_cite_cn_sci_ratio2 f_relative_ratio1 f_relative_ratio2
*/


*** (1) Add control variables

merge 1:1 Symbol year using ${stata_output}CSMAR_cv.dta // _merge==1 means the firm-year is in the patent sample but has no matching CV (possibly because the company was not yet listed that year)
keep if _merge == 3
drop _merge

*** (2) Founding year

gen founding_yr = real(substr(EstablishDate, 1, 4))

drop if year < founding_yr & founding_yr != . // If a firm has not yet been founded, it cannot have patent applications. In practice for listed firms, these rows should already be excluded in the prior CV merge.



gen did = 0
gen list_year = year(list_time)
replace did = 1 if (year > list_year & entity_list == 1)

gen firm_listing_year = substr(LISTINGDATE, 1, 4)
label var firm_listing_year "Listing year of the firm"
label var list_time "Date of being listed on the Entity List"
destring firm_listing_year, replace
gen firm_age = year - firm_listing_year

gen firm_size = ln(RegisterCapital)
gen cash = ln(CashHoldings)
egen province_code = group(PROVINCECODE)
egen industry_code = group(IndustryCode)

gen dif_year = year - list_year

replace dif_year = -10 if dif_year < -10

* Control variables
gen founding_year = substr(EstablishDate, 1, 4)
replace founding_year = "" if founding_year == "None"
destring founding_year, replace

gen listing_year = substr(LISTINGDATE, 1, 4)
destring listing_year, replace



global allcontrols firm_age firm_size state_owned cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ province_code industry_code year ListedCoID founding_year listing_year academic_experience patent_stock

foreach var of global allcontrols {
    drop if missing(`var')
}

global sum_controls firm_age firm_size state_owned cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ founding_year listing_year academic_experience patent_stock

global controls firm_age firm_size state_owned cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ academic_experience patent_stock


*** Add moderators
*** (1) Whether the firm has science-based patents in the past three years

sort Symbol year
gen f_cite_science_3yr = 0 // Generate the 3-year rolling indicator

* Loop over each observation to calculate the 3-year rolling indicator
forvalues i = 1/`=_N' {
    * Get company and year for the current observation
    local comp = Symbol[`i']
    local yr = year[`i']

    * Calculate the 3-year rolling count for citing science
    quietly summ f_cite_science if Symbol == `comp' & inrange(year, `yr'-2, `yr'), meanonly
    replace f_cite_science_3yr = r(sum) if _n == `i'
}

* Optional: If you want the new variable to be 1 if the patents cite science, and 0 otherwise
replace f_cite_science_3yr = (f_cite_science_3yr > 0)

*** (2) Industry reliance on science
bys industry_code year: egen i_ros = mean(f_cite_science_ratio)


* Log transforms
gen ln_f_cite_science_num = ln(f_cite_science_num + 1)
gen ln_f_cite_foreign_sci_num = ln(f_cite_foreign_sci_num + 1)
gen ln_f_cite_us_sci_num = ln(f_cite_us_sci_num + 1)
gen ln_f_cite_nonus_foreign_sci_num = ln(f_cite_nonus_foreign_sci_num + 1)
gen ln_f_cite_cn_sci_num = ln(f_cite_cn_sci_num + 1)

winsor2 f_cite_science_num f_cite_foreign_sci_num f_cite_us_sci_num f_cite_nonus_foreign_sci_num f_cite_cn_sci_num, cuts(0 99.5)
winsor2 $controls, replace

gen whether_pat = 0
replace whether_pat = 1 if f_patent_num > 0

gsort Symbol year
order Symbol year whether_pat

* Keep only firms with any patent activity in the panel window
bys Symbol: egen all_pat = sum(f_patent_num)
drop if all_pat == 0 // Only keep firms with patent activity

save ${stata_output}DID_listedfirm-level.dta, replace


erase ${temp_output}temp.dta
