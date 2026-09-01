/*******************************************************************************
Project: WOS Pipeline - Data Cleaning and Panel Construction
Script: 01_WOS_data_cleaning.do

Purpose
  - Build the WOS firm-year analysis sample used by downstream DID scripts.
  - Attach "other sanctions list" indicators to the WOS panel.

Inputs
  - `${python_output}WOS_CNfirm_publication.csv` (Python-prepared WOS panel).
  - `${CN_CN}Other_lists.dta` (other-list firm names).

Outputs
  - `${CN_CN}Other_lists_eng.dta`
  - `${stata_output}CN_WOS_DID.dta`

*******************************************************************************/

* Path globals are defined centrally in `00_run_all.do`.


******************************** other list ************************************

clear
set more off

* Single variable: English firm name (long text is more robust)
input strL firm_en
"360 Security Technology"
"Shanghai YITU Network Technology"
"Shanghai Hesai Technology"
"Shanghai Aerospace Equipment Manufacturing General Factory"
"Shanghai Aircraft Manufacturing"
"NetPosa Technologies"
"CRRC Corporation"
"China Communications Construction"
"China South Industries Group Automation Research Institute"
"China National Chemical Engineering"
"China National Chemical"
"China North Industries"
"Commercial Aircraft Corporation of China Shanghai Aircraft Design and Research Institute"
"China General Nuclear Power"
"China Architecture Design & Research"
"China National Offshore Oil"
"China Telecom"
"China Telecommunications"
"China Electronics"
"China Mobile Communications"
"China United Network Communications"
"AECC Harbin Dongan Engine"
"AECC Commercial Aircraft Engine"
"AECC Shenyang Liming Aero-Engine"
"AECC Hunan South Aero-Engine Industry"
"AECC Gas Turbine"
"AECC Aero Engine"
"AECC Aviation Science and Technology"
"AECC Xi'an Aero-Control Technology"
"AVIC Aero-Engine Standard Parts Manufacturing"
"AVIC Xi'an Flight Automatic Control Research Institute"
"AVIC Jincheng Nanjing Electromechanical Hydraulic Engineering Research Center"
"AVIC LeiHua Electronic Technology Research Institute"
"China Railway Construction"
"China Three Gorges"
"China State Construction Transportation"
"China State Construction Technology"
"Advanced Micro-Fabrication Equipment China"
"AVIC Optoelectronics Technology"
"AVIC Shenyang Commercial Aircraft Corporation of China"
"AVIC Electromechanical Systems"
"AVIC Xi'an Aircraft Industry"
"AVIC South China Aircraft Industry"
"AVIC General Aircraft Research Institute"
"AVIC High-Tech Development"
"CSSC Xijiang Shipbuilding"
"Semiconductor Manufacturing International Corporation Shanghai"
"Semiconductor Manufacturing International Corporation Beijing"
"Semiconductor Manufacturing International Corporation Tianjin"
"Semiconductor Manufacturing International Corporation Shenzhen"
"Global Tone Communication Technology"
"CloudWalk Technology"
"Guangming Electronics"
"Inner Mongolia First Machinery Group"
"Beijing Liweil Aviation Precision Machinery"
"Beijing Andatek Technology"
"Beijing Megvii Technology"
"Beijing Bem Aero Materials Hi-Tech"
"Beijing Knownsec Information Technology"
"Beijing Institute of Aeronautical Materials"
"Huawei Technologies"
"Huawei Device"
"Hefei Fuhua Precision Machinery Manufacturing"
"Harbin General Aircraft Industry"
"National Satellite Meteorological Center"
"Anhui Yingliu Aero-Dynamics"
"Yibin Sanjiang Machinery"
"Guangzhou Hangxin Aviation Technology"
"Chengdu M&S Electronics Technology"
"Chengdu Zongheng Automation Technology"
"Chengdu Hangli Aviation Technology"
"Chengdu Aircraft Industry"
"China Optical"
"China State Construction Engineering"
"China National Nuclear"
"China Telecommunications Group"
"China Electronics Technology"
"AECC"
"China Aerospace Science & Industry"
"AVIC"
"China State Shipbuilding"
"AVIC Aircraft"
"SMIC"
"SUMEC"
"Wuxi Parker New Material Technology"
"Wuxi Hangya Technology"
"Wuxi Turbine Blade"
"Dawning Information Industry"
"Hangzhou Hikvision Digital Technology"
"Hangzhou Bearing Test & Research Center"
"Wuhan Jishang Navigation Technology"
"Jiangsu Meilong Aviation Components"
"Jiangxi Hongdu Aviation Industry"
"Shenyang Institute of Instrumentation Science"
"Shenyang Xizi Aviation Industry"
"Shenyang Aircraft Industry"
"Henan Aerospace Precision Manufacturing"
"Zhejiang Dahua Technology"
"Inspur Group"
"BGI Genomics"
"SZ DJI Technology"
"Shenzhen Cosin Technology"
"Hubei Hangyu Jiatai Aircraft Equipment"
"Hunan South General Aviation Engine"
"Second Institute of Oceanography, Ministry of Natural Resources"
"DFH Satellite"
"China Academy of Aerospace Aerodynamics"
"Aerospace Morning Light (Fujian) Pipeline Technology"
"Suzhou Yike Electromechanical"
"Xi'an Aero Engine"
"Xi'an Xihang Group Wright Aviation Manufacturing Technology"
"Xi'an Aircraft Industry"
"Guizhou Aerospace Technology Development"
"Guizhou Liyang International Manufacturing"
"Chongqing APT Communication Technology"
"Jincheng"
"Yangtze Memory Technologies"
"Shaanxi Aviation Electric"
"Shaanxi Aircraft Industry"
end
gen id=_n

