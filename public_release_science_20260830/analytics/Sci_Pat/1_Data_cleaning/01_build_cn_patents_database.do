
/*******************************************************************************
Project: CN Patents (1985–2025) — Data Build (ETL)
Script: 01_build_cn_patents_database.do

Purpose
  - Harmonize raw CN patent extracts (1985–2023 .txt + 2024–2025 .dta/.csv)
    into standardized Stata datasets.

Inputs
  - Raw patent extracts:
      ${raw_CN_patents1} (1985–2023)
      ${raw_CN_patents2} (2024–2025)

Outputs (saved under ${CN_patents})
  - date.dta
  - app.dta
  - add.dta
  - businfo.dta
  - ipc.dta
  - citation.dta

Notes
  - This script is the ETL foundation for downstream analysis scripts.
  - The patent application-number field is standardized via helper program `std_apn_simple`.
*******************************************************************************/
* Run via `00_run_all_1.do` (depends on shared path globals set by the runner).



/***********************************************************************
  Helper: Standardize the application-number field to `apn_simple`
  Logic intentionally identical to original repeated block:
    apn1 = substr(<application_number>, 3, .)
    apn_simple = substr(apn1, 1, strpos(apn1, ".") - 1) +
                 substr(apn1, strpos(apn1, ".") + 2, .)
  Then replace the original application-number field with `apn_simple` and order it first.
***********************************************************************/
capture program drop std_apn_simple
program define std_apn_simple
    version 18.0

    gen apn1       = substr(申请号, 3, .)
    gen apn_simple = substr(apn1, 1, strpos(apn1, ".") - 1) + ///
                     substr(apn1, strpos(apn1, ".") + 2, .)

    drop apn1 申请号
    rename apn_simple 申请号
    order 申请号
end


********************************************************************************
*********************** (1) Chinese patent: date *******************************
********************************************************************************

/*** (1) 1985–2023 ***/
import delimited "${raw_CN_patents1}date.txt", varnames(1) clear

/*
Raw columns:
application number, application date, first publication number, first publication date,
grant announcement number, grant announcement date, substantive examination effective date, lapse date
*/

