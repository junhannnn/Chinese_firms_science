/*******************************************************************************
Project: CN_CN | ROS Analytics — Firm-Year Panel Build (DID)
Script: 06_build_firm_year_panel.do

Purpose
  - Convert patent-level data into a firm-year panel and construct core DID variables
    for Entity List (EL) inclusion analysis.
  - Merge patent-level covariates/moderators (province, IPC/industry, SOE, RCA,
    collaboration/transfer/license indicators, US-patent citation reliance), then
    (i) aggregate to firm-year, (ii) balance the panel via tsfill, and (iii) define
    treatment timing variables.

Inputs
  - Patent-level master (Stata):
      ${stata_output}Chinese_patents_filed_by_EL_otherfirms.dta
        (requires at least: apn, fapp, fapp_standard, list_time, entity_list,
         and science-citation variables such as cite_science and paper-year moments)
  - Public listing mapping (Stata):
      ${stata_output}apn_firmcode.dta
  - Patent exploration measures (Stata):
      ${stata_output}apn_exploration.dta
  - Other regulatory lists (Stata):
      ${stata_output}Other_lists.dta
  - Patent-level controls / moderators (Stata):
      ${stata_output}CNpatents_province.dta
      ${stata_output}CNpatents_mainipc.dta
      ${stata_output}CNpatents_soe.dta
      ${stata_output}CNpatents_firm_copatent_uni.dta
      ${stata_output}CNpatents_firm_copatent_firm.dta
      ${stata_output}CNpatents_relative_competitive_mainipc.dta
      ${stata_output}CNpatents_relative_competitive_allipc.dta
      ${stata_output}CNpat_cite_uspat.dta

Final Output (saved under ${stata_output})
  - DID_allfirm-level.dta
    (balanced firm-year panel, restricted to 2010–2022, containing treatment timing,
     outcomes, moderators, and controls)

Key Constructions
  - firm_id: numeric firm identifier from firm name fapp (egen group()).
  - Panel window: keeps years 2010–2022; tsfill creates a balanced firm-year grid.
  - Entry restriction: drops firm-years prior to foundyr_fpatyr.
  - Exit restriction: if a firm has zero patents in 2021–2023, drop years after its
    last patent year.

Dependencies / Requirements
  - Requires user-installed Stata command winsor2 (SSC) for winsorization.
  - Assumes upstream scripts have standardized keys (apn, fapp, fapp_standard) and
    produced the patent-level input datasets listed above.

Notes
  - "Other list" membership is augmented via manual regex-based firm-name matching,
    and corresponding otherlist_year is manually assigned for those additions.
  - list_time and entity_list are normalized within firm_id to address name changes
    across time (min(list_time), max(entity_list)).
*******************************************************************************/
* Run via `00_run_all_2.do` (depends on shared path globals set by the runner).



********************************************************************************
* Patent-level -> firm-year panel construction
********************************************************************************

use ${stata_output}Chinese_patents_filed_by_EL_otherfirms.dta, clear


*------------------------------------------------------------*
* Merge: whether patent is filed by a publicly listed firm
*------------------------------------------------------------*
merge 1:m apn using ${stata_output}apn_firmcode.dta
drop if _merge == 2
drop _merge

gen public_list = 0
replace public_list = 1 if Symbol != ""
bys fapp: egen publicly_listed = max(public_list)
drop public_list


*------------------------------------------------------------*
* Merge: exploration indicator
*------------------------------------------------------------*
merge m:1 apn using ${stata_output}apn_exploration.dta
drop if _merge == 2
drop _merge


*------------------------------------------------------------*
* Merge: other lists
*------------------------------------------------------------*
merge m:1 fapp using ${stata_output}Other_lists.dta

gen other_list = 0
replace other_list = 1 if _merge == 3
list if _merge == 2

* Manual additions to "other_list" based on firm name patterns
replace other_list = 1 if regexm(fapp, "中光学集团") | regexm(fapp, "中国建筑工程") | ///
    regexm(fapp, "中国核工业") | regexm(fapp, "中国电信集团") | regexm(fapp, "中国电子科技集团") | ///
    regexm(fapp, "中国航天科工集团") | regexm(fapp, "中国船舶工业集团") | regexm(fapp, "中芯国际集成电路制造")

