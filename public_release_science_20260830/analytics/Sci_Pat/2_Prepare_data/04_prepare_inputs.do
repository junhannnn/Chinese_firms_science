/*******************************************************************************
Project: CN Patents — Analysis Inputs Preparation
Script: 04_prepare_inputs.do

Purpose
  - Prepare auxiliary inputs and patent-level exploration measures:
      (i) firm appearance on other regulatory lists,
      (ii) mapping from patent application (apn) to listed-firm identifiers,
      (iii) patent exploration indicators based on IPC combinations.

Inputs
  - Other lists (Excel):
      ${raw_data}Other_lists.xlsx  (sheet "Sheet1")
  - CN patent firm registry (Stata):
      ${CN_patents}businfo.dta     (Unified Social Credit Code; listing code)
  - Patent IPC and application year (Stata):
      ${stata_output}CNpatents_allipc.dta
      ${stata_output}CNpatents_year.dta

Outputs (saved under ${stata_output})
  - Other_lists.dta
      vars: fapp otherlist_year
  - apn_firmcode.dta
      vars: apn applicant_slot SocialCreditCode Symbol SymbolSuffix
      (slot-level mapping; preserves empty listing-code slots)
  - apn_exploration.dta
      vars: apn new_com new_pairwise

Temporary files (saved under ${temp_output})
  - apn_newcomb.dta
  - ipc_long.dta, ipc1.dta, ipc2.dta
  - apn_new_pairwise_morethan2.dta
  - apn_new_pairwise.dta
  (created and erased within the script)

Notes
  - "Other list" date is collapsed to the earliest observed List_time per firm.
    (Variable name is otherlist_year for historical compatibility.)
  - new_com flags whether an IPC-subclass *set* (within a patent) appears for the
    first time in a given application year.
  - new_pairwise flags whether any IPC-subclass *pair* within a patent appears
    for the first time in a given application year.
*******************************************************************************/
* Run via `00_run_all_2.do` (depends on shared path globals set by the runner).




********************************************************************************
* Prepare
********************************************************************************


********************************************************************************
* (1) Other lists
********************************************************************************

import excel ${raw_data}Other_lists.xlsx, sheet("Sheet1") firstrow clear

drop if fapp == ""
keep fapp List_time
duplicates drop

* Earliest listing year across other lists for each firm.
* Note: Some firms appear in multiple lists with different dates.
bys fapp: egen otherlist_year = min(List_time)

keep fapp otherlist_year
duplicates drop

sort fapp    // ~12 firms require regex-based matching later
save ${stata_output}Other_lists.dta, replace   // vars: fapp otherlist_year


********************************************************************************
* (2) Chinese patents filed by Chinese listed firms (granted 1985–2023)
********************************************************************************

* Generated externally by 03_build_apn_firmcode.ipynb (Python notebook), run before this do-file.


********************************************************************************
* (3) Patent exploration
********************************************************************************
* Two indicators:
*   - new_com: first occurrence year of the full IPC-subclass combination (within patent)
*   - new_pairwise: first occurrence year of any IPC pair within the patent


********************************************************************************
* (3.1) New full combination (set of IPC subclasses within a patent)
********************************************************************************

use ${stata_output}CNpatents_allipc.dta, clear
bysort apn ipc_subclass: keep if _n == 1

merge m:1 apn using ${stata_output}CNpatents_year.dta
drop _merge

bysort apn (ipc_subclass): gen ord2 = _n
tostring ord2, gen(ord2s) format("%02.0f")

keep apn ipc_subclass ord2s appyr
reshape wide ipc_subclass, i(apn) j(ord2s) string

egen combo = concat(ipc_subclass*), p(" ")

keep apn appyr combo
egen first_yr = min(appyr), by(combo)
gen new_com = (appyr == first_yr)

keep apn new_com
save ${temp_output}apn_newcomb.dta, replace   // vars: apn new_com


********************************************************************************
* (3.2) New pairwise combination (any IPC-subclass pair within a patent)
********************************************************************************

use ${stata_output}CNpatents_allipc.dta, clear
bysort apn ipc_subclass: keep if _n == 1

merge m:1 apn using ${stata_output}CNpatents_year.dta
drop _merge

