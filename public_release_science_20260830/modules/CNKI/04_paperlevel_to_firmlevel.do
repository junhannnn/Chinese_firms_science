
capture cd ".\analytics\CNKI\"
if _rc {
    capture cd "./analytics/CNKI/"
}

global python_output "../../proc_output/CNKI/"
global stata_output "../../stata_output/CNKI/"
global table_output "../../table_output/CNKI/"
global figure_output "../../figure_output/CNKI/"
global temp_output "../../temp_output/CNKI/"

********************************************************************************
********************************** Data cleaning *******************************
********************************************************************************

import delimited ${python_output}03_CNKI_firm_paperid.csv, clear

bys paperid: gen aff_num = _N
gen weight_paper = 1/aff_num

rename entity_list list_year
replace list_year=. if list_year==-1
tab list_year
gen entity_list=0
replace entity_list=1 if list_year!=.
order firm_id paperid year entity_list list_year
sort firm_id year

gen f_u_colla=0
replace f_u_colla=1 if firm_uni_colla=="True"

* firm_field
gen field=substr(clc,1,1)
replace field="NaN" if field==""
sort firm_id field
bysort firm_id field (paperid): gen field_count = _N
bysort firm_id (field_count): replace field = field[_N]
bysort firm_id (field): gen firm_field = field if _n == _N
bysort firm_id (firm_field): replace firm_field = firm_field[_N]


* calculate
bys firm_id year: gen pub_num = _N
bys firm_id year: egen f_u_colla_num = sum(f_u_colla)
bys firm_id year: egen funding_num = sum(funding)
bys firm_id year: egen pub_num_fractional = sum(weight_paper)


* consider JIF
sum jif, d
replace jif=0 if jif==.
bys firm_id year: egen pub_num_h = total(cond(jif>1, 1, 0))
bys firm_id year: egen f_u_colla_num_h = total(cond(jif>1, f_u_colla, 0))
bys firm_id year: egen funding_num_h = total(cond(jif>1, funding, 0))

centile jif, centile(66)
bys firm_id year: egen pub_num_hh = total(cond(jif>1.2, 1, 0)) //top 1/3
bys firm_id year: egen f_u_colla_num_hh = total(cond(jif>1.2, f_u_colla, 0)) //top 1/3


bys firm_id year: egen entity_list1=max(entity_list)
bys firm_id year: egen list_year1=max(list_year)
drop entity_list list_year
rename entity_list1 entity_list
rename list_year1 list_year

keep firm_id year entity_list list_year pub_num f_u_colla_num pub_num_h f_u_colla_num_h firm_name firm_name_cleaned firm_field pub_num_fractional ///
pub_num_hh f_u_colla_num_hh
duplicates drop


xtset firm_id year

gen did=0
replace did=1 if (year>=list_year & entity_list==1)

gen ln_pub_num=ln(pub_num+1)
gen ln_f_u_colla_num=ln(f_u_colla_num+1)
gen ln_pub_num_h=ln(pub_num_h+1)
gen ln_f_u_colla_num_h=ln(f_u_colla_num_h+1)

winsor2 pub_num f_u_colla_num pub_num_h f_u_colla_num_h ///
pub_num_hh f_u_colla_num_hh, cuts(0 99.5)

keep if year>=2010

save ${stata_output}CNKI_DID_not_standard.dta, replace
export delimited using ${stata_output}CNKI_DID_not_standard.csv, replace



********************************************************************************
************************** Standardize firm name *******************************
********************************************************************************

use ${stata_output}CNKI_DID_not_standard.dta, clear
bys firm_id: egen firm_pub_num = sum(pub_num)
keep firm_name firm_pub_num
duplicates drop

gsort -firm_pub_num firm_name

save ${stata_output}CNKI_Qichacha_order.dta, replace


************** GO QICHACHA TO SEARCH