replace other_list = 1 if regexm(fapp, "中国航发") | regexm(fapp, "中国航空工业集团") | ///
    regexm(fapp, "中航飞机股份有限公司") | regexm(fapp, "江苏苏美达")

* Manually set otherlist_year for the above additions
replace otherlist_year = 2021 if regexm(fapp, "中光学集团") | regexm(fapp, "中国建筑工程") | ///
    regexm(fapp, "中国核工业") | regexm(fapp, "中国电信集团") | regexm(fapp, "中国电子科技集团") | ///
    regexm(fapp, "中国航天科工集团") | regexm(fapp, "中国船舶工业集团") | regexm(fapp, "中芯国际集成电路制造")

replace otherlist_year = 2020 if regexm(fapp, "中国航发") | regexm(fapp, "中国航空工业集团") | ///
    regexm(fapp, "中航飞机股份有限公司") | regexm(fapp, "江苏苏美达")

drop if _merge == 2
drop _merge

*------------------------------------------------------------*
* Merge: patent-paper similarity
*------------------------------------------------------------*
destring apn, gen (apn_num)

merge m:1 apn_num using ${stata_output}science_closeness_cnki.dta
drop if _merge == 2
drop _merge

merge m:1 apn_num using ${stata_output}science_closeness_int.dta
drop if _merge == 2
drop _merge

*------------------------------------------------------------*
* Firm identifiers and basic cleaning
*------------------------------------------------------------*
egen firm_id = group(fapp)

preserve
keep firm_id fapp
duplicates drop
sort firm_id
save "${stata_output}firm_id_fapp_mapping.dta", replace
restore


replace entity_list = 0 if entity_list == .

rename appyr year

********************************************************************************
* (1) Merge covariates and moderators (patent-level inputs)
********************************************************************************

* Province (patent-level -> firm-level min province_id)
merge m:1 apn using ${stata_output}CNpatents_province.dta
drop if _merge == 2
drop _merge
bys firm_id: egen province = min(province_id)

* Main IPC and industry assignment (most frequent subclass per firm)
merge m:1 apn using ${stata_output}CNpatents_mainipc.dta
drop if _merge == 2
drop _merge
bysort firm_id ipc_subclass: gen count = _N
bysort firm_id (count): gen industry = ipc_subclass[_N]
by firm_id: replace industry = industry[_N]

* SOE indicator (firm-level)
merge m:1 fapp_standard using ${stata_output}CNpatents_soe.dta
drop if _merge == 2
drop _merge
bys firm_id: egen state_owned = max(soe)

* University co-patenting (firm-year)
merge m:1 apn using ${stata_output}CNpatents_firm_copatent_uni.dta
drop if _merge == 2
replace firm_uni = 0 if _merge == 1
drop _merge
bys firm_id year: egen firm_uni_colla = max(firm_uni)
bys firm_id year: egen firm_uni_colla_num = sum(firm_uni)

* Firm-firm co-patenting (firm-year)
merge m:1 apn using ${stata_output}CNpatents_firm_copatent_firm.dta
drop if _merge == 2
replace firm_colla_firm = 0 if _merge == 1
drop _merge
bys firm_id year: egen firm_firm_colla = max(firm_colla_firm)
bys firm_id year: egen firm_firm_colla_num = sum(firm_colla_firm)

* Relative competitive advantage (RCA) measures
merge m:1 apn using ${stata_output}CNpatents_relative_competitive_mainipc.dta
drop if _merge == 2
drop _merge
bys firm_id year: egen rca = max(relative_competitive)
label var rca "Relative competitive advantages of patents filed by each firm in a given year"

merge m:1 apn using ${stata_output}CNpatents_relative_competitive_allipc.dta
drop if _merge == 2
drop _merge
bys firm_id year: egen rca2 = max(relative_competitive2)
label var rca2 "Relative competitive advantages of patents filed by each firm in a given year"

* Moderator: citation of US patents
merge m:1 apn using ${stata_output}CNpat_cite_uspat.dta
drop if _merge == 2
drop _merge


