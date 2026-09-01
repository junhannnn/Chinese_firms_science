****************************************************
* Match export firms with patent applicants
* Full do-file (final revised version)
****************************************************

clear all
set more off


capture cd ".\analytics\Sci_Pat\"
if _rc {
    capture cd "./analytics/Sci_Pat/"
}


global stata_output "../../stata_output/CN_CN/"
global temp_output  "../../temp_output/CN_CN/"

****************************************************
* Step 1. Clean export data
****************************************************
use "${stata_output}exp_usadver.dta", clear

* unique row id for later merges
gen exp_id = _n

rename firm_name name_raw

* 1.1 Basic normalization
gen name_clean = ustrtrim(name_raw)
replace name_clean = ustrregexra(name_clean, "\s+", "")

* unify brackets and dash types
replace name_clean = subinstr(name_clean, "（", "(", .)
replace name_clean = subinstr(name_clean, "）", ")", .)
replace name_clean = subinstr(name_clean, "－", "-", .)
replace name_clean = subinstr(name_clean, "—", "-", .)
replace name_clean = subinstr(name_clean, "–", "-", .)

* 1.2 Remove full labels first
replace name_clean = ustrregexra(name_clean, "^\(已注销\)", "")
replace name_clean = ustrregexra(name_clean, "^（已注销）", "")
replace name_clean = ustrregexra(name_clean, "^已注销", "")
replace name_clean = ustrregexra(name_clean, "^【该企业已废止】", "")
replace name_clean = ustrregexra(name_clean, "^【已废止】", "")
replace name_clean = ustrregexra(name_clean, "^【已注销】", "")
replace name_clean = ustrregexra(name_clean, "^【吊销】", "")

* remove book-title marks
replace name_clean = ustrregexra(name_clean, "[《》]", "")

* 1.3 Remove leading/trailing junk characters
replace name_clean = ustrregexra(name_clean, "^[,._\-\[\]【】]+", "")
replace name_clean = ustrregexra(name_clean, "[,._\-\[\]【】_]+$", "")
replace name_clean = ustrtrim(name_clean)

* 1.4 Core name: remove common legal suffixes
gen name_core = name_clean
replace name_core = ustrregexra(name_core, ///
"(集团股份有限公司|集团有限责任公司|集团有限公司|股份有限公司|有限责任公司|有限公司|集团公司|总公司|公司|有限公|有限)$", "")
replace name_core = ustrtrim(name_core)

* 1.5 Conservative key
gen name_key = name_core

* 1.6 Flag bad names
gen bad_name = 0
replace bad_name = 1 if ustrlen(name_clean) <= 3
replace bad_name = 1 if regexm(name_clean, "[(]$")
replace bad_name = 1 if regexm(name_clean, "^[A-Za-z0-9\.\-]+$") & ustrlen(name_clean) <= 6

* short English abbreviation / truncated abbreviation
gen abbrev_trunc = 0
replace abbrev_trunc = 1 if regexm(name_clean, "^[A-Za-z0-9\.\-]+\($")
replace abbrev_trunc = 1 if regexm(name_clean, "^[A-Za-z0-9\.\-]+-$")
replace abbrev_trunc = 1 if regexm(name_clean, "^[A-Za-z0-9\.\-]+$") & ustrlen(name_clean) <= 5
replace bad_name = 1 if abbrev_trunc == 1

* helper stub: remove trailing incomplete symbols, but do NOT use for auto merge
gen name_stub = name_clean
replace name_stub = ustrregexra(name_stub, "[(\-]+$", "")
replace name_stub = ustrtrim(name_stub)

* 1.7 Flag truncated names
gen truncated_name = 0
replace truncated_name = 1 if regexm(name_raw, "(有限公|有限|责任公|股份有|集团有)$")
replace truncated_name = 1 if regexm(name_raw, "[(（]$")
replace truncated_name = 1 if regexm(name_raw, "[(（]") & !regexm(name_raw, "[)）]")

order exp_id name_raw f_usadver f_usadver_value name_clean name_core name_key name_stub bad_name truncated_name abbrev_trunc
save "${temp_output}exp_usadver_clean.dta", replace


****************************************************
* Step 2. Clean patent applicant data (raw cleaned file)
****************************************************
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


