/*******************************************************************************
Project: Science-linked patents—supplementary alternative identification
Script:  2_export_US_adver.do

Purpose:
  Build firm-level measures of export exposure to U.S. foreign-adversary states.
  Process annual firm-product export files for 2008–2016, identify critical-area
  products, construct a balanced firm-year panel, and aggregate exposure measures
  to the firm level.

Main inputs:
  - Annual export files exp2008.csv through exp2016.csv in the source directory
    referenced by the import command below

Main outputs (under ${stata_output}):
  - exp_usadver_2008_2016.dta: appended firm-year exposure measures
  - exp_usadver.dta: firm-level adversary-state export measures

Notes:
  Annual intermediate files are written under ${temp_output} and deleted after
  they are appended.
*******************************************************************************/

* ==============================================================================
* 1. Configure project and output paths
* ==============================================================================

capture cd ".\analytics\Sci_Pat\"
if _rc {
    capture cd "./analytics/Sci_Pat/"
}


global stata_output "../../stata_output/CN_CN/"
global table_output  "../../table_output/CN_CN/"
global temp_output  "../../temp_output/CN_CN/"
global dataset  "../../dataset/Miscellaneous/"


clear all

* ==============================================================================
* 2. Process annual export files for 2008–2016
* ==============================================================================

forvalues y = 2008/2016 {

    import delimited "${dataset}data_for_Yanbo\exp`y'.csv", clear

	
    capture confirm string variable firm_id
    if _rc != 0 {
        tostring firm_id, replace format(%20.0f)
    }

    
	* Flag exports to the four adversary-state country codes used in this analysis.
    gen us_adversary = 0
    foreach x in CUB IRN PRK RUS {
        replace us_adversary = 1 if iso3 == "`x'"
    }
	
	
	* Standardize HS8 codes as eight-character strings and derive HS4/HS6 codes.
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

	* Aggregate adversary-state exposure across all product sectors.
    bys firm_id: egen f_y_usadver = max(us_adversary)
    bys firm_id: egen f_y_usadver_value = total(value)
	
	* Aggregate exposure for the designated critical-area HS4 codes.
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
* ==============================================================================
* 3. Append annual files into a firm-year panel
* ==============================================================================

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
* ==============================================================================
* 4. Remove annual intermediate files
* ==============================================================================

forvalues y = 2008/2016 {
    erase "${temp_output}exp_adver_`y'.dta"
}
* ==============================================================================
* 5. Balance the panel and construct firm-level exposure measures
* ==============================================================================

use "${stata_output}exp_usadver_2008_2016.dta", clear // var: firm_id firm_name year f_y_usadver f_y_usadver_value

egen firmid = group(firm_id)
xtset firmid year

tsfill, full

* Fill firm identifiers and names forward and backward after panel completion.
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