********************************************************************************
* (2) Normalize list_time and entity_list within firm (name changes across time)
********************************************************************************

* list_time: fill within firm using earliest observed list_time
bys firm_id: egen list_time2 = min(list_time)
format list_time2 %td
drop list_time
rename list_time2 list_time

* entity_list: fill within firm using max observed entity_list
bys firm_id: egen entity_list2 = max(entity_list)
drop entity_list
rename entity_list2 entity_list


********************************************************************************
* (3) Construct dependent variables (firm-year aggregates)
********************************************************************************

* Indicator: any patent cites science (firm-year)
bys firm_id year: egen f_cite_science = max(cite_science)
label var f_cite_science "Mark whether a firm's patent citing science in a given year"

* Counts + ratio
bys firm_id year: egen f_cite_science_num = sum(cite_science)
bys firm_id year: gen  f_patent_num = _N
gen f_cite_science_ratio = f_cite_science_num / f_patent_num
label var f_cite_science_num   "Num of sci-reliant patents of the firm in a given year"
label var f_patent_num         "Num of all patents of the firm in a given year"
label var f_cite_science_ratio "% of sci-reliant patents among all patents of the firm in a given year"

* Science-citing patents in exploration (new_com == 1)
bys firm_id year: egen f_cite_science_num_explo = sum(cite_science) if new_com == 1
bys firm_id year: egen f_cite_science_explo = max(f_cite_science_num_explo)

* Avg. number of cited papers (all patents)
bys firm_id year: egen f_cite_paper_num = mean(cite_paper_num)
label var f_cite_paper_num "Average num of papers cited by the firm's patents in a given year"

* Avg. number of cited papers among science-reliant patents only
* If no sci-reliant patents in that year, value remains missing.
bys firm_id year: egen f_sci_cite_paper_num = mean(cond(cite_paper_num != 0, cite_paper_num, .))
label var f_sci_cite_paper_num "Average num of papers cited by the firm's sci-reliant patents in a given year"


*------------------------------------------------------------*
* Science source decomposition (foreign / US / non-US / CN)
*------------------------------------------------------------*

* Foreign science
bys firm_id year: egen f_cite_foreign_sci_num = sum(cite_foreign_sci)
label var f_cite_foreign_sci_num "Num of foreign sci-reliant patents of the firm in a given year"
bys firm_id year: egen f_cite_foreign_sci_w = sum(w_foreign)

gen f_cite_foreign_sci_ratio1 = f_cite_foreign_sci_num / f_patent_num
gen f_cite_foreign_sci_ratio2 = f_cite_foreign_sci_num / f_cite_science_num
gen f_cite_foreign_sci_ratio3 = f_cite_foreign_sci_w / f_patent_num
gen f_cite_foreign_sci_ratio4 = f_cite_foreign_sci_w / f_cite_science_num

* US science
bys firm_id year: egen f_cite_us_sci_num = sum(cite_us_sci)
label var f_cite_us_sci_num "Num of US sci-reliant patents of the firm in a given year"
bys firm_id year: egen f_cite_us_sci_w = sum(w_us)

gen f_cite_us_sci_ratio1 = f_cite_us_sci_num / f_patent_num
gen f_cite_us_sci_ratio2 = f_cite_us_sci_num / f_cite_science_num
gen f_cite_us_sci_ratio3 = f_cite_us_sci_w / f_patent_num
gen f_cite_us_sci_ratio4 = f_cite_us_sci_w / f_cite_science_num

* Non-US foreign science
bys firm_id year: egen f_cite_nonus_foreign_sci_num = sum(cite_nonus_foreign_sci)
label var f_cite_nonus_foreign_sci_num "Num of non-US foreign sci-reliant patents of the firm in a given year"
bys firm_id year: egen f_cite_nonus_foreign_sci_w = sum(w_nonus_foreign)