save ${temp_output}temp_eng.dta, replace


use ${CN_CN}Other_lists.dta, clear
gen id=_n
merge 1:1 id using ${temp_output}temp_eng.dta
drop _merge id

gen len = length(firm_en)
summ len
recast str100 firm_en
drop len

save ${CN_CN}Other_lists_eng.dta, replace

erase ${temp_output}temp_eng.dta

********************************************************************************
********************************* Data cleaning ********************************
********************************************************************************

import delimited ${python_output}WOS_CNfirm_publication.csv, clear

keep if year>=2010 & year<=2022

rename in_entity_list list_year
replace list_year="" if list_year=="False"
destring list_year, replace
tab list_year
gen entity_list=0
replace entity_list=1 if list_year!=.

order firm_id year entity_list list_year
sort firm_id year



xtset firm_id year
tsfill, full

local svars firm_id year entity_list list_year affiliationame wos_field field_id

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


foreach v of varlist num_papers num_with_uni num_papers_h num_with_uni_h ///
num_papers_fractional ///
num_papers_hh num_with_uni_hh {
    replace `v' = 0 if missing(`v')
}


gen did=0
replace did=1 if (year>list_year & entity_list==1)

rename num_papers pub_num
rename num_with_uni f_u_colla_num
rename num_papers_h pub_num_h
rename num_with_uni_h f_u_colla_num_h
rename num_papers_hh pub_num_hh
rename num_with_uni_hh f_u_colla_num_hh
rename num_papers_fractional pub_num_fractional

gen ln_pub_num=ln(pub_num+1)
gen ln_f_u_colla_num=ln(f_u_colla_num+1)
gen ln_pub_num_h=ln(pub_num_h+1)
gen ln_f_u_colla_num_h=ln(f_u_colla_num_h+1)


***************************** merge with other lists ***************************

rename affiliationame firm_en

recast str500 firm_en
merge m:1 firm_en using ${CN_CN}Other_lists_eng.dta

gen other_list=0
replace other_list=1 if _merge==3


