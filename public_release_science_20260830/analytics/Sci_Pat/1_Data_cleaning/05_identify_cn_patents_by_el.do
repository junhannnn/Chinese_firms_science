
/*******************************************************************************
Project: Entity List (China) ↔ CN Patent Applications
Script: 05_identify_cn_patents_by_el.do

Purpose
  - Build patent-level datasets linking China's Entity List firms to CN patents.
  - Two matching strategies:
      (A) Applicant-name match only (subsidiaries NOT included unless listed)
      (B) Parent-firm match using standardized applicant name (subsidiaries included)

Inputs
  - ${raw_data}EL_800.xlsx
  - ${CN_patents}app.dta
  - (and supporting CN patent datasets as used in the script)

Outputs (saved under ${stata_output})
  (1) Entity_List_China_withpatents_manual.dta
      - patent level; applicant-name match after manual cleaning
  (2) Entity_List_China_withpatents_manual_parent.dta
      - patent level; parent-firm propagation using standardized applicant name

Intermediate (saved under ${stata_output})
  (3) EL_800.dta
  (4) EL_merge.dta

Notes
  - Part A excludes subsidiaries unless explicitly listed on the Entity List.
  - Part B includes subsidiaries if the parent firm is listed.
*******************************************************************************/
* Run via `00_run_all_1.do` (depends on shared path globals set by the runner).



/*******************************************************************************
Part I. Entity List (Applicant-name matching; subsidiaries excluded unless listed)
Logic note:
  - Matching uses the *applicant name* (not standardized name).
  - If a parent is on Entity List but a subsidiary is not, that subsidiary is NOT included.
*******************************************************************************/

*============================================================*
* (1) Import and clean the Entity List (manual matching table)
*============================================================*

* Import Excel (xlsx → dta)
import excel ${raw_data}EL_800.xlsx, sheet("Sheet1") firstrow clear

rename 名称     name
rename 生效时间 list_time

keep name list_time
label var name      "Entity name listed on the Entity List"
label var list_time "Date of inclusion on the Entity List"

* Normalize full-width parentheses to ASCII parentheses
replace name = subinstr(name, "（", "(", .)
replace name = subinstr(name, "）", ")", .)

save ${stata_output}EL_800.dta, replace   // vars: name, list_time; obs ~800


*------------------------------------------------------------*
* Manual name harmonization for Entity List entries
*------------------------------------------------------------*
* These explicit replacements standardize EL entity names before matching to
* CN patent applicant names (manual, precision-first harmonization).
replace name = "深圳一电航空技术有限公司" if name == "AEE深圳一电航空技术有限公司"
replace name = "中国船舶重工集团公司"     if regexm(name, "CSSC")
replace name = "中国船舶重工集团公司"     if regexm(name, "CSSG")
replace name = "中国船舶重工集团公司"     if regexm(name, "GSSC")
replace name = "深圳市旺年华电子有限公司" if name == "Electronics Co. Ltd.(旺年华电子有限公司)"
replace name = "深圳市旺年华电子有限公司" if name == "Shenzhen Avanlane (深圳市旺年华电子有限公司)"
replace name = "深圳市旺年华电子有限公司" if name == "Suntric Company Limited(旺年华有限公司)"
replace name = "上海华为技术有限公司"     if name == "上海华为技术有限公司(中国上海)"
replace name = "壁仞科技有限公司"         if regexm(name, "壁仞")
replace name = "中国航天科工集团第二研究院" if regexm(name, "中国航天科工集团有限公司第二研究院")
replace name = "中芯国际"                 if regexm(name, "中芯国际")
replace name = "华为云"                   if regexm(name, "华为云")
replace name = "上海依图网络科技有限公司" if name == "上海依图络科技有限公司"
replace name = "上海海思技术有限公司"     if name == "上海海思科技有限公司(中国)"
replace name = "上海集成电路研发中心有限公司" if name == "上海集成电路研发中心"
replace name = "中国商用飞机有限责任公司上海飞机设计研究院" if name == "上海飞机设计研究院"
replace name = "华为终端(东莞)有限公司"   if name == "东莞华为服务有限公司(广东东莞)"
replace name = "华为技术服务有限公司"     if name == "中国华为技术服务有限公司(中国)"
replace name = "天利航空科技深圳有限公司" if name == "中国天利航空科技实业公司"
replace name = "中国广核集团有限公司"     if name == "中国广核集团"