gen f_cite_nonus_foreign_sci_ratio1 = f_cite_nonus_foreign_sci_num / f_patent_num
gen f_cite_nonus_foreign_sci_ratio2 = f_cite_nonus_foreign_sci_num / f_cite_science_num
gen f_cite_nonus_foreign_sci_ratio3 = f_cite_nonus_foreign_sci_w / f_patent_num
gen f_cite_nonus_foreign_sci_ratio4 = f_cite_nonus_foreign_sci_w / f_cite_science_num

* Chinese science
bys firm_id year: egen f_cite_cn_sci_num = sum(cite_cn_sci)
label var f_cite_cn_sci_num "Num of Chinese sci-reliant patents of the firm in a given year"
bys firm_id year: egen f_cite_cn_sci_w = sum(w_cn)

gen f_cite_cn_sci_ratio1 = f_cite_cn_sci_num / f_patent_num
gen f_cite_cn_sci_ratio2 = f_cite_cn_sci_num / f_cite_science_num
gen f_cite_cn_sci_ratio3 = f_cite_cn_sci_w / f_patent_num
gen f_cite_cn_sci_ratio4 = f_cite_cn_sci_w / f_cite_science_num

*------------------------------------------------------------*
* Relative composition ratios (medians at firm-year)
*------------------------------------------------------------*
bys firm_id year: egen f_relative_ratio1        = median(relative_ratio1)
bys firm_id year: egen f_relative_ratio2        = median(relative_ratio2)
bys firm_id year: egen f_cn_sci_ratio           = median(cn_sci_ratio)
bys firm_id year: egen f_foreign_sci_ratio      = median(foreign_sci_ratio)
bys firm_id year: egen f_us_sci_ratio           = median(us_sci_ratio)
bys firm_id year: egen f_nonusforeign_sci_ratio = median(nonusforeign_sci_ratio)

bys firm_id year: egen f_cite_cn_lang       = sum(cite_cn_lang)
bys firm_id year: egen f_cite_en_lang       = sum(cite_en_lang)
bys firm_id year: egen f_cite_cn_lang_ratio = median(cite_cn_lang_ratio)
bys firm_id year: egen f_cite_en_lang_ratio = median(cite_en_lang_ratio)


*------------------------------------------------------------*
* Citation age / lag construction
*------------------------------------------------------------*
gen lag_mean = year - paperyear_mean
gen lag_med  = year - paperyear_med
gen lag_max  = year - paperyear_min
gen lag_min  = year - paperyear_max

gen lag = paperyear_max - paperyear_min

* Paper year moments (firm-year)
bys firm_id year: egen f_paperyear_mean = mean(paperyear_mean)
bys firm_id year: egen f_paperyear_med  = median(paperyear_med)
bys firm_id year: egen f_paperyear_min  = min(paperyear_min)
bys firm_id year: egen f_paperyear_max  = max(paperyear_max)

* Year lag moments (filing year - publication year)
bys firm_id year: egen f_yearlag_mean = mean(lag_mean)
bys firm_id year: egen f_yearlag_med  = median(lag_med)
bys firm_id year: egen f_yearlag_min  = min(lag_min)
bys firm_id year: egen f_yearlag_max  = max(lag_max)

bys firm_id year: egen f_lag = max(lag)

* Multiple-country knowledge sources (count)
bys firm_id year: egen f_multi_country = total(multi_country)
label var f_multi_country "Number of science-reliant patents which is multiple knowledge sources"


*------------------------------------------------------------*
* Reliance on US technology (firm-year)
*------------------------------------------------------------*
replace us_sum = 0 if us_sum==.
replace us_sum = 1 if us_sum>1
bys firm_id year: egen f_us_sum    = sum(us_sum) // count of patents citing US patents

*bys firm_id year: egen f_us_sum    = sum(us_sum)
bys firm_id year: egen f_us_ratio1 = median(us_ratio)
bys firm_id year: egen f_us_ratio2 = mean(us_ratio)
bys firm_id year: egen f_us_ratio3 = max(us_ratio)


*------------------------------------------------------------*
* CNKI patent-paper similarity
*------------------------------------------------------------*

*** all sample

bys firm_id year: egen f_cnki_closeness_mean = max(cnki_closeness_mean)
label var f_cnki_closeness_mean "The mean CNKI science closeness of patents filed by the firm in a given year"