gen byte other_list_2020 = ///
regexm(firm_en, "National Satellite Meteorological Center") | ///
regexm(firm_en, "Shaanxi Aircraft Industry") | ///
regexm(firm_en, "Henan Aerospace Precision Manufacturing") | ///
regexm(firm_en, "Guizhou Aerospace Technology Development") | ///
regexm(firm_en, "Jiangsu Meilong Aviation Components") | ///
regexm(firm_en, "Anhui Yingliu Aero-Dynamics") | ///
regexm(firm_en, "Shenyang Institute of Instrumentation Science") | ///
regexm(firm_en, "Hunan South General Aviation Engine") | ///
regexm(firm_en, "AECC Shenyang Liming Aero-Engine") | ///
regexm(firm_en, "Xian Aero Engine") | ///
regexm(firm_en, "AVIC Aero-Engine Standard Parts Manufacturing") | ///
regexm(firm_en, "Hangzhou Bearing Test & Research Center") | ///
regexm(firm_en, "Wuxi Turbine Blade") | ///
regexm(firm_en, "AECC Aviation Science and Technology") | ///
regexm(firm_en, "SUMEC") | ///
regexm(firm_en, "AVIC Aircraft") | ///
regexm(firm_en, "Shenyang Aircraft Industry") | ///
regexm(firm_en, "Chengdu Aircraft Industry") | ///
regexm(firm_en, "Hefei Fuhua Precision Machinery Manufacturing") | ///
regexm(firm_en, "AECC Aero Engine") | ///
regexm(firm_en, "AECC Hunan South Aero-Engine Industry") | ///
regexm(firm_en, "Guizhou Liyang International Manufacturing") | ///
regexm(firm_en, "Xian Aircraft Industry") | ///
regexm(firm_en, "Guangzhou Hangxin Aviation Technology") | ///
regexm(firm_en, "CSSC Xijiang Shipbuilding") | ///
regexm(firm_en, "Jincheng") | ///
regexm(firm_en, "AECC Harbin Dongan Engine") | ///
regexm(firm_en, "Second Institute of Oceanography, Ministry of Natural Resources") | ///
regexm(firm_en, "AECC Xian Aero-Control Technology") | ///
regexm(firm_en, "Chongqing APT Communication Technology") | ///
regexm(firm_en, "Harbin General Aircraft Industry") | ///
regexm(firm_en, "Guangming Electronics") | ///
regexm(firm_en, "Suzhou Yike Electromechanical") | ///
regexm(firm_en, "Shanghai Aerospace Equipment Manufacturing General Factory") | ///
regexm(firm_en, "AVIC") | ///
regexm(firm_en, "Wuxi Parker New Material Technology") | ///
regexm(firm_en, "Wuxi Hangya Technology") | ///
regexm(firm_en, "Beijing Institute of Aeronautical Materials") | ///
regexm(firm_en, "AVIC South China Aircraft Industry") | ///
regexm(firm_en, "AECC") | ///
regexm(firm_en, "Beijing Andatek Technology") | ///
regexm(firm_en, "AVIC Xian Flight Automatic Control Research Institute") | ///
regexm(firm_en, "AECC Gas Turbine") | ///
regexm(firm_en, "AECC Commercial Aircraft Engine") | ///
regexm(firm_en, "Yibin Sanjiang Machinery") | ///
regexm(firm_en, "AVIC Jincheng Nanjing Electromechanical Hydraulic Engineering Research Center") | ///
regexm(firm_en, "AVIC General Aircraft Research Institute") | ///
regexm(firm_en, "Xi'an Xihang Group Wright Aviation Manufacturing Technology") | ///
regexm(firm_en, "Hubei Hangyu Jiatai Aircraft Equipment") | ///
regexm(firm_en, "Chengdu Hangli Aviation Technology") | ///
regexm(firm_en, "Beijing Liweil Aviation Precision Machinery") | ///
regexm(firm_en, "Commercial Aircraft Corporation of China Shanghai Aircraft Design and Research Institute") | ///
regexm(firm_en, "Shenyang Xizi Aviation Industry") | ///
regexm(firm_en, "AVIC LeiHua Electronic Technology Research Institute") | ///
regexm(firm_en, "Beijing Bem Aero Materials Hi-Tech") | ///
regexm(firm_en, "Shaanxi Aviation Electric") | ///
regexm(firm_en, "Shanghai Aircraft Manufacturing")

