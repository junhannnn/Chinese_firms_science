/*******************************************************************************
Project: Science-linked patents—supplementary alternative identification
Script:  3_merge_export_patent.do

Purpose:
  Match firms in the adversary-state export data to Chinese patent applicants.
  Standardize firm names, apply sequential exact matches using cleaned and
  suffix-stripped names, reject ambiguous matches, and attach export-exposure
  measures to matched patent applicants.

Main inputs (under ${stata_output}):
  - exp_usadver.dta
  - Chinese_patents_filed_by_EL_otherfirms.dta

Main output (under ${stata_output}):
  - exp_usadver_merge.dta: applicant-level adversary-state export measures

Notes:
  Intermediate cleaning and matching files are written under ${temp_output} and
  removed at the end. Exact matches proceed from the most to the least specific
  name representation, with uniqueness and name-quality restrictions.
*******************************************************************************/

* ==============================================================================
* 1. Configure the Stata session and shared paths
* ==============================================================================

clear all
set more off


capture cd ".\analytics\Sci_Pat\"
if _rc {
    capture cd "./analytics/Sci_Pat/"
}


global stata_output "../../stata_output/CN_CN/"
global temp_output  "../../temp_output/CN_CN/"

* ==============================================================================
* 2. Clean and standardize export-firm names
* ==============================================================================
use "${stata_output}exp_usadver.dta", clear

* Create a stable export-row identifier for the sequential matches.
gen exp_id = _n

rename firm_name name_raw

* Remove surrounding and internal whitespace.
gen name_clean = ustrtrim(name_raw)
replace name_clean = ustrregexra(name_clean, "\s+", "")

* Standardize bracket and dash characters.
replace name_clean = subinstr(name_clean, "（", "(", .)
replace name_clean = subinstr(name_clean, "）", ")", .)
replace name_clean = subinstr(name_clean, "－", "-", .)
replace name_clean = subinstr(name_clean, "—", "-", .)
replace name_clean = subinstr(name_clean, "–", "-", .)

* Remove leading registration-status labels.
replace name_clean = ustrregexra(name_clean, "^\(已注销\)", "")
replace name_clean = ustrregexra(name_clean, "^（已注销）", "")
replace name_clean = ustrregexra(name_clean, "^已注销", "")
replace name_clean = ustrregexra(name_clean, "^【该企业已废止】", "")
replace name_clean = ustrregexra(name_clean, "^【已废止】", "")
replace name_clean = ustrregexra(name_clean, "^【已注销】", "")
replace name_clean = ustrregexra(name_clean, "^【吊销】", "")

* Remove book-title punctuation.
replace name_clean = ustrregexra(name_clean, "[《》]", "")

* Remove leading and trailing punctuation.
replace name_clean = ustrregexra(name_clean, "^[,._\-\[\]【】]+", "")
replace name_clean = ustrregexra(name_clean, "[,._\-\[\]【】_]+$", "")
replace name_clean = ustrtrim(name_clean)

* Construct a core name by removing common legal suffixes.
gen name_core = name_clean
replace name_core = ustrregexra(name_core, ///
"(集团股份有限公司|集团有限责任公司|集团有限公司|股份有限公司|有限责任公司|有限公司|集团公司|总公司|公司|有限公|有限)$", "")
replace name_core = ustrtrim(name_core)

* Retain a conservative matching key based on the core name.
gen name_key = name_core

* Flag short or malformed names that are unsafe for automated matching.
gen bad_name = 0
replace bad_name = 1 if ustrlen(name_clean) <= 3
replace bad_name = 1 if regexm(name_clean, "[(]$")
replace bad_name = 1 if regexm(name_clean, "^[A-Za-z0-9\.\-]+$") & ustrlen(name_clean) <= 6

* Identify short or truncated alphanumeric abbreviations.
gen abbrev_trunc = 0
replace abbrev_trunc = 1 if regexm(name_clean, "^[A-Za-z0-9\.\-]+\($")
replace abbrev_trunc = 1 if regexm(name_clean, "^[A-Za-z0-9\.\-]+-$")
replace abbrev_trunc = 1 if regexm(name_clean, "^[A-Za-z0-9\.\-]+$") & ustrlen(name_clean) <= 5
replace bad_name = 1 if abbrev_trunc == 1