bys firm_id year: egen f_cnki_closeness_med = max(cnki_closeness_med)
label var f_cnki_closeness_med "The median CNKI science closeness of patents filed by the firm in a given year"

bys firm_id year: egen f_cnki_closeness_max = max(cnki_closeness_max)
label var f_cnki_closeness_max "The max CNKI science closeness of patents filed by the firm in a given year"

*** subsample

* =========================
* Construct S/NS-specific similarity at patent level
* =========================
gen cnki_mean_s  = cnki_closeness_mean if cite_science==1
gen cnki_mean_ns = cnki_closeness_mean if cite_science==0

gen cnki_med_s  = cnki_closeness_med if cite_science==1
gen cnki_med_ns = cnki_closeness_med if cite_science==0

gen cnki_max_s  = cnki_closeness_max if cite_science==1
gen cnki_max_ns = cnki_closeness_max if cite_science==0

* =========================
* Aggregate to firm-year
* =========================
bys firm_id year: egen f_cnkiclose_mean_s  = max(cnki_mean_s)
bys firm_id year: egen f_cnkiclose_mean_ns = max(cnki_mean_ns)

bys firm_id year: egen f_cnkiclose_med_s  = max(cnki_med_s)
bys firm_id year: egen f_cnkiclose_med_ns = max(cnki_med_ns)

bys firm_id year: egen f_cnkiclose_max_s  = max(cnki_max_s)
bys firm_id year: egen f_cnkiclose_max_ns = max(cnki_max_ns)

gen one_sl  = (cite_science==1)
gen one_nsl = (cite_science==0)

bys firm_id year: egen f_sl_num = total(one_sl)
bys firm_id year: egen f_nsl_num = total(one_nsl)

gen f_has_sl  = (f_sl_num>0)
gen f_has_nsl = (f_nsl_num>0)
label var f_has_sl  "Indicator: firm-year has at least one SL patent"
label var f_has_nsl "Indicator: firm-year has at least one NSL patent"



*------------------------------------------------------------*
* WOS patent-paper similarity
*------------------------------------------------------------*


*** all sample

bys firm_id year: egen f_wos_closeness_mean = max(wos_closeness_mean)
label var f_wos_closeness_mean "The mean WOS science closeness of patents filed by the firm in a given year"

bys firm_id year: egen f_wos_closeness_med = max(wos_closeness_med)
label var f_wos_closeness_med "The median WOS science closeness of patents filed by the firm in a given year"

bys firm_id year: egen f_wos_closeness_max = max(wos_closeness_max)
label var f_wos_closeness_max "The max WOS science closeness of patents filed by the firm in a given year"

*** subsample

* =========================
* Construct S/NS-specific similarity at patent level
* =========================
gen wos_mean_s  = wos_closeness_mean if cite_science==1
gen wos_mean_ns = wos_closeness_mean if cite_science==0

gen wos_med_s  = wos_closeness_med if cite_science==1
gen wos_med_ns = wos_closeness_med if cite_science==0

gen wos_max_s  = wos_closeness_max if cite_science==1
gen wos_max_ns = wos_closeness_max if cite_science==0

* =========================
* Aggregate to firm-year
* =========================
bys firm_id year: egen f_wosclose_mean_s  = max(wos_mean_s)
bys firm_id year: egen f_wosclose_mean_ns = max(wos_mean_ns)

bys firm_id year: egen f_wosclose_med_s  = max(wos_med_s)
bys firm_id year: egen f_wosclose_med_ns = max(wos_med_ns)

bys firm_id year: egen f_wosclose_max_s  = max(wos_max_s)
bys firm_id year: egen f_wosclose_max_ns = max(wos_max_ns)





