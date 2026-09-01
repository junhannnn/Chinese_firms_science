
capture cd ".\analytics\CNKI\"
if _rc {
    capture cd "./analytics/CNKI/"
}

global python_output "../../proc_output/CNKI/"
global stata_output "../../stata_output/CNKI/"
global table_output "../../table_output/CNKI/"
global figure_output "../../figure_output/CNKI/"
global temp_output "../../temp_output/CNKI/"
global CN_CN "../../stata_output/CN_CN/"

******************************** Prepare data **********************************

import delimited ${python_output}07_CNKI_SOE_ChatGPT.csv, bindquote(strict) clear 
egen firm_qcc_id = group(firm_name_qcc)

replace year = 0 if missing(year)
replace firm_field = "0" if missing(firm_field)
replace firm_qcc_id = 0 if missing(firm_qcc_id)

rename soe soe_based_type
rename soe_chatgpt soe_based_llm
gen soe=.
replace soe=1 if soe_based_llm=="1"
replace soe=0 if soe_based_llm=="0"
tab soe

replace soe=1 if corporate=="同济大学建筑设计研究院有限公司"
replace soe=1 if corporate=="天士力医药集团-C"
replace soe=1 if corporate=="安琪酵母-C"
replace soe=1 if corporate=="中设集团-C"
replace soe=1 if corporate=="贵研铂业-C"
replace soe=1 if corporate=="中国汽研-C"
replace soe=1 if corporate=="泸州老窖集团-C"
replace soe=1 if corporate=="河南交通规划设研院-C"

keep if year>=2010 & year<=2022

xtset firm_id year
tsfill, full

local svars firm_name firm_name_cleaned firm_field entity_list list_year did firm_name_qcc 企业机构类型 所属集团 corporate corporate_id soe_based_type soe_based_llm firm_qcc_id soe 所属行业

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


foreach v of varlist pub_num f_u_colla_num pub_num_h f_u_colla_num_h ///
                      pub_num_w f_u_colla_num_w pub_num_h_w f_u_colla_num_h_w ///
                      ln_pub_num ln_f_u_colla_num ln_pub_num_h ln_f_u_colla_num_h ///
					  pub_num_fractional ///
					  pub_num_hh f_u_colla_num_hh pub_num_hh_w f_u_colla_num_hh_w {
    replace `v' = 0 if missing(`v')
}

***************************** merge with other lists ***************************
rename firm_name fapp
recast str265 fapp
merge m:1 fapp using ${CN_CN}Other_lists.dta

gen other_list=0
replace other_list=1 if _merge==3
list if _merge==2

replace other_list = 1 if regexm(fapp, "中光学集团")|regexm(fapp, "中国建筑工程")| ///
regexm(fapp, "中国核工业")|regexm(fapp, "中国电信集团")|regexm(fapp, "中国电子科技集团")| ///
regexm(fapp, "中国航天科工集团")|regexm(fapp, "中国船舶工业集团")|regexm(fapp, "中芯国际集成电路制造")

replace other_list = 1 if regexm(fapp, "中国航发")|regexm(fapp, "中国航空工业集团")| ///
regexm(fapp, "中航飞机股份有限公司")|regexm(fapp, "江苏苏美达")


replace otherlist_year=2021 if regexm(fapp, "中光学集团")|regexm(fapp, "中国建筑工程")| ///
regexm(fapp, "中国核工业")|regexm(fapp, "中国电信集团")|regexm(fapp, "中国电子科技集团")| ///
regexm(fapp, "中国航天科工集团")|regexm(fapp, "中国船舶工业集团")|regexm(fapp, "中芯国际集成电路制造")

replace otherlist_year=2020 if regexm(fapp, "中国航发")|regexm(fapp, "中国航空工业集团")| ///
regexm(fapp, "中航飞机股份有限公司")|regexm(fapp, "江苏苏美达")

drop if _merge==2
drop _merge

rename fapp firm_name
drop firm_name firm_name_cleaned firm_name_qcc

save ${stata_output}CNKI_DID.dta, replace
