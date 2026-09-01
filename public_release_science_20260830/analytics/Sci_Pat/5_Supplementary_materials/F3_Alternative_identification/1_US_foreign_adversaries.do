
import excel ".\dataset\Miscellaneous\US_foreign_adversaries.xlsx", sheet("Sheet1") firstrow clear


gen type_rank = .

replace type_rank = 1 if Type == "Comprehensively sanctioned jurisdictions"
replace type_rank = 2 if Type == "Targeted sanctions (Country-specific sanctions programs)"
replace type_rank = 3 if Type == "Targeted sanctions (Human rights abuses/corruption)"
replace type_rank = 4 if Type == "Targeted sanctions (Terrorism)"
replace type_rank = 5 if Type == "Targeted sanctions (Drug trafficking/transnational criminal organizations)"
replace type_rank = 6 if Type == "Jurisdictions subject to military/arms related export controls (Department of State Arms Embargo)"
replace type_rank = 7 if Type == "Jurisdictions subject to military/arms related export controls (Department of Commerce Military End Use/User Rule)"
replace type_rank = 8 if Type == "Jurisdictions subject to military/arms related export controls (Russia/Belarus MEU FDP Rule)"



reshape wide Type, i(Country) j(type_rank)

rename Type1 saction_list1
rename Type2 saction_list2
rename Type3 saction_list3
rename Type4 saction_list4
rename Type5 saction_list5
rename Type6 saction_list6
rename Type7 saction_list7
rename Type8 saction_list8

gen byte temp = (trim(saction_list1) == "Comprehensively sanctioned jurisdictions")
drop saction_list1
rename temp saction_list1

gen byte temp = (trim(saction_list2) == "Targeted sanctions (Country-specific sanctions programs)")
drop saction_list2
rename temp saction_list2

gen byte temp = (trim(saction_list3) == "Targeted sanctions (Human rights abuses/corruption)")
drop saction_list3
rename temp saction_list3

gen byte temp = (trim(saction_list4) == "Targeted sanctions (Terrorism)")
drop saction_list4
rename temp saction_list4

gen byte temp = (trim(saction_list5) == "Targeted sanctions (Drug trafficking/transnational criminal organizations)")
drop saction_list5
rename temp saction_list5

gen byte temp = (trim(saction_list6) == "Jurisdictions subject to military/arms related export controls (Department of State Arms Embargo)")
drop saction_list6
rename temp saction_list6

gen byte temp = (trim(saction_list7) == "Jurisdictions subject to military/arms related export controls (Department of Commerce Military End Use/User Rule)")
drop saction_list7
rename temp saction_list7

gen byte temp = (trim(saction_list8) == "Jurisdictions subject to military/arms related export controls (Russia/Belarus MEU FDP Rule)")
drop saction_list8
rename temp saction_list8



label var saction_list1 "Comprehensively sanctioned jurisdictions"
label var saction_list2 "Targeted sanctions (Country-specific sanctions programs)"
label var saction_list3 "Targeted sanctions (Human rights abuses/corruption)"
label var saction_list4 "Targeted sanctions (Terrorism)"
label var saction_list5 "Targeted sanctions (Drug trafficking/transnational criminal organizations)"
label var saction_list6 "Jurisdictions subject to military/arms related export controls (Department of State Arms Embargo)"
label var saction_list7 "Jurisdictions subject to military/arms related export controls (Department of Commerce Military End Use/User Rule)"
label var saction_list8 "Jurisdictions subject to military/arms related export controls (Russia/Belarus MEU FDP Rule)"


export excel using ".\dataset\Miscellaneous\US_foreign_adversaries_dropdup.xlsx", firstrow(variables) replace