********************************************************************************
* Keep firm-year variables, then collapse patent-level -> firm-year
********************************************************************************
keep firm_id fapp year publicly_listed foundyr_fpatyr ///
    f_cite_science f_cite_science_ratio f_cite_paper_num f_sci_cite_paper_num ///
    f_cite_foreign_sci_num f_cite_nonus_foreign_sci_num f_cite_us_sci_num f_cite_cn_sci_num f_cite_science_num f_patent_num ///
    f_relative_ratio1 f_relative_ratio2 f_cn_sci_ratio f_foreign_sci_ratio f_us_sci_ratio f_nonusforeign_sci_ratio ///
    f_cite_foreign_sci_ratio1 f_cite_foreign_sci_ratio2 f_cite_foreign_sci_ratio3 f_cite_foreign_sci_ratio4 ///
	f_cite_nonus_foreign_sci_ratio1 f_cite_nonus_foreign_sci_ratio2 f_cite_nonus_foreign_sci_ratio3 f_cite_nonus_foreign_sci_ratio4 ///
    f_cite_cn_sci_ratio1 f_cite_cn_sci_ratio2 f_cite_cn_sci_ratio3 f_cite_cn_sci_ratio4 ///
	f_cite_us_sci_ratio1 f_cite_us_sci_ratio2 f_cite_us_sci_ratio3 f_cite_us_sci_ratio4 ///
    list_time entity_list province industry state_owned rca rca2 ///
    otherlist_year other_list ///
    firm_uni_colla firm_firm_colla firm_uni_colla_num firm_firm_colla_num ///
    f_cite_cn_lang f_cite_en_lang f_cite_cn_lang_ratio f_cite_en_lang_ratio ///
    f_paperyear_mean f_paperyear_med f_paperyear_max f_paperyear_min f_yearlag_mean f_yearlag_max f_yearlag_min f_lag ///
    f_cite_science_explo ///
    f_us_sum f_us_ratio1 f_us_ratio2 f_us_ratio3 ///
    f_multi_country ///
	f_cnki_closeness_mean f_cnki_closeness_med f_cnki_closeness_max f_wos_closeness_mean f_wos_closeness_med f_wos_closeness_max ///
	f_cnkiclose_mean_s f_cnkiclose_mean_ns f_cnkiclose_med_s f_cnkiclose_med_ns f_cnkiclose_max_s f_cnkiclose_max_ns ///
	f_wosclose_mean_s f_wosclose_mean_ns f_wosclose_med_s f_wosclose_med_ns f_wosclose_max_s f_wosclose_max_ns ///
	f_has_sl f_has_nsl

duplicates drop


********************************************************************************
* Panel construction: restrict years, tsfill, and missing-value handling
********************************************************************************

xtset firm_id year
keep if year >= 2010 & year <= 2022

* Convert unbalanced panel -> balanced panel (full firm-year grid)
drop f_cite_science_explo
tsfill, full


*------------------------------------------------------------*
* Fill time-invariant (or slowly varying) firm attributes forward/backward
*------------------------------------------------------------*
local svars fapp publicly_listed otherlist_year other_list province industry ///
    state_owned list_time entity_list foundyr_fpatyr

sort firm_id year
foreach v of local svars {
    by firm_id (year): replace `v' = `v'[_n-1] if missing(`v')
}

gen year_1 = 3000 - year
sort firm_id year_1
foreach v of local svars {
    by firm_id (year_1): replace `v' = `v'[_n-1] if missing(`v')
}
drop year_1

sort firm_id year


*------------------------------------------------------------*
* Fill zeros for count-like outcomes where missing implies 0
*------------------------------------------------------------*
foreach v of varlist ///
    f_cite_science f_cite_science_num f_patent_num ///
    f_cite_cn_sci_num f_cite_foreign_sci_num f_cite_us_sci_num f_cite_nonus_foreign_sci_num ///
    firm_uni_colla firm_uni_colla_num firm_firm_colla firm_firm_colla_num ///
    f_cite_cn_lang f_cite_en_lang ///
    f_cite_paper_num f_sci_cite_paper_num f_multi_country {
    replace `v' = 0 if missing(`v')
}


*------------------------------------------------------------*
* Entry: drop years prior to founding year
*------------------------------------------------------------*
drop if year < foundyr_fpatyr   // If a firm is not founded, it should not have patent applications


