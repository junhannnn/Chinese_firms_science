/*******************************************************************************
Project: Entity List (EL) — Background Descriptives
Script: 01_descriptive_statistics_el_firms.do

Purpose
  - Produce descriptive figures summarizing Chinese firms on the U.S. Entity List:
      (i) top provinces, (ii) top industries,
      (iii) annual inflow onto the Entity List.
  - Report reference tabulations for EL composition (Type1/Type2/Type3).
  - Count Huawei-related entries in EL_800.xlsx via string match on `名称`.

Inputs
  - Firm registry / background (Excel):
      ${other_data}EL_Chinesefirm_qichacha_info.xlsx  (sheet "1")
  - Entity List master file (Excel):
      ${raw_data}EL_800.xlsx  (sheet "Sheet1")

Outputs (saved under ${figure_output})
  - background_EL_province.gph
  - background_EL_industry.gph
  - background_EL_listyr.gph

Notes
  - Province and industry names are mapped to English labels for plotting.
  - This script uses Stata Graph Editor commands (gr_edit); results may vary
    slightly across Stata versions and OS environments.
  - The script also prints simple tabulations and Huawei-related counts for reference.
*******************************************************************************/
* Run via `00_run_all_2.do` (depends on shared path globals set by the runner).


********************************************************************************
* Descriptive statistics about Entity List (EL) firms
********************************************************************************


********************************************************************************
* Top-10 provinces by number of firms
********************************************************************************

import excel ${other_data}EL_Chinesefirm_qichacha_info.xlsx, ///
    sheet("1") firstrow clear

contract 所属省份
gen province = substr(所属省份, 1, 6)

gsort -_freq
keep in 1/10

* Province names (EN)
gen province_en = ""
replace province_en = "Beijing"   if province == "北京"
replace province_en = "Guangdong" if province == "广东"
replace province_en = "Jiangsu"   if province == "江苏"
replace province_en = "Shanghai"  if province == "上海"
replace province_en = "Shaanxi"   if province == "陕西"
replace province_en = "Sichuan"   if province == "四川"
replace province_en = "Xinjiang"  if province == "新疆"
replace province_en = "Zhejiang"  if province == "浙江"
replace province_en = "Anhui"     if province == "安徽"
replace province_en = "Tianjin"   if province == "天津"

graph bar _freq, ///
    over(province_en, sort(1) descending gap(50) label(labsize(small))) ///
    bar(1, fcolor(green*1) lcolor(green*1)) ///
    ytitle("{bf:Number of Firms}", size(large)) ///
    ylabel(, labsize(large)) ///
    graphregion(margin(small))

* Styling edits (Graph Editor)
gr_edit .grpaxis.style.editstyle majorstyle(tickangle(forty_five)) editcopy
gr_edit .grpaxis.style.editstyle majorstyle(tickstyle(textstyle(size(large)))) editcopy

graph save ${figure_output}background_EL_province.gph, replace


********************************************************************************
* Top-10 industries by number of firms
********************************************************************************

import excel ${other_data}EL_Chinesefirm_qichacha_info.xlsx, ///
    sheet("1") firstrow clear

bys 国标行业大类: gen industry_num = _N
keep 国标行业大类 industry_num
duplicates drop

drop if 国标行业大类 == "-"

gsort -industry_num
keep in 1/10

* Industry names (EN)
gen industry_en = ""
replace industry_en = "Scientific & technological promotion and application services" ///
    if 国标行业大类 == "科技推广和应用服务业"
replace industry_en = "Manufacture of computers and communication" ///
    if 国标行业大类 == "计算机、通信和其他电子设备制造业"
replace industry_en = "Software and information technology services" ///
    if 国标行业大类 == "软件和信息技术服务业"
replace industry_en = "Wholesale trade" ///
    if 国标行业大类 == "批发业"
replace industry_en = "Manufacture of rail, ship, and aerospace" ///
    if 国标行业大类 == "铁路、船舶、航空航天和其他运输设备制造业"
replace industry_en = "Professional technical services" ///
    if 国标行业大类 == "专业技术服务业"
replace industry_en = "Research and experimental development" ///
    if 国标行业大类 == "研究和试验发展"
replace industry_en = "Business services" ///
    if 国标行业大类 == "商务服务业"
replace industry_en = "Retail trade" ///
    if 国标行业大类 == "零售业"
replace industry_en = "Manufacture of electrical machinery and equipment" ///
    if 国标行业大类 == "电气机械和器材制造业"

graph hbar industry_num, ///
    over(industry_en, sort(1) descending gap(50) label(labsize(small))) ///
    bar(1, fcolor(red*1.5) lcolor(red*1.5)) ///
    blabel(bar, size(medsmall) format(%9.0fc)) ///
    ytitle("{bf:Number of Firms}", size(large) placement(east)) ///
    ylabel(, labsize(large)) ///
    graphregion(margin(medsmall))