****************************************************
* Step 3. Build unique patent table by name_clean
****************************************************
use "${temp_output}patent_firms_clean_raw.dta", clear

bysort name_clean: egen patent_count = total(patent_firm)
bysort name_clean: egen bad_name_pat = max(bad_name)
bysort name_clean: gen n_clean = _N

bysort name_clean (name_raw): keep if _n == 1

rename name_raw name_raw_pat

keep name_clean name_raw_pat patent_count name_core name_key bad_name_pat n_clean
save "${temp_output}patent_by_nameclean.dta", replace


****************************************************
* Step 4. Build unique patent table by name_core
****************************************************
use "${temp_output}patent_firms_clean_raw.dta", clear

bysort name_core: egen patent_count = total(patent_firm)
bysort name_core: egen bad_name_pat = max(bad_name)
bysort name_core: gen n_core = _N

bysort name_core (name_raw): keep if _n == 1

rename name_raw name_raw_pat

keep name_core name_raw_pat patent_count bad_name_pat n_core
save "${temp_output}patent_by_namecore.dta", replace


****************************************************
* Step 5. Build unique patent table by name_key
****************************************************
use "${temp_output}patent_firms_clean_raw.dta", clear

bysort name_key: egen patent_count = total(patent_firm)
bysort name_key: egen bad_name_pat = max(bad_name)
bysort name_key: gen n_key = _N

bysort name_key (name_raw): keep if _n == 1

rename name_raw name_raw_pat

keep name_key name_raw_pat patent_count bad_name_pat n_key
save "${temp_output}patent_by_namekey.dta", replace


****************************************************
* Step 6. Exact match on name_clean
****************************************************
use "${temp_output}exp_usadver_clean.dta", clear

rename name_raw name_raw_exp

merge m:1 name_clean using "${temp_output}patent_by_nameclean.dta", ///
    keep(master match) gen(_m_clean)

gen final_match = 0
gen final_match_type = .

replace final_match = 1 if _m_clean == 3 & bad_name == 0 & truncated_name == 0
replace final_match_type = 1 if _m_clean == 3 & bad_name == 0 & truncated_name == 0

save "${temp_output}match_step1_cleanname.dta", replace


****************************************************
* Step 7. Exact match on name_core
****************************************************
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


****************************************************
* Step 8. Exact match on name_key
****************************************************
capture erase "${temp_output}match_step3_key_onlymatched.dta"

* start from step1 and remove exp_id already matched in step2
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


****************************************************
* Step 9. Combine all exact-match results
****************************************************
use "${temp_output}match_step1_cleanname.dta", clear

count if missing(exp_id)
if r(N) > 0 {
    di as error "exp_id has missing values in match_step1_cleanname.dta"
    error 459
}

isid exp_id

* step2 merge back
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

* step3 merge back
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


****************************************************
* Final step. Create exp_usadver_merge.dta
* Keep original export data and add fapp
****************************************************

* 1. Extract exp_id and the matched patent applicant name from the match results
use "${temp_output}match_exact_combined.dta", clear

keep exp_id final_match_type name_raw_pat

* Keep fapp only for successful matches
gen fapp = name_raw_pat if !missing(final_match_type)

keep exp_id fapp
duplicates drop exp_id, force

tempfile matched_fapp
save `matched_fapp'

* 2. Return to the original export data
use "${stata_output}exp_usadver.dta", clear

gen exp_id = _n

* 3. Merge in fapp
merge 1:1 exp_id using `matched_fapp', nogen

* 4. Save the final file
drop if fapp==""
collapse (max) f_usadver_dummy (mean) f_usadver (sum) f_usadver_value ///
(max) f_usadver_criarea_dummy (mean) f_usadver_criarea (sum) f_usadver_value_criarea ///
(firstnm) firm_name, by(fapp) //Resolve the many-to-one issue

save "${stata_output}exp_usadver_merge.dta", replace



erase ${temp_output}exp_usadver_clean.dta
erase ${temp_output}patent_firms_clean_raw.dta
erase ${temp_output}patent_by_nameclean.dta
erase ${temp_output}patent_by_namecore.dta
erase ${temp_output}patent_by_namekey.dta
erase ${temp_output}match_step1_cleanname.dta
erase ${temp_output}match_step2_core_onlymatched.dta
erase ${temp_output}match_exact_combined.dta