replace name = "中国电子科技集团公司第三十八研究所" if name == "中国电子科技集团公司38研究所(CETC 38)"
replace name = "中国电子科技集团公司第三十八研究所" if name == "中国电子科技集团公司38研究所博微太赫兹信息技术有限公司"
replace name = "中国电子科技集团公司第三十八研究所" if name == "中国电子科技集团公司38研究所合肥华耀电子工业有限公司"
replace name = "中国电子科技集团公司第三十八研究所" if name == "中国电子科技集团公司38研究所合肥博微田村电气有限公司"
replace name = "中国电子科技集团公司第三十八研究所" if name == "中国电子科技集团公司38研究所安徽博微广成信息科技有限公司"
replace name = "中国电子科技集团公司第三十八研究所" if name == "中国电子科技集团公司38研究所安徽博微瑞达电子技术有限公司"
replace name = "中国电子科技集团公司第三十八研究所" if name == "中国电子科技集团公司38研究所安徽博微长安电子有限公司"
replace name = "中国电子科技集团公司第三十八研究所" if name == "中国电子科技集团公司38研究所安徽四创电子股份有限公司"

replace name = "中国电子科技集团公司第七研究所" if name == "中国电子科技集团公司第七研究所(CETC-7)"
replace name = "中国电子科技集团公司第七研究所" if name == "中国电子科技集团公司第七研究所广州宏宇科技有限公司"
replace name = "中国电子科技集团公司第七研究所" if name == "中国电子科技集团公司第七研究所广州通光通信技术有限公司"

replace name = "中国电子科技集团公司第三十研究所" if name == "中国电子科技集团公司第三十研究所(CETC-30)"

replace name = "中国电子科技集团公司第五十五研究所" if name == "中国电子科技集团公司第五十五研究所(CETC 55)"
replace name = "中国电子科技集团公司第五十五研究所" if name == "中国电子科技集团公司第五十五研究所南京国博电子有限公司"
replace name = "中国电子科技集团公司第五十五研究所" if name == "中国电子科技集团公司第五十五研究所南京国盛电子有限公司"

replace name = "中国电子科技集团公司第十三研究所" if name == "中国电子科技集团公司第十三研究所(CETC 13)"
replace name = "中国电子科技集团公司第十三研究所" if name == "中国电子科技集团公司第十三研究所(石家庄开发区麦特达微电子技术开发应用公司)"
replace name = "中国电子科技集团公司第十三研究所" if name == "中国电子科技集团公司第十三研究所华北集成电路有限公司"
replace name = "中国电子科技集团公司第十三研究所" if name == "中国电子科技集团公司第十三研究所同辉电子科技有限公司"
replace name = "中国电子科技集团公司第十三研究所" if name == "中国电子科技集团公司第十三研究所微电子技术发展应用公司"
replace name = "中国电子科技集团公司第十三研究所" if name == "中国电子科技集团公司第十三研究所河北兴业恒通国际有限公司"
replace name = "中国电子科技集团公司第十三研究所" if name == "中国电子科技集团公司第十三研究所河北医药保健有限公司"
replace name = "中国电子科技集团公司第十三研究所" if name == "中国电子科技集团公司第十三研究所河北博威集成电路有限公司"
replace name = "中国电子科技集团公司第十三研究所" if name == "中国电子科技集团公司第十三研究所河北普星电子有限公司"
replace name = "中国电子科技集团公司第十三研究所" if name == "中国电子科技集团公司第十三研究所河北美泰电子科技有限公司"
replace name = "中国电子科技集团公司第十三研究所" if name == "中国电子科技集团公司第十三研究所河北英沃泰克电子有限公司"
replace name = "中国电子科技集团公司第十三研究所" if name == "中国电子科技集团公司第十三研究所河北赛诺克电子有限公司"

replace name = "中国电子科技集团公司第十四研究所" if name == "中国电子科技集团公司第十四研究所(CETC 14)"
replace name = "中国电子科技集团公司第十四研究所" if name == "中国电子科技集团公司第十四研究所南京三思实业公司"
replace name = "中国电子科技集团公司第十四研究所" if name == "中国电子科技集团公司第十四研究所南京无线电技术研究所"