* Styling edits (Graph Editor)
gr_edit .grpaxis.style.editstyle majorstyle(tickstyle(textstyle(size(medlarge)))) editcopy

graph save ${figure_output}background_EL_industry.gph, replace


********************************************************************************
* How many Chinese firms are placed on the Entity List each year
********************************************************************************

import excel ${raw_data}EL_800.xlsx, ///
    sheet("Sheet1") firstrow clear

keep if Type3 == "China"
keep if Type2 == "Firm (listed)" | Type2 == "Firm (not listed)"

rename 名称      name
rename 生效时间  list_time
keep name list_time

label var name      "Entity name listed on the Entity List"
label var list_time "Date of inclusion on the Entity List"

sort list_time
gen year = year(list_time)

bys year: gen listed_num = _N
keep year listed_num
duplicates drop

twoway bar listed_num year, ///
    ytitle("{bf:Number of Chinese Firms}""{bf: Placed on the Entity List}", size(medlarge)) ///
    xtitle("{bf:Year}", size(large) placement(east)) ///
    xlabel(, labsize(medsmall)) ///
    ylabel(, labsize(medsmall) angle(0)) ///
    fcolor(ebblue*1.5) lcolor(ebblue*1.5) ///
    barwidth(0.9) ///
    graphregion(margin(medsmall))

graph save ${figure_output}background_EL_listyr.gph, replace


********************************************************************************
* (1) Descriptive statistics: overall EL_800.xlsx composition
********************************************************************************

import excel ${raw_data}EL_800.xlsx, ///
    sheet("Sheet1") firstrow clear

tab Type1
/*
      Type1 |      Freq.     Percent        Cum.
------------+-----------------------------------
     Entity |        819       96.92       96.92
 Individual |         26        3.08      100.00
------------+-----------------------------------
      Total |        845      100.00
*/

tab Type2
/*
                           Type2 |      Freq.     Percent        Cum.
---------------------------------+-----------------------------------
                   Firm (listed) |         50        5.92        5.92
               Firm (not listed) |        610       72.19       78.11
                      Government |         21        2.49       80.59
                      Individual |         26        3.08       83.67
University or Research Institute |        138       16.33      100.00
---------------------------------+-----------------------------------
                           Total |        845      100.00
*/

keep if Type2 == "Firm (listed)" | Type2 == "Firm (not listed)"

tab Type3
/*
      Type3 |      Freq.     Percent        Cum.
------------+-----------------------------------
      China |        499       75.61       75.61
    Foreign |         86       13.03       88.64
         HK |         72       10.91       99.55
     Taiwan |          3        0.45      100.00
------------+-----------------------------------
      Total |        660      100.00
*/

keep if Type3 == "China"

tab Type2
/*
                           Type2 |      Freq.     Percent        Cum.
---------------------------------+-----------------------------------
                   Firm (listed) |         47        9.42        9.42
               Firm (not listed) |        452       90.58      100.00
---------------------------------+-----------------------------------
                           Total |        499      100.00
*/


********************************************************************************
* (2) Count Huawei-related entries (string match on the raw `name` column)
********************************************************************************

import excel ${raw_data}EL_800.xlsx, ///
    sheet("Sheet1") firstrow clear

keep if strpos(名称, "华为") > 0   // expected: 132
tab Type3
/*
      Type3 |      Freq.     Percent        Cum.
------------+-----------------------------------
      China |         51       38.64       38.64
    Foreign |         77       58.33       96.97
         HK |          4        3.03      100.00
------------+-----------------------------------
      Total |        132      100.00
*/



****尝试用11critical做描述性统计：
use "${stata_output}DID_allfirm-level.dta", clear
keep if entity_list==1
keep firm_id industry
duplicates drop

rename industry ipc_subclass

bys ipc_subclass: gen ipc_num = _N
keep ipc_num ipc_subclass
duplicates drop
gsort -ipc_num