keep apn ipc_subclass appyr
save ${temp_output}ipc_long.dta, replace

* Create two copies for within-patent pair construction via joinby
use ${temp_output}ipc_long.dta, clear
rename ipc_subclass ipc1
save ${temp_output}ipc1.dta, replace

use ${temp_output}ipc_long.dta, clear
rename ipc_subclass ipc2
save ${temp_output}ipc2.dta, replace

use ${temp_output}ipc1.dta, clear
joinby apn using ${temp_output}ipc2.dta

* Remove self-pairs; sort within pair to make unordered pair unique
drop if ipc1 == ipc2
gen strL sorted1 = cond(ipc1 < ipc2, ipc1, ipc2)
gen strL sorted2 = cond(ipc1 < ipc2, ipc2, ipc1)
gen pair = sorted1 + " " + sorted2
drop ipc1 ipc2 sorted1 sorted2

* First year a pair appears (globally); then patent-level indicator
bysort pair: egen first_pair_year = min(appyr)
gen new_pair = (appyr == first_pair_year)

bysort apn: egen new_pairwise = max(new_pair)

keep apn new_pairwise
duplicates drop
save ${temp_output}apn_new_pairwise_morethan2.dta, replace

* Ensure patents with only 1 IPC subclass are included with new_pairwise = 0
use ${temp_output}ipc_long.dta, clear
keep apn
duplicates drop

merge m:1 apn using ${temp_output}apn_new_pairwise_morethan2.dta, ///
    keepusing(new_pairwise)

replace new_pairwise = 0 if missing(new_pairwise)
drop _merge

save ${temp_output}apn_new_pairwise.dta, replace


********************************************************************************
* (3.3) Combine exploration measures and export
********************************************************************************

use ${temp_output}apn_newcomb.dta, clear
merge 1:1 apn using ${temp_output}apn_new_pairwise.dta
drop _merge

save ${stata_output}apn_exploration.dta, replace


********************************************************************************
* Cleanup temporary files
********************************************************************************

erase ${temp_output}ipc_long.dta
erase ${temp_output}ipc1.dta
erase ${temp_output}ipc2.dta
erase ${temp_output}apn_new_pairwise_morethan2.dta
erase ${temp_output}apn_newcomb.dta
erase ${temp_output}apn_new_pairwise.dta


********************************************************************************
* (4) Patent-paper similarity
********************************************************************************

************************* Calculate: CNKI science closeness ********************

import delimited ${CN_patents_simi}CNpat_CNKIpaper_similarity/sim100.txt, clear

bys apn: egen cnki_closeness_mean = mean(sim)
bys apn: egen cnki_closeness_med = median(sim)
bys apn: egen cnki_closeness_max = max(sim)
keep apn cnki_closeness_mean cnki_closeness_med cnki_closeness_max
duplicates drop

label var cnki_closeness_mean "Mean patent-paper similarity among the top 10 most similar CNKI papers"
label var cnki_closeness_med "Median patent-paper similarity among the top 10 most similar CNKI papers"
label var cnki_closeness_max "Max patent-paper similarity among the top 10 most similar CNKI papers"

format apn %15.0g
rename apn apn_num

save ${stata_output}science_closeness_cnki.dta, replace //Patent-level. var: apn_num cnki_closeness_mean cnki_closeness_med cnki_closeness_max



************ Calculate: international journal science closeness ****************

import delimited ${CN_patents_simi}CNpat_internationalpaper_similarity/sim100.txt, clear

bys apn: egen wos_closeness_mean = mean(sim)
bys apn: egen wos_closeness_med = median(sim)
bys apn: egen wos_closeness_max = max(sim)
keep apn wos_closeness_mean wos_closeness_med wos_closeness_max
duplicates drop

label var wos_closeness_mean "Mean patent-paper similarity among the top 10 most similar WOS papers"
label var wos_closeness_med "Median patent-paper similarity among the top 10 most similar WOS papers"
label var wos_closeness_max "Max patent-paper similarity among the top 10 most similar WOS papers"

format apn %15.0g
rename apn apn_num

save ${stata_output}science_closeness_int.dta, replace //Patent-level. var: apn_num wos_closeness_mean wos_closeness_med wos_closeness_max