replace name = "中国航发沈阳黎明航空发动机有限责任公司" if name == "中国航发沈阳黎明航空科技有限公司"
replace name = "中国航发西安动力控制科技有限公司"         if name == "中国航发西安动力控制有限责任公司"
replace name = "中国航发"                                 if name == "中国航空发动机集团有限公司"

replace name = "中国航空工业集团公司济南特种结构研究所" if name == "中国航空工业集团公司复合材料特种结构研究所"
replace name = "中国航空工业集团公司雷华电子技术研究所" if name == "中国航空工业集团公司宙华电子技术研究所"
replace name = "中国船舶重工集团公司第七二二研究所"     if name == "中国船舶工业集团第722研究所"
replace name = "今创集团"                                 if name == "今创集团(KTK)"

replace name = "中国人民解放军军事医学科学院"                   if name == "军事医学科学院"
replace name = "中国人民解放军军事医学科学院军事兽医研究所"     if name == "军事医学科学院军事兽医研究所"
replace name = "中国人民解放军军事医学科学院卫生学环境医学研究所" if name == "军事医学科学院卫生环境医学研究所"
replace name = "中国人民解放军军事医学科学院卫生装备研究所"     if name == "军事医学科学院卫生装备研究所"
replace name = "中国人民解放军军事医学科学院基础医学研究所"     if name == "军事医学科学院基础医学研究所"
replace name = "中国人民解放军军事医学科学院微生物流行病研究所" if name == "军事医学科学院微生物流行病学研究所"
replace name = "中国人民解放军军事医学科学院放射与辐射医学研究所" if name == "军事医学科学院放射与辐射医学研究所"
replace name = "中国人民解放军军事医学科学院毒物药物研究"       if name == "军事医学科学院毒理药理物研究所毒物分析实验室"
replace name = "中国人民解放军军事医学科学院毒物药物研究所"     if name == "军事医学科学院毒理药理研究所"
replace name = "中国人民解放军军事医学科学院野战输血研究所"     if name == "军事医学科学院野战输血研究所"

replace name = "北京中电兴发科技有限公司" if name == "北京中电兴发料技有限公司"
replace name = "北京六合华大基因科技股份有限公司" if name == "北京六合华大基因科技有限公司"
replace name = "北京华为数字技术有限公司" if name == "北京华为数字技术有限公司(中国北京)"
replace name = "北京天圣华信息技术有限责任公司" if name == "北京天圣华信息技术有限公司"
replace name = "第四范式(北京)技术有限公司" if name == "北京第四范式智能技术股份有限公司"

replace name = "华为国际有限公司"       if name == "华为国际有限公司(中国香港)"
replace name = "华为技术加拿大有限公司" if name == "华为技术有限公司(加拿大安大略省)"
replace name = "瑞典华为技术有限公司"   if name == "华为技术有限公司(瑞典)"
replace name = "华为技术服务有限公司"   if name == "华为技术有限公司北京研究院"
replace name = "成都华为技术有限公司"   if name == "华为技术有限公司成都研究院"
replace name = "西安华为技术有限公司"   if name == "华为技术有限公司西安研究院"
replace name = "杜塞尔多夫华为技术有限公司" if name == "华为技术杜塞尔多夫有限公司"
replace name = "深圳华为移动通信技术有限公司" if name == "华为移动科技有限公司"
replace name = "华为软件技术有限公司"   if name == "华为软件技术有限公司(中国江苏)"
replace name = "华海通信技术有限公司"   if name == "华海通信国际有限公司"

replace name = "合肥美菱股份有限公司" if name == "合肥美菱有限公司"
replace name = "嘉兆科技有限公司"     if name == "嘉兆科技有限公司(中国香港)"

replace name = "中国电子科技集团公司第十三研究所" if name == "国电子科技集团公司第十三研究所河北普兴电子科技股份有限公司"
replace name = "中国电子科技集团公司第二研究所"   if name == "国航天科工集团有限公司第二研究院284厂(北京长丰机械厂)"

replace name = "天津七六四通信导航技术有限公司" if name == "天津764通信导航技术有限公司"
replace name = "天津天地伟业数码科技有限公司"   if name == "天津天地伟业科技有限公司"
replace name = "天津微纳制造技术有限公司"       if name == "天津市微纳制造技术工程中心"