*------------------------------------------------------------
* Reset all indicators
*------------------------------------------------------------
foreach v in is_ai is_adv_mfg is_adv_comm is_biotech is_quantum ///
         is_semi is_adv_energy is_adv_mat is_space is_autonomy is_cyber {
    capture confirm variable `v'
    if _rc {
        gen byte `v' = 0
    }
    else {
        replace `v' = 0
    }
}

*------------------------------------------------------------
* 1. Artificial Intelligence
* G06N kept in AI; G06F moved to Cyber/Data
*------------------------------------------------------------
replace is_ai = 1 if inlist(ipc_subclass,"G06N","G06K","G10L")
label var is_ai "Artificial Intelligence"

*------------------------------------------------------------
* 2. Advanced Manufacturing
* B25J moved to Autonomy
*------------------------------------------------------------
replace is_adv_mfg = 1 if inlist(ipc_subclass,"B23","B29","B33Y","G05B")
label var is_adv_mfg "Advanced Manufacturing"

*------------------------------------------------------------
* 3. Advanced Communications
* H04B, H04L, H04W kept here; G01S moved to Autonomy
*------------------------------------------------------------
replace is_adv_comm = 1 if inlist(ipc_subclass,"H04B","H04L","H04W","H01Q")
label var is_adv_comm "Advanced Communications"

*------------------------------------------------------------
* 4. Biotechnology
* No overlap
*------------------------------------------------------------
replace is_biotech = 1 if inlist(ipc_subclass,"C12N","C12P","C12Q","A61K","A61P")
label var is_biotech "Biotechnology"

*------------------------------------------------------------
* 5. Quantum Information
* G06N moved to AI; H01L moved to Semiconductor
*------------------------------------------------------------
replace is_quantum = 1 if inlist(ipc_subclass,"G02B")
label var is_quantum "Quantum Information"

*------------------------------------------------------------
* 6. Semiconductors & Microelectronics
* H01L kept here; H01M moved to Advanced Energy
*------------------------------------------------------------
replace is_semi = 1 if inlist(ipc_subclass,"H01L","G11C","B81B","B81C")
label var is_semi "Semiconductors & Microelectronics"

*------------------------------------------------------------
* 7. Advanced Energy
* H01M kept here
*------------------------------------------------------------
replace is_adv_energy = 1 if inlist(ipc_subclass,"H01M","F03D","H02J","C25B","F24S")
label var is_adv_energy "Advanced Energy"

*------------------------------------------------------------
* 8. Advanced Materials
* No overlap
*------------------------------------------------------------
replace is_adv_mat = 1 if inlist(ipc_subclass,"C01B","C09D","B82Y","C22C","H01B")
label var is_adv_mat "Advanced Materials"

*------------------------------------------------------------
* 9. Space Technologies
* H04B moved to Advanced Communications
*------------------------------------------------------------
replace is_space = 1 if inlist(ipc_subclass,"B64G","G01C")
label var is_space "Space Technologies"

*------------------------------------------------------------
* 10. Autonomy
* B25J and G01S kept here
*------------------------------------------------------------
replace is_autonomy = 1 if inlist(ipc_subclass,"G05D","B25J","G08G","G01S")
label var is_autonomy "Autonomy"

*------------------------------------------------------------
* 11. Data & Cybersecurity
* G06F kept here; H04L and H04W moved to Advanced Communications
*------------------------------------------------------------
replace is_cyber = 1 if inlist(ipc_subclass,"G06F","G06Q")
label var is_cyber "Data & Cybersecurity"

*------------------------------------------------------------
* Check overlap
*------------------------------------------------------------
egen n_tech_fields = rowtotal(is_ai is_adv_mfg is_adv_comm is_biotech ///
    is_quantum is_semi is_adv_energy is_adv_mat is_space is_autonomy is_cyber)

tab n_tech_fields

assert n_tech_fields <= 1


*------------------------------------------------------------
* Top 10 critical areas by number of firms
*------------------------------------------------------------

* 1. Generate mutually exclusive critical area variable
gen str40 critical_area = ""

replace critical_area = "Artificial Intelligence" ///
    if is_ai == 1

replace critical_area = "Advanced Manufacturing" ///
    if is_adv_mfg == 1

replace critical_area = "Advanced Communications" ///
    if is_adv_comm == 1

replace critical_area = "Biotechnology" ///
    if is_biotech == 1

replace critical_area = "Quantum Information" ///
    if is_quantum == 1

replace critical_area = "Semiconductors & Microelectronics" ///
    if is_semi == 1

replace critical_area = "Advanced Energy" ///
    if is_adv_energy == 1

replace critical_area = "Advanced Materials" ///
    if is_adv_mat == 1

replace critical_area = "Space Technologies" ///
    if is_space == 1

replace critical_area = "Autonomy" ///
    if is_autonomy == 1

replace critical_area = "Data & Cybersecurity" ///
    if is_cyber == 1

* 2. Keep only IPCs assigned to a critical area
keep if critical_area != ""

* 3. Sum company counts by critical area
collapse (sum) firm_num = ipc_num, by(critical_area)

* 4. Rank areas
gsort -firm_num
gen rank = _n
keep if rank <= 10

* 5. Draw horizontal bar chart
graph hbar (asis) firm_num, ///
    over(critical_area, sort(firm_num) descending label(labsize(small))) ///
    blabel(bar, format(%9.0f)) ///
    ytitle("Number of firms") ///
    title("Top 10 Critical Areas by Main IPC") ///

