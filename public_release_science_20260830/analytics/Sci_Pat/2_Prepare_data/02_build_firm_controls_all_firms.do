/*******************************************************************************
Project: CN Patents — Firm-Level Controls (All Firms)
Script: 02_build_firm_controls_all_firms.do

Purpose
  - Construct patent- and firm-level control variables from CN patent data:
      (i) applicant province, (ii) founding year, (iii) IPC subclass measures,
      (iv) SOE indicator, (v) relative competitive advantage based on US patents,
      (vi) collaboration indicators (firm–university, firm–firm),
      (vii) citation-based mechanisms (US vs. domestic vs. foreign citations).
  - Outputs are designed to be merged downstream using application number (apn)
    or standardized firm name (fapp_standard).

Inputs
  - CN patent database (Stata):
      ${CN_patents}add.dta      (province codes / location fields)
      ${CN_patents}ipc.dta      (IPC strings)
      ${CN_patents}app.dta      (applicant lists / applicant types)
      ${CN_patents}businfo.dta  (firm registry attributes, incl. company type)
  - CN–US linked patent data (Stata):
      ${CN_US}ipc.dta
      ${CN_US}USpatent_location.dta
  - Python-processed intermediates (CSV):
      ${python_output}businfo_founding_date.csv
      ${python_output}CNpat_citepat_country.csv

Outputs (saved under ${stata_output})
  - CNpatents_province.dta
  - CNpatents_founding_year.dta
  - CNpatents_mainipc.dta
  - CNpatents_allipc.dta
  - CNpatents_soe.dta
  - relative_competitive_based_USpatents.dta
  - CNpatents_relative_competitive_mainipc.dta
  - CNpatents_relative_competitive_allipc.dta
  - CNpatents_firm_copatent_uni.dta
  - CNpatents_firm_copatent_firm.dta
  - CNpat_cite_uspat.dta
  - (placeholders in this script header, if present later in file:)
      CNpat_US_priority.dta
      CNpat_USapp_license.dta

Temporary files (saved under ${temp_output})
  - app.dta
    (created and erased within the script)

Notes
  - Key identifiers:
      apn = patent application number
      fapp_standard = cleaned standardized applicant name
  - Relative competitive advantage is defined at IPC-subclass level using US patents:
      share_CN(ipc) = (# US patents with disambig_country == "CN") / (all US patents in ipc).
*******************************************************************************/
* Run via `00_run_all_2.do` (depends on shared path globals set by the runner).




********************************************************************************
* Province for all firms (listed + unlisted)
********************************************************************************
* Note: add.txt can be merged to obtain province.

use ${CN_patents}add.dta, clear

keep if 申请人国家地区 == "中国"
keep 申请号 申请人省市代码
duplicates drop

rename 申请人省市代码 province_id
rename 申请号          apn

* Keep variables needed for output (province must exist in the source data)
keep apn province province_id

* Exclude HK/MO/TW and missing province codes
drop if province_id == "HK" | province_id == "MO" | province_id == "TW"
drop if province_id == ""

destring province_id, replace

save ${stata_output}CNpatents_province.dta, replace   // vars: apn province province_id


********************************************************************************
* Founding year for all firms (listed + unlisted)
********************************************************************************
* Note: `businfo.txt` can be merged to obtain firm founding dates.

import delimited ${python_output}businfo_founding_date.csv, ///
    varnames(1) clear

* Remove non-alphanumeric characters, then extract year
gen clean_found_date = ustrregexra(found_date, "[^a-zA-Z0-9]", "")

gen founding_year = substr(clean_found_date, 1, 4)
destring founding_year, replace
replace founding_year = . if founding_year == 0

keep apn founding_year
duplicates drop
tab founding_year

save ${stata_output}CNpatents_founding_year.dta, replace   // vars: apn founding_year


********************************************************************************
* Industry proxy via IPC (all firms)
********************************************************************************

********************************
* Main IPC subclass (first 4 chars)
********************************
use ${CN_patents}ipc.dta, clear
rename 申请号 apn

keep apn ipc
gen ipc_subclass = substr(ipc, 1, 4)

keep apn ipc_subclass
duplicates drop

save ${stata_output}CNpatents_mainipc.dta, replace   // vars: apn ipc_subclass


********************************
* All IPC subclasses (split and reshape long)
********************************
use ${CN_patents}ipc.dta, clear

split ipc, p("; ")
drop ipc ipc11-ipc260

foreach var of varlist ipc1-ipc10 {
    replace `var' = substr(`var', 1, 4)
}

rename 申请号 apn

duplicates drop
duplicates drop apn, force

reshape long ipc, i(apn) j(ipc_order)
rename ipc ipc_subclass

drop if ipc_subclass == ""

save ${stata_output}CNpatents_allipc.dta, replace   // vars: apn ipc_subclass


********************************************************************************
* SOE indicator (state-owned enterprise)
********************************************************************************

* Step 1: patent-level applicant info
use ${CN_patents}app.dta, clear
keep 申请号 标准化申请人 申请人 申请人数量
duplicates drop 申请号, force
save ${temp_output}app.dta, replace

* Step 2: firm registry info (SOE classification)
use ${CN_patents}businfo.dta, clear
order 申请号 工商别名 工商公司类型

gen SOE = 0
replace SOE = 1 if regexm(工商公司类型, "国有")

keep 申请号 工商别名 工商公司类型 SOE
duplicates drop

* Step 3: merge to applicant info and keep single-applicant patents
merge 1:1 申请号 using ${temp_output}app.dta
drop if _merge == 2
drop _merge