* Build a diagnostic name stub; it is not used for automated matching.
gen name_stub = name_clean
replace name_stub = ustrregexra(name_stub, "[(\-]+$", "")
replace name_stub = ustrtrim(name_stub)

* Flag names that appear truncated in the source data.
gen truncated_name = 0
replace truncated_name = 1 if regexm(name_raw, "(有限公|有限|责任公|股份有|集团有)$")
replace truncated_name = 1 if regexm(name_raw, "[(（]$")
replace truncated_name = 1 if regexm(name_raw, "[(（]") & !regexm(name_raw, "[)）]")

order exp_id name_raw f_usadver f_usadver_value name_clean name_core name_key name_stub bad_name truncated_name abbrev_trunc
save "${temp_output}exp_usadver_clean.dta", replace
* ==============================================================================
* 3. Clean and standardize patent-applicant names
* ==============================================================================
use "${stata_output}Chinese_patents_filed_by_EL_otherfirms.dta", clear

rename fapp name_raw

gen name_clean = ustrtrim(name_raw)
replace name_clean = ustrregexra(name_clean, "\s+", "")

replace name_clean = subinstr(name_clean, "（", "(", .)
replace name_clean = subinstr(name_clean, "）", ")", .)
replace name_clean = subinstr(name_clean, "－", "-", .)
replace name_clean = subinstr(name_clean, "—", "-", .)
replace name_clean = subinstr(name_clean, "–", "-", .)

replace name_clean = ustrregexra(name_clean, "^\(已注销\)", "")
replace name_clean = ustrregexra(name_clean, "^（已注销）", "")
replace name_clean = ustrregexra(name_clean, "^已注销", "")
replace name_clean = ustrregexra(name_clean, "^【该企业已废止】", "")
replace name_clean = ustrregexra(name_clean, "^【已废止】", "")
replace name_clean = ustrregexra(name_clean, "^【已注销】", "")
replace name_clean = ustrregexra(name_clean, "^【吊销】", "")
replace name_clean = ustrregexra(name_clean, "[《》]", "")

replace name_clean = ustrregexra(name_clean, "^[,._\-\[\]【】]+", "")
replace name_clean = ustrregexra(name_clean, "[,._\-\[\]【】_]+$", "")
replace name_clean = ustrtrim(name_clean)

gen name_core = name_clean
replace name_core = ustrregexra(name_core, ///
"(集团股份有限公司|集团有限责任公司|集团有限公司|股份有限公司|有限责任公司|有限公司|集团公司|总公司|公司|有限公|有限)$", "")
replace name_core = ustrtrim(name_core)

gen name_key = name_core

gen bad_name = 0
replace bad_name = 1 if ustrlen(name_clean) <= 3
replace bad_name = 1 if regexm(name_clean, "[(]$")
replace bad_name = 1 if regexm(name_clean, "^[A-Za-z0-9\.\-]+$") & ustrlen(name_clean) <= 6

gen abbrev_trunc = 0
replace abbrev_trunc = 1 if regexm(name_clean, "^[A-Za-z0-9\.\-]+\($")
replace abbrev_trunc = 1 if regexm(name_clean, "^[A-Za-z0-9\.\-]+-$")
replace abbrev_trunc = 1 if regexm(name_clean, "^[A-Za-z0-9\.\-]+$") & ustrlen(name_clean) <= 5
replace bad_name = 1 if abbrev_trunc == 1

gen patent_firm = 1

order name_raw name_clean name_core name_key bad_name abbrev_trunc patent_firm
save "${temp_output}patent_firms_clean_raw.dta", replace
* ==============================================================================
* 4. Build a patent-applicant lookup table by cleaned name
* ==============================================================================
use "${temp_output}patent_firms_clean_raw.dta", clear