replace name = "北京奇虎科技有限公司"           if name == "奇虎360 (Gihoo 360 Technology Company)"
replace name = "寒武纪行歌(南京)科技有限公司"   if name == "寒武纪(南京)科技有限公司"
replace name = "中科寒武纪科技股份有限公司"     if name == "寒武纪科技股份有限公司"
replace name = "康泰尔有限公司"                 if name == "康泰尔科技有限公司"
replace name = "北京和德宇航技术有限公司"       if name == "德宇航技术有限公司"

replace name = "成都华为技术有限公司"           if name == "成都华为技术有限公司(四川成都)"
replace name = "成都海光微电子技术有限公司"     if name == "成都海光微电子技术公司"
replace name = "成都海光集成电路设计有限公司"   if name == "成都海光集成电路设计公司"
replace name = "新疆大全新能源股份有限公司"     if name == "新疆大全新能源放份有限公司"

replace name = "杭州华为数字技术有限公司"       if name == "杭州华为数码科技有限公司(浙江杭州)"
replace name = "杭州华为企业通信技术有限公司"   if name == "杭州华为通信技术有限公司"
replace name = "格莱特有限公司"                 if name == "格莱特电子科技有限公司"
replace name = "欧唐科技(深圳)有限公司"         if name == "欧唐有限公司"
replace name = "江苏苏美达成套设备工程有限公司" if name == "江苏苏美达仪器设备有限公司"
replace name = "杭州华为企业通信技术有限公司"   if name == "浙江华为通信技术有限公司(中国浙江)"

replace name = "浪潮集团有限公司"               if name == "浪潮集团"
replace name = "海思光电子有限公司"             if name == "海思光电子有限公司(湖北武汉)"
replace name = "深圳光启创新技术有限公司"       if name == "深圳光启集团"

replace name = "深圳华为通信技术有限公司"       if name == "深圳华为技术服务"
replace name = "深圳华为通信技术有限公司"       if name == "深圳华为技术服务有限公司(中国广东)"

replace name = "北京北方烽火科技有限公司"       if name == "烽火科技集团有限公司"
replace name = "深圳砺剑天眼科技有限公司"       if name == "砺剑天眼科技有限公司"
replace name = "碳元科技股份有限公司"           if name == "碳元科技"
replace name = "北京中科立维科技有限公司"       if name == "立维科技有限公司"
replace name = "广东联合电子服务股份有限公司"   if name == "联合电子有限公司"
replace name = "西安航天动力技术研究所"         if name == "航天动力技术研究院"
replace name = "苏州盛科通信股份有限公司"       if name == "苏州盛科通信设份有限公同"

replace name = "西安华为技术有限公司"           if name == "西安华为技术有限公司(陕西西安)"
replace name = "西安瑞鑫科金属材料有限责任公司" if name == "西安瑞鑫投资有限公司(陕西西安)"
replace name = "西安飞机工业(集团)有限责任公司" if name == "西安飞机工业(集团)有限公司"

replace name = "上汽通用汽车有限公司"           if name == "通用企业有限公司"
replace name = "金城集团有限公司"               if name == "金城集团进出口有限公司"

replace name = "北京中科寒武纪科技有限公司"     if name == "雄安寒武纪科技有限公司"
replace name = "集成光子学中心有限公司"         if name == "集成光子学中心(CIP，英国)"
replace name = "青岛海洋科学与技术国家实验室发展中心" if name == "青岛海洋科学与技术国家实验室"

*------------------------------------------------------------*
* De-duplicate: keep earliest listing date per entity name
*------------------------------------------------------------*
* Retain one canonical (earliest) listing date for each cleaned EL entity name.
duplicates drop

duplicates tag name, gen(mark)   // ~6 firms listed twice; keep earliest occurrence
bys name: egen listed_time = min(list_time)
keep if list_time == listed_time
drop listed_time mark

save ${stata_output}EL_merge.dta, replace   // vars: name, list_time; obs ~743


*============================================================*
* (2) Merge Entity List with patents (applicant-name approach)
*============================================================*
* Part I uses the raw first-applicant name for direct matching only.
use ${CN_patents}app.dta, clear

rename 第一申请人 name