keep if 申请人数量 == 1
keep 标准化申请人 SOE
duplicates drop

* Clean bracket characters in standardized applicant string
gen fapp_standard = 标准化申请人
replace fapp_standard = subinstr(fapp_standard, "[", "", .)
replace fapp_standard = subinstr(fapp_standard, "]", "", .)

keep fapp_standard SOE
order fapp_standard SOE

* Firm-level SOE: max across its patents
bys fapp_standard: egen soe = max(SOE)
keep fapp_standard soe
duplicates drop

save ${stata_output}CNpatents_soe.dta, replace

erase ${temp_output}app.dta


********************************************************************************
* Relative competitive advantage (IPC-level, based on US patents)
********************************************************************************
* Workflow:
*   US patents (IPC-level) -> compute China's share within each IPC subclass
*   Then map to China patents (patent-level), and later aggregate to firm-year

use ${CN_US}ipc.dta, clear
merge 1:1 patent_id using ${CN_US}USpatent_location.dta
keep if _merge == 3

keep patent_id ipc disambig_country

gen China = 0
replace China = 1 if disambig_country == "CN"

bys ipc: gen num = _N
bys ipc: egen China_num = sum(China)

* China's relative position in this IPC = China count / total count
gen relative_competitive = China_num / num

keep ipc relative_competitive
duplicates drop

rename ipc ipc_subclass

save ${stata_output}relative_competitive_based_USpatents.dta, replace   // vars: ipc_subclass relative_competitive


********************************************************************************
* Map relative competitive advantage to China patents (patent-level)
********************************************************************************

* Main IPC mapping: one IPC subclass per patent
use ${stata_output}CNpatents_mainipc.dta, clear   // vars: apn ipc_subclass
merge m:1 ipc_subclass using ${stata_output}relative_competitive_based_USpatents.dta
keep if _merge == 3
drop _merge ipc_subclass

save ${stata_output}CNpatents_relative_competitive_mainipc.dta, replace   // vars: apn relative_competitive


* All IPC mapping: average across subclasses within patent
use ${stata_output}CNpatents_allipc.dta, clear   // vars: apn ipc_subclass
merge m:1 ipc_subclass using ${stata_output}relative_competitive_based_USpatents.dta
keep if _merge == 3
drop _merge

drop if apn == ""
collapse (mean) relative_competitive, by(apn)
rename relative_competitive relative_competitive2

save ${stata_output}CNpatents_relative_competitive_allipc.dta, replace   // vars: apn relative_competitive2


********************************************************************************
* Moderator: firm–university collaboration (co-filed patents)
********************************************************************************

use ${CN_patents}app.dta, clear
drop if 申请人数量 == 1

gen filed_firm = 0
replace filed_firm = 1 if strpos(申请人类型, "企业") > 0

gen filed_uni = 0
replace filed_uni = 1 if strpos(申请人类型, "大专院校") > 0 | ///
                        strpos(申请人类型, "科研单位") > 0 | ///
                        strpos(申请人类型, "学校") > 0

* Keep patents filed by both firm and university
keep if filed_firm == 1 & filed_uni == 1

keep 申请号
rename 申请号 apn
duplicates drop

gen firm_uni = 1
label var firm_uni "1=filed by both firm and university"

save ${stata_output}CNpatents_firm_copatent_uni.dta, replace   // vars: apn firm_uni


********************************************************************************
* Moderator: firm–firm collaboration (co-filed patents with other firms only)
********************************************************************************

use ${CN_patents}app.dta, clear
drop if 申请人数量 == 1

gen filed_firm = 0
replace filed_firm = 1 if strpos(申请人类型, "企业") > 0

gen filed_other = 0
replace filed_other = 1 if strpos(申请人类型, "大专院校") > 0 | ///
                          strpos(申请人类型, "科研单位") > 0 | ///
                          strpos(申请人类型, "学校") > 0 | ///
                          strpos(申请人类型, "个人") > 0 | ///
                          strpos(申请人类型, "机关团体") > 0 | ///
                          strpos(申请人类型, "其他") > 0

* Keep patents filed by firm(s) and no non-firm entity types
keep if filed_firm == 1 & filed_other == 0

keep 申请号
rename 申请号 apn
duplicates drop

gen firm_colla_firm = 1
label var firm_colla_firm "1=filed by both firm and firm"

save ${stata_output}CNpatents_firm_copatent_firm.dta, replace   // vars: apn firm_colla_firm


********************************************************************************
* Mechanism: citations of US patents (China patents citing US patents)
********************************************************************************

import delimited ${python_output}CNpat_citepat_country.csv, ///
    varnames(1) stringcols(1) clear

keep apn us_sum us_ratio ///
     domestic_sum domestic_ratio ///
     foreign_sum foreign_ratio ///
     nonus_foreign_sum nonus_foreign_ratio

duplicates drop
duplicates drop apn, force   // drop 1 obs

label var us_sum            "Citation count of US patents"
label var us_ratio          "Citation count of US patents / citation count of all patents"

label var domestic_sum      "Citation count of CN patents"
label var domestic_ratio    "Citation count of CN patents / citation count of all patents"

label var foreign_sum       "Citation count of foreign patents"
label var foreign_ratio     "Citation count of foreign patents / citation count of all patents"

label var nonus_foreign_sum      "Citation count of non-US foreign patents"
label var nonus_foreign_ratio    "Citation count of non-US foreign patents / citation count of all patents"

save ${stata_output}CNpat_cite_uspat.dta, replace   // vars: apn us_sum us_ratio ...