bysort name_clean: egen patent_count = total(patent_firm)
bysort name_clean: egen bad_name_pat = max(bad_name)
bysort name_clean: gen n_clean = _N

bysort name_clean (name_raw): keep if _n == 1

rename name_raw name_raw_pat

keep name_clean name_raw_pat patent_count name_core name_key bad_name_pat n_clean
save "${temp_output}patent_by_nameclean.dta", replace
* ==============================================================================
* 5. Build a patent-applicant lookup table by core name
* ==============================================================================
use "${temp_output}patent_firms_clean_raw.dta", clear

bysort name_core: egen patent_count = total(patent_firm)
bysort name_core: egen bad_name_pat = max(bad_name)
bysort name_core: gen n_core = _N

bysort name_core (name_raw): keep if _n == 1

rename name_raw name_raw_pat

keep name_core name_raw_pat patent_count bad_name_pat n_core
save "${temp_output}patent_by_namecore.dta", replace
* ==============================================================================
* 6. Build a patent-applicant lookup table by conservative key
* ==============================================================================
use "${temp_output}patent_firms_clean_raw.dta", clear

bysort name_key: egen patent_count = total(patent_firm)
bysort name_key: egen bad_name_pat = max(bad_name)
bysort name_key: gen n_key = _N

bysort name_key (name_raw): keep if _n == 1

rename name_raw name_raw_pat

keep name_key name_raw_pat patent_count bad_name_pat n_key
save "${temp_output}patent_by_namekey.dta", replace
* ==============================================================================
* 7. Match export firms on the cleaned name
* ==============================================================================
use "${temp_output}exp_usadver_clean.dta", clear

rename name_raw name_raw_exp

merge m:1 name_clean using "${temp_output}patent_by_nameclean.dta", ///
    keep(master match) gen(_m_clean)

gen final_match = 0
gen final_match_type = .

replace final_match = 1 if _m_clean == 3 & bad_name == 0 & truncated_name == 0
replace final_match_type = 1 if _m_clean == 3 & bad_name == 0 & truncated_name == 0

save "${temp_output}match_step1_cleanname.dta", replace
* ==============================================================================
* 8. Match remaining export firms on unique core names
* ==============================================================================
use "${temp_output}match_step1_cleanname.dta", clear

preserve
    keep if final_match == 0
    keep exp_id name_raw_exp f_usadver f_usadver_value name_clean name_core name_key name_stub ///
         bad_name truncated_name abbrev_trunc
    tempfile unmatched1
    save `unmatched1'
restore

use `unmatched1', clear
merge m:1 name_core using "${temp_output}patent_by_namecore.dta", ///
    keep(master match) gen(_m_core)

gen core_match_ok = 0
replace core_match_ok = 1 if _m_core == 3 & n_core == 1 & bad_name == 0 & truncated_name == 0

keep if core_match_ok == 1

gen final_match = 1
gen final_match_type = 2

save "${temp_output}match_step2_core_onlymatched.dta", replace
* ==============================================================================
* 9. Match remaining export firms on unique conservative keys
* ==============================================================================
capture erase "${temp_output}match_step3_key_onlymatched.dta"

* Start with unmatched cleaned-name records and remove core-name matches.
use "${temp_output}match_step1_cleanname.dta", clear
keep exp_id name_raw_exp f_usadver f_usadver_value name_clean name_core name_key name_stub ///
     bad_name truncated_name abbrev_trunc final_match final_match_type

tempfile base_step1
save `base_step1'

capture confirm file "${temp_output}match_step2_core_onlymatched.dta"
if _rc == 0 {
    use "${temp_output}match_step2_core_onlymatched.dta", clear
    keep exp_id
    duplicates drop exp_id, force
    tempfile step2_ids
    save `step2_ids'

    use `base_step1', clear
    merge m:1 exp_id using `step2_ids', keep(master match) gen(_m_step2id)
    keep if _m_step2id == 1
    drop _m_step2id
}

keep if missing(final_match_type)

drop final_match final_match_type

merge m:1 name_key using "${temp_output}patent_by_namekey.dta", ///
    keep(master match) gen(_m_key)