*------------------------------------------------------------*
* Exit: if no patents in 2021–2023 window, drop years after last patent year
*------------------------------------------------------------*
bysort fapp (year): egen patent_2020_2022 = max(cond(inrange(year, 2021, 2023) & f_patent_num > 0, 1, 0))
bysort fapp (year): egen last_patent_year = max(cond(f_patent_num > 0, year, .))

drop if patent_2020_2022 == 0 & year > last_patent_year
drop patent_2020_2022 last_patent_year


********************************************************************************
* DID variables
********************************************************************************
gen did = 0
gen list_year = year(list_time)
replace did = 1 if (year > list_year & entity_list == 1)

gen dif_year = year - list_year


********************************************************************************
* Controls and missing-value enforcement
********************************************************************************
global allcontrols year province industry firm_id state_owned f_cite_science_num
foreach var of global allcontrols {
    drop if missing(`var')
}


********************************************************************************
* Moderators
********************************************************************************

* Scientific foundations: cumulative past science citation indicator and counts
gen past_cite_science = 0
bysort firm_id (year): replace past_cite_science = max(past_cite_science[_n-1], f_cite_science[_n-1]) if _n > 1

gen past_cite_science_num = 0
bysort firm_id (year): replace past_cite_science_num = sum(f_cite_science_num[_n-1]) if _n > 1

bysort firm_id (year): egen total_f_cite_science_ratio = total(f_cite_science_ratio)
bysort firm_id (year): egen count_f_cite_science_ratio = total(!missing(f_cite_science_ratio))
bysort firm_id (year): gen past_cite_science_ratio = ///
    (total_f_cite_science_ratio - f_cite_science_ratio) / (count_f_cite_science_ratio - 1) if _n > 1


********************************************************************************
* Matching variables: pre-treatment averages
********************************************************************************

* before_patent:
*   - Treated: avg patents before list_year
*   - Controls: avg patents over entire sample period
egen before_patent = mean(f_patent_num) if !missing(list_year) & year < list_year, by(firm_id)
bysort firm_id (year): replace before_patent = before_patent[_n-1] if missing(before_patent)

egen before_patent_control = mean(f_patent_num), by(firm_id)
replace before_patent = before_patent_control if missing(before_patent)
drop before_patent_control

* before_sci_patent:
*   - Treated: avg sci-patents before list_year
*   - Controls: avg sci-patents over entire sample period
egen before_sci_patent = mean(f_cite_science_num) if !missing(list_year) & year < list_year, by(firm_id)
bysort firm_id (year): replace before_sci_patent = before_sci_patent[_n-1] if missing(before_sci_patent)

egen before_sci_patent_control = mean(f_cite_science_num), by(firm_id)
replace before_sci_patent = before_sci_patent_control if missing(before_sci_patent)
drop before_sci_patent_control


********************************************************************************
* Transformations and winsorization
********************************************************************************

* Log transforms (+1 shift)
gen ln_f_cite_science_num          = ln(f_cite_science_num + 1)
gen ln_f_cite_cn_sci_num           = ln(f_cite_cn_sci_num + 1)
gen ln_f_cite_foreign_sci_num      = ln(f_cite_foreign_sci_num + 1)
gen ln_f_cite_us_sci_num           = ln(f_cite_us_sci_num + 1)
gen ln_f_cite_nonus_foreign_sci_num= ln(f_cite_nonus_foreign_sci_num + 1)
gen ln_f_multi_country             = ln(f_multi_country + 1)

winsor2 f_cite_science_num f_cite_cn_sci_num f_cite_foreign_sci_num ///
    f_cite_us_sci_num f_cite_nonus_foreign_sci_num f_multi_country, cuts(0 99.5)

encode industry, gen(industry_id)

* Ensure SOE is firm-level max within firm
bys firm_id: egen soe = max(state_owned)
drop state_owned
rename soe state_owned

* Patent application indicator
gen whether_pat = 0
replace whether_pat = 1 if f_patent_num > 0

sort firm_id year
order firm_id fapp year whether_pat

* Drop firms with only one observation in the panel
bys firm_id: gen single = _N
drop if single == 1
drop single
*drop fapp

********************************************************************************
* Save final output
********************************************************************************
save ${stata_output}DID_allfirm-level.dta, replace
