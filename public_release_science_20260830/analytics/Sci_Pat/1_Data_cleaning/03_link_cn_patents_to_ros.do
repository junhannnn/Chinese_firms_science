
/*******************************************************************************
Project: CN Patents (1985–2025) — Link to ROS (Science Reliance)
Script: 03_link_cn_patents_to_ros.do

Purpose
  - Construct a patent–paper level dataset of science-reliant CN patents by:
      (i) excluding patents filed by foreigners in China
      (ii) merging patent-year information

Inputs (from ${stata_output})
  - Chinese_npl_citations_both_sources.dta     (patent–paper level)
  - CNpatents_type_country.dta                (applicant type + country)
  - CNpatents_year.dta                        (appyr/sxyr/grtyr + pub_id)

Outputs (saved under ${stata_output})
  (1) CNpatents_reliance_science.dta          [IMPORTANT]
      - patent–paper level
      - science-reliant granted patents filed by Chinese entities
  (2) CNpatents_reliance_science_allyears.dta

Notes
  - Core filter: keep observations where `app_country` equals the China value.
*******************************************************************************/
* Run via `00_run_all_1.do` (depends on shared path globals set by the runner).



********************************************************************************
*********************** Merge (patent–paper level) *****************************
********************************************************************************

/*
Base data:
  - Chinese_npl_citations_both_sources.dta (patent–paper level)
Filters:
  - Keep only patents filed by Chinese entities (`app_country` equals the China value)
Merges:
  - CNpatents_type_country.dta (type + applicant country)
  - CNpatents_year.dta (appyr/sxyr/grtyr, pub_id, etc.)
*/

use "${stata_output}Chinese_npl_citations_both_sources.dta", clear

/*** (1) Exclude foreign individuals and entities ***/
merge m:1 apn using "${stata_output}CNpatents_type_country.dta"
* Comment in original code:
*   All matched. _merge==2: Chinese patents filed by Chinese entities but not citing scientific papers
drop if _merge == 2
drop _merge

* Keep only patents filed by Chinese entities in China
drop if app_country != "中国"


/*** (2) Merge patent-year information ***/
merge m:1 apn using "${stata_output}CNpatents_year.dta"
* Attach application/examination/grant years to each patent–paper observation.
drop if _merge == 2
drop _merge

rename apn patent_id

tab appyr   // 1987–2023
tab grtyr   // 1990–2025

save "${stata_output}CNpatents_reliance_science.dta", replace
* Vars (examples): patent_id paperid authorid authororder source country ...



********************************************************************************
****************************** Other calculation *******************************
********************************************************************************

/******************* Share of HMT at the paper level ***************************
  Convert from patent–paper level to paper level, then group countries.
*******************************************************************************/
* This auxiliary file is a paper-level summary used for descriptive checks.

use "${stata_output}CNpatents_reliance_science.dta", clear

keep paperid paperyear source paperinfo country language
duplicates drop   // patent–paper -> paper level (original note: 2,828,205 obs)

gen country1 = "Others"
replace country1 = "Mainland China" if country == "China"
replace country1 = "HMT"            if country == "Hong Kong" | country == "Macau" | country == "Taiwan"
replace country1 = "Germany"        if country == "Germany"
replace country1 = "Japan"          if country == "Japan"
replace country1 = "UK"            if country == "UK"
replace country1 = "USA"           if country == "USA"
replace country1 = "Canada"        if country == "Canada"
replace country1 = "South Korea"   if country == "South Korea"

tab country1, sort