gen key_match_ok = 0
replace key_match_ok = 1 if _m_key == 3 & n_key == 1 & bad_name == 0 & truncated_name == 0

keep if key_match_ok == 1

gen final_match = 1
gen final_match_type = 3

count
if r(N) > 0 {
    save "${temp_output}match_step3_key_onlymatched.dta", replace
}
* ==============================================================================
* 10. Combine the sequential exact-match results
* ==============================================================================
use "${temp_output}match_step1_cleanname.dta", clear

count if missing(exp_id)
if r(N) > 0 {
    di as error "exp_id has missing values in match_step1_cleanname.dta"
    error 459
}

isid exp_id

* Merge successful core-name matches into the cleaned-name results.
capture confirm file "${temp_output}match_step2_core_onlymatched.dta"
if _rc == 0 {
    preserve
        use "${temp_output}match_step2_core_onlymatched.dta", clear
        count
        if r(N) > 0 {
            keep exp_id final_match final_match_type patent_count name_raw_pat
            duplicates drop exp_id, force
            tempfile step2_clean
            save `step2_clean'
            local do_step2 = 1
        }
        else {
            local do_step2 = 0
        }
    restore

    if `do_step2' == 1 {
        merge 1:1 exp_id using `step2_clean', keep(master match) gen(_m_step2) update replace
        drop _m_step2
    }
}

* Merge successful conservative-key matches into the combined results.
capture confirm file "${temp_output}match_step3_key_onlymatched.dta"
if _rc == 0 {
    preserve
        use "${temp_output}match_step3_key_onlymatched.dta", clear
        count
        if r(N) > 0 {
            keep exp_id final_match final_match_type patent_count name_raw_pat
            duplicates drop exp_id, force
            tempfile step3_clean
            save `step3_clean'
            local do_step3 = 1
        }
        else {
            local do_step3 = 0
        }
    restore

    if `do_step3' == 1 {
        merge 1:1 exp_id using `step3_clean', keep(master match) gen(_m_step3) update replace
        drop _m_step3
    }
}

replace final_match = 0 if missing(final_match)
replace patent_count = 0 if missing(patent_count)

gen has_patent = final_match
gen has_patent_strict = inlist(final_match_type, 1, 2)
gen has_patent_loose  = inlist(final_match_type, 1, 2, 3)

save "${temp_output}match_exact_combined.dta", replace
* ==============================================================================
* 11. Create the applicant-level export-exposure dataset
* ==============================================================================

* Extract the matched patent-applicant name for each export record.
use "${temp_output}match_exact_combined.dta", clear

keep exp_id final_match_type name_raw_pat

* Retain an applicant name only for successful matches.
gen fapp = name_raw_pat if !missing(final_match_type)

keep exp_id fapp
duplicates drop exp_id, force

tempfile matched_fapp
save `matched_fapp'

* Return to the original export data.
use "${stata_output}exp_usadver.dta", clear

gen exp_id = _n

* Merge the matched applicant names into the export records.
merge 1:1 exp_id using `matched_fapp', nogen

* Aggregate export measures to the matched patent-applicant level.
drop if fapp==""
collapse (max) f_usadver_dummy (mean) f_usadver (sum) f_usadver_value ///
(max) f_usadver_criarea_dummy (mean) f_usadver_criarea (sum) f_usadver_value_criarea ///
(firstnm) firm_name, by(fapp) //Resolve the many-to-one issue

save "${stata_output}exp_usadver_merge.dta", replace

* ==============================================================================
* 12. Remove intermediate cleaning and matching files
* ==============================================================================

erase ${temp_output}exp_usadver_clean.dta
erase ${temp_output}patent_firms_clean_raw.dta
erase ${temp_output}patent_by_nameclean.dta
erase ${temp_output}patent_by_namecore.dta
erase ${temp_output}patent_by_namekey.dta
erase ${temp_output}match_step1_cleanname.dta
erase ${temp_output}match_step2_core_onlymatched.dta
erase ${temp_output}match_exact_combined.dta
