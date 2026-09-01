
capture cd ".\analytics\Sci_Pat\"
if _rc {
    capture cd "./analytics/Sci_Pat/"
}


global stata_output "../../stata_output/CN_CN/"
global table_output  "../../table_output/CN_CN/"
global temp_output  "../../temp_output/CN_CN/"
global dataset  "../../dataset/Miscellaneous/"


clear all

forvalues y = 2008/2016 {

    import delimited "${dataset}data_for_Yanbo\exp`y'.csv", clear

	
    capture confirm string variable firm_id
    if _rc != 0 {
        tostring firm_id, replace format(%20.0f)
    }

    
	* List
    gen us_adversary = 0
    foreach x in CUB IRN PRK RUS {
        replace us_adversary = 1 if iso3 == "`x'"
    }
	
	
	* Convert HS8 into an 8-digit string
	capture confirm string variable hs8
	if _rc {
		format hs8 %08.0f
		tostring hs8, gen(hs8_str) usedisplayformat
		drop hs8
		rename hs8_str hs8
	}

	replace hs8 = strtrim(hs8)
	replace hs8 = substr("00000000" + hs8, strlen("00000000" + hs8) - 7, 8)
	gen hs4 = substr(hs8, 1, 4)
	gen hs6 = substr(hs8, 1, 6)

	gen byte critical_area = inlist(hs4, "8517", "8541", "8542")
	
	
    keep if us_adversary == 1

	* all sector
    bys firm_id: egen f_y_usadver = max(us_adversary)
    bys firm_id: egen f_y_usadver_value = total(value)
	
	* sensitive sector
	bys firm_id: egen f_y_c_usadver_criarea = max(us_adversary) if critical_area == 1
	bys firm_id: egen f_y_c_usadver_value_criarea = total(value) if critical_area == 1
	replace f_y_c_usadver_criarea=0 if f_y_c_usadver_criarea==.
	replace f_y_c_usadver_value_criarea=0 if f_y_c_usadver_value_criarea==.
	
    bys firm_id: egen f_y_usadver_criarea = max(f_y_c_usadver_criarea)
    bys firm_id: egen f_y_usadver_value_criarea = max(f_y_c_usadver_value_criarea)

    keep firm_id firm_name f_y_usadver f_y_usadver_value f_y_usadver_criarea f_y_usadver_value_criarea
    duplicates drop

    gen year = `y'
    order firm_id firm_name year

    save "${temp_output}exp_adver_`y'.dta", replace
}


*** append all files
clear
save "${stata_output}exp_usadver_2008_2016.dta", emptyok replace

forvalues y = 2008/2016 {
    append using "${temp_output}exp_adver_`y'.dta"
}

sort firm_id year
by firm_id: gen firm_name_latest = firm_name[1]
replace firm_name = firm_name_latest
drop firm_name_latest
drop if firm_id=="."

save "${stata_output}exp_usadver_2008_2016.dta", replace


*** erase temp files

forvalues y = 2008/2016 {
    erase "${temp_output}exp_adver_`y'.dta"
}


*** firm-year level to firm level

use "${stata_output}exp_usadver_2008_2016.dta", clear // var: firm_id firm_name year f_y_usadver f_y_usadver_value

egen firmid = group(firm_id)
xtset firmid year

tsfill, full

*------------------------------------------------------------*
* Fill time-invariant (or slowly varying) firm attributes forward/backward
*------------------------------------------------------------*
sort firmid year
by firmid: replace firm_id   = firm_id[_n-1]   if missing(firm_id)
by firmid: replace firm_name = firm_name[_n-1] if missing(firm_name)

gsort firmid -year
by firmid: replace firm_id   = firm_id[_n-1]   if missing(firm_id)
by firmid: replace firm_name = firm_name[_n-1] if missing(firm_name)

sort firmid year

foreach v of varlist ///
    f_y_usadver f_y_usadver_value f_y_usadver_criarea f_y_usadver_value_criarea {
    replace `v' = 0 if missing(`v')
}


drop if firm_name==""
drop if firm_name=="NULL"

bys firmid: egen f_usadver_dummy = max(f_y_usadver) 
bys firmid: egen f_usadver = mean(f_y_usadver) 
bys firmid: egen f_usadver_value = mean(f_y_usadver_value) //total

bys firmid: egen f_usadver_criarea_dummy = max(f_y_usadver_criarea) 
bys firmid: egen f_usadver_criarea = mean(f_y_usadver_criarea) 
bys firmid: egen f_usadver_value_criarea = mean(f_y_usadver_value_criarea) //total

keep firm_name f_usadver_dummy f_usadver f_usadver_value ///
f_usadver_criarea_dummy f_usadver_criarea f_usadver_value_criarea
duplicates drop

label var f_usadver_dummy "Indicator for firm exports to U.S. adversary states"
label var f_usadver "Firm-level share of years with exports to U.S. adversary states"
label var f_usadver_value "Firm-level average export value to U.S. adversary states"

label var f_usadver_criarea_dummy "Indicator for firm exports of critical-area products to U.S. adversary states"
label var f_usadver_criarea "Firm-level share of years with exports of critical-area products to U.S. adversary states"
label var f_usadver_value_criarea "Firm-level average export value of critical-area products to U.S. adversary states"

save "${stata_output}exp_usadver.dta", replace 