gen byte other_list_2021 = ///
regexm(firm_en, "China North Industries") | ///
regexm(firm_en, "NetPosa Technologies") | ///
regexm(firm_en, "360 Security Technology") | ///
regexm(firm_en, "AVIC Shenyang Commercial Aircraft Corporation of China") | ///
regexm(firm_en, "SMIC") | ///
regexm(firm_en, "China National Nuclear") | ///
regexm(firm_en, "Wuhan Jishang Navigation Technology") | ///
regexm(firm_en, "Dawning Information Industry") | ///
regexm(firm_en, "AVIC High-Tech Development") | ///
regexm(firm_en, "China Optical") | ///
regexm(firm_en, "Chengdu Zongheng Automation Technology") | ///
regexm(firm_en, "CloudWalk Technology") | ///
regexm(firm_en, "Global Tone Communication Technology") | ///
regexm(firm_en, "Aerospace Morning Light") | ///
regexm(firm_en, "Semiconductor Manufacturing International Corporation Tianjin") | ///
regexm(firm_en, "Semiconductor Manufacturing International Corporation Beijing") | ///
regexm(firm_en, "AVIC Optoelectronics Technology") | ///
regexm(firm_en, "Zhejiang Dahua Technology") | ///
regexm(firm_en, "Inspur Group") | ///
regexm(firm_en, "BGI Genomics") | ///
regexm(firm_en, "China Telecom") | ///
regexm(firm_en, "China State Construction Technology") | ///
regexm(firm_en, "AVIC Electromechanical Systems") | ///
regexm(firm_en, "China National Chemical") | ///
regexm(firm_en, "Jiangxi Hongdu Aviation Industry") | ///
regexm(firm_en, "Huawei Technologies") | ///
regexm(firm_en, "China Mobile Communications") | ///
regexm(firm_en, "CRRC Corporation") | ///
regexm(firm_en, "DFH Satellite") | ///
regexm(firm_en, "DJI Technology") | ///
regexm(firm_en, "Huawei Device") | ///
regexm(firm_en, "China Aerospace Science & Industry") | ///
regexm(firm_en, "Yangtze Memory Technologies") | ///
regexm(firm_en, "China Telecommunications") | ///
regexm(firm_en, "China Academy of Aerospace Aerodynamics") | ///
regexm(firm_en, "Shanghai YITU Network Technology") | ///
regexm(firm_en, "Beijing Megvii Technology") | ///
regexm(firm_en, "China Railway Construction") | ///
regexm(firm_en, "Shanghai Hesai Technology") | ///
regexm(firm_en, "China Three Gorges") | ///
regexm(firm_en, "Semiconductor Manufacturing International Corporation Shanghai") | ///
regexm(firm_en, "China State Construction Engineering") | ///
regexm(firm_en, "Hangzhou Hikvision Digital Technology") | ///
regexm(firm_en, "AVIC Xian Aircraft Industry") | ///
regexm(firm_en, "China General Nuclear Power") | ///
regexm(firm_en, "China State Shipbuilding") | ///
regexm(firm_en, "China Electronics Technology") | ///
regexm(firm_en, "China United Network Communications") | ///
regexm(firm_en, "China Architecture Design & Research") | ///
regexm(firm_en, "Advanced Micro-Fabrication Equipment China") | ///
regexm(firm_en, "Beijing Knownsec Information Technology") | ///
regexm(firm_en, "China National Offshore Oil") | ///
regexm(firm_en, "Chengdu M&S Electronics Technology") | ///
regexm(firm_en, "China State Construction Transportation") | ///
regexm(firm_en, "China South Industries Group Automation Research Institute") | ///
regexm(firm_en, "China Communications Construction") | ///
regexm(firm_en, "China Telecommunications") | ///
regexm(firm_en, "China Electronics") | ///
regexm(firm_en, "Inner Mongolia First Machinery Group") | ///
regexm(firm_en, "China National Chemical Engineering") | ///
regexm(firm_en, "Shenzhen Cosin Technology") | ///
regexm(firm_en, "Semiconductor Manufacturing International Corporation Shenzhen")


replace other_list = 1 if other_list_2020
replace other_list = 1 if other_list_2021
replace otherlist_year = 2020 if other_list_2020
replace otherlist_year = 2021 if other_list_2021

drop if _merge==2
drop _merge fapp


winsor2 pub_num f_u_colla_num pub_num_h f_u_colla_num_h ///
pub_num_hh f_u_colla_num_hh, cuts(0 99.5)
replace avg_jif=0 if avg_jif==.

save ${stata_output}CN_WOS_DID.dta, replace