* Manual harmonization on patent applicant names (to improve match rate)
replace name = "中国船舶重工集团公司"     if regexm(name, "中国船舶重工集团公司")
replace name = "壁仞科技有限公司"         if regexm(name, "壁仞")
replace name = "中国航天科工集团第二研究院" if regexm(name, "中国航天科工集团第二研究院")
replace name = "中芯国际"                 if regexm(name, "中芯国际")
replace name = "华为云"                   if regexm(name, "华为云")
replace name = "中国航发"                 if regexm(name, "中国航发")
replace name = "今创集团"                 if name == "今创集团有限公司"
replace name = "今创集团"                 if name == "今创集团股份有限公司"
replace name = "国家超级计算济南中心"     if name == "山东省计算中心 (国家超级计算济南中心)"
replace name = "国家超级计算济南中心"     if name == "山东省计算中心(国家超级计算济南中心)"
replace name = "新疆生产建设兵团"         if regexm(name, "新疆生产建设兵团")

merge m:1 name using ${stata_output}EL_merge.dta   // matched ~305k; ~440 unmatched EL names
keep if _merge == 3

rename 申请号 apn
keep apn list_time
duplicates drop

gen entity_list = 1
label var entity_list "If parent is on EL but subsidiary is not on EL, subsidiary is excluded here"

save ${stata_output}Entity_List_China_withpatents_manual.dta, replace   // apn list_time entity_list


/*******************************************************************************
Part II. Entity List (Parent-firm matching; subsidiaries included)
Logic note:
  - Still merges on applicant name first.
  - Then uses the standardized applicant field to propagate EL status
    to subsidiaries under the same standardized parent (fapp_standard).
*******************************************************************************/

*============================================================*
* (2) Merge Entity List with patents (parent-firm inclusion)
*============================================================*
use ${CN_patents}app.dta, clear

rename 第一申请人 name

* Same manual harmonization as Part I
replace name = "中国船舶重工集团公司"     if regexm(name, "中国船舶重工集团公司")
replace name = "壁仞科技有限公司"         if regexm(name, "壁仞")
replace name = "中国航天科工集团第二研究院" if regexm(name, "中国航天科工集团第二研究院")
replace name = "中芯国际"                 if regexm(name, "中芯国际")
replace name = "华为云"                   if regexm(name, "华为云")
replace name = "中国航发"                 if regexm(name, "中国航发")
replace name = "今创集团"                 if name == "今创集团有限公司"
replace name = "今创集团"                 if name == "今创集团股份有限公司"
replace name = "国家超级计算济南中心"     if name == "山东省计算中心 (国家超级计算济南中心)"
replace name = "国家超级计算济南中心"     if name == "山东省计算中心(国家超级计算济南中心)"
replace name = "新疆生产建设兵团"         if regexm(name, "新疆生产建设兵团")

merge m:1 name using ${stata_output}EL_merge.dta   // matched ~305k; ~440 unmatched EL names
drop if _merge == 2

*------------------------------------------------------------*
* Propagate EL status using standardized applicant name
*------------------------------------------------------------*
* Part II broadens coverage by propagating EL status through the standardized
* applicant name (parent-firm style matching across related applicants).
gen filed_by_EL = 0
replace filed_by_EL = 1 if _merge == 3
label var filed_by_EL "Patent filed by a firm directly matched to the EL (name match)"

replace 标准化申请人 = subinstr(标准化申请人, "[", "", .)
replace 标准化申请人 = subinstr(标准化申请人, "]", "", .)

gen fapp_standard = 标准化申请人
replace fapp_standard = substr(标准化申请人, 1, strpos(标准化申请人, ";") - 1) ///
    if strpos(标准化申请人, ";") > 0

bys fapp_standard: egen filed_by_EL_p = max(filed_by_EL)

tab filed_by_EL_p   // if parent is listed, subsidiaries are included; ~543k patents

keep if filed_by_EL_p == 1
label var filed_by_EL_p "Patent filed by a firm OR parent firm on the EL (standardized match)"

rename 申请号 apn
keep apn filed_by_EL filed_by_EL_p list_time fapp_standard name
duplicates drop

gen entity_list = 1
label var entity_list "If parent is on EL but subsidiary is not, subsidiary is included here"

order apn entity_list list_time filed_by_EL filed_by_EL_p name fapp_standard
label var name          "Firm name (applicant name)"
label var fapp_standard "Standard firm name (parent firm name)"

save ${stata_output}Entity_List_China_withpatents_manual_parent.dta, replace   ///
    // apn entity_list list_time filed_by_EL filed_by_EL_p name fapp_standard