foreach var in 申请日 首次公开日 授权公告日 实质审查生效日 失效日 {
    gen `var'_d = date(`var', "YMD")
    format `var'_d %tdCCYY/NN/DD
}

drop 申请日 首次公开日 授权公告日 实质审查生效日 失效日

rename 申请日_d         申请日
rename 首次公开日_d     首次公开日
rename 授权公告日_d     授权公告日
rename 实质审查生效日_d 实质审查生效日
rename 失效日_d         失效日

* Standardize the application-number field
std_apn_simple

save "${temp_output}date_1.dta", replace


/*** (2) 2024–2025 ***/
* Recent years are already stored in Stata format with different column names.
use "${raw_CN_patents2}date.dta", clear

/*
Columns (raw):
apn appdate pubno pubdate grtno grtdate examdate lapsedate
*/
rename apn       申请号
rename appdate   申请日
rename pubno     首次公开号
rename pubdate   首次公开日
rename grtno     授权公告号
rename grtdate   授权公告日
rename examdate  实质审查生效日
rename lapsedate 失效日

save "${temp_output}date_2.dta", replace


/*** (3) Merge ***/
* Append historical and recent vintages, then save one harmonized table.
use "${temp_output}date_1.dta", clear
append using "${temp_output}date_2.dta"
duplicates drop

save "${CN_patents}date.dta", replace

erase "${temp_output}date_1.dta"
erase "${temp_output}date_2.dta"



********************************************************************************
*********************** (2) Chinese patent: app ********************************
********************************************************************************

/*** (1) 1985–2023 ***/
import delimited "${raw_CN_patents1}app.txt", varnames(1) clear

/*
Raw columns:
application number, applicants, standardized applicants, first applicant, applicant type, applicant count
*/

* Standardize the application-number field
std_apn_simple

save "${temp_output}app_1.dta", replace


/*** (2) 2024–2025 ***/
use "${raw_CN_patents2}app.dta", clear

recast str225 fstapp

rename apn     申请号
rename app     申请人
rename stdapp  标准化申请人
rename fstapp  第一申请人
rename apptype 申请人类型
rename appno   申请人数量

save "${temp_output}app_2.dta", replace


/*** (3) Merge ***/
use "${temp_output}app_1.dta", clear
append using "${temp_output}app_2.dta"
duplicates drop

save "${CN_patents}app.dta", replace

erase "${temp_output}app_1.dta"
erase "${temp_output}app_2.dta"



********************************************************************************
*********************** (3) Chinese patent: add ********************************
********************************************************************************

/*** (1) 1985–2023 ***/
import delimited "${raw_CN_patents1}add.txt", varnames(1) clear

/*
Raw columns:
application number, applicant country/region, applicant address, applicant province/city code,
Chinese applicant city, Chinese applicant county
*/

* Standardize the application-number field
std_apn_simple

save "${temp_output}add_1.dta", replace


/*** (2) 2024–2025 ***/
use "${raw_CN_patents2}add.dta", clear

rename apn      申请号
rename add      申请人地址
rename ctry     申请人国家地区
rename areacode 申请人省市的代码
rename city     中国申请人地市
rename county   中国申请人区县

keep 申请号 申请人国家地区 申请人地址 申请人省市的代码 中国申请人地市 中国申请人区县
save "${temp_output}add_2.dta", replace


/*** (3) Merge + harmonize ***/
use "${temp_output}add_1.dta", clear
append using "${temp_output}add_2.dta"

* Harmonize province/city code field across vintages:
* extract the 2-char code when embedded in a text pattern (e.g., "...; XX").
replace 申请人省市的代码 = regexs(1) ///
    if !missing(申请人省市代码) & ///
       regexm(申请人省市代码, ";\s*([A-Za-z0-9]{2})")

drop 申请人省市代码
rename 申请人省市的代码 申请人省市代码

order 申请号 申请人国家地区 申请人省市代码
keep 申请号 申请人国家地区 申请人省市代码

duplicates drop
duplicates drop 申请号, force

save "${CN_patents}add.dta", replace

erase "${temp_output}add_1.dta"
erase "${temp_output}add_2.dta"



********************************************************************************
********************* (4) Chinese patent: businfo ******************************
********************************************************************************

/*** (1) 1985–2023 ***/
import delimited "${raw_CN_patents1}businfo.txt", bindquote(strict) varnames(1) clear

/*
Raw columns:
application number, business alias, business English name, business registered address, business entity type,
business founding date, unified social credit code, business registration number, listed-company code, business status
*/

* Keep only used fields (drop registered address and business status)
keep 申请号 工商别名 工商英文名 工商统一社会信用代码 工商注册号 ///
     工商上市代码 工商成立日期 工商公司类型

* Standardize the application-number field
std_apn_simple

save "${temp_output}businfo_1.dta", replace


/*** (2) 2024–2025 ***/
use "${raw_CN_patents2}businfo.dta", clear

rename apn      申请号
rename name     工商别名
rename en_name  工商英文名
rename creditno 工商统一社会信用代码
rename regno    工商注册号
rename stkcode  工商上市代码

recast str300 工商统一社会信用代码

save "${temp_output}businfo_2.dta", replace


/*** (3) Merge ***/
use "${temp_output}businfo_1.dta", clear
append using "${temp_output}businfo_2.dta"
duplicates drop
duplicates drop 申请号, force

save "${CN_patents}businfo.dta", replace

erase "${temp_output}businfo_1.dta"
erase "${temp_output}businfo_2.dta"



********************************************************************************
*********************** (5) Chinese patent: ipc ********************************
********************************************************************************

/*** (1) 1985–2023 ***/
import delimited "${raw_CN_patents1}ipc.txt", delimiter("|") varnames(1) clear

/*
Raw columns:
application number, IPC, national economic classification, subject classification
*/

* Standardize the application-number field
std_apn_simple

keep 申请号 ipc
save "${temp_output}ipc_1.dta", replace


/*** (2) 2024–2025 ***/
use "${raw_CN_patents2}ipc.dta", clear

keep apn ipc
rename apn 申请号

save "${temp_output}ipc_2.dta", replace


/*** (3) Merge ***/
use "${temp_output}ipc_1.dta", clear
append using "${temp_output}ipc_2.dta"
duplicates drop

save "${CN_patents}ipc.dta", replace

erase "${temp_output}ipc_1.dta"
erase "${temp_output}ipc_2.dta"



********************************************************************************
******************** (6) Chinese patent: citation ******************************
********************************************************************************

/*** (1) 1985–2023 ***/
import delimited "${raw_CN_patents1}citation.txt", delimiter("|") varnames(1) clear

/*
Raw columns:
application number, cited patent, self-citation info, external-citation info, citation type,
citation source, cited scientific literature
*/
keep 申请号 引证专利
duplicates drop

save "${temp_output}citation_1.dta", replace


/*** (2) 2024–2025 ***/
import delimited "${raw_CN_patents2}citations/pat_citations.csv", varnames(1) clear

rename apn   申请号
rename cited 引证专利

keep 申请号 引证专利
duplicates drop

sort 申请号 引证专利
by 申请号: gen cites = 引证专利 if _n == 1
by 申请号: replace cites = cites[_n-1] + "; " + 引证专利 if _n > 1
by 申请号: keep if _n == _N

keep 申请号 cites
rename cites 引证专利

save "${temp_output}citation_2.dta", replace


/*** (3) Merge + standardize application number ***/
use "${temp_output}citation_1.dta", clear
append using "${temp_output}citation_2.dta"

* Re-standardize application number after append to keep one common key format.
* Standardize the application-number field
std_apn_simple

duplicates drop
save "${CN_patents}citation.dta", replace

erase "${temp_output}citation_1.dta"
erase "${temp_output}citation_2.dta"
