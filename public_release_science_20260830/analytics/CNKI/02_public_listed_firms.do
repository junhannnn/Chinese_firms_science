
/*******************************************************************************
Project: CNKI Analysis - Public Listed Firms Subsample
Script: 02_public_listed_firms.do

Purpose
  - Construct the listed-firm panel by linking CNKI firm-year data with CSMAR.
  - Run baseline and CEM-matched DID regressions for publication outcomes.

Inputs
  - ${stata_output}CNKI_DID.dta
  - ${CN_CN}CSMAR_cv.dta

Outputs
  - ${stata_output}CNKI_listedfirm_DID.dta
  - ${table_output}CNKI_listedfirm.rtf
  - ${temp_output}Symbol_SocialCreditCode.dta (temporary; deleted in-script)

Notes
  - Controls are interpolated and winsorized before final regressions.
  - Requires user-written commands used in this script (for example: `winsor2`,
    `reghdfe`, `ppmlhdfe`, `cem`, `esttab`).
*******************************************************************************/

* Paths are initialized by `00_run_all.do`.


********************************************************************************
**************************** Sample: Chinese listed firms **********************
********************************************************************************

use ${CN_CN}CSMAR_cv.dta, clear
keep Symbol SocialCreditCode
duplicates drop
drop if SocialCreditCode=="None"
duplicates drop SocialCreditCode, force
save ${temp_output}Symbol_SocialCreditCode.dta, replace //var: Symbol SocialCreditCode


use ${stata_output}CNKI_DID.dta, clear
rename 统一社会信用代码 SocialCreditCode
merge m:1 SocialCreditCode using ${temp_output}Symbol_SocialCreditCode.dta
keep if _merge==3
drop _merge


foreach v of varlist pub_num f_u_colla_num pub_num_h f_u_colla_num_h ///
                      pub_num_w f_u_colla_num_w pub_num_h_w f_u_colla_num_h_w ///
                      ln_pub_num ln_f_u_colla_num ln_pub_num_h ln_f_u_colla_num_h ///
                      pub_num_fractional {

    bysort Symbol year: egen sum_`v' = total(`v')
    replace `v' = sum_`v'
    drop sum_`v'
}

drop firm_id
duplicates drop
duplicates drop Symbol year, force

sort Symbol year
order Symbol year

gen Symbol_id = Symbol
xtset Symbol_id year
tsfill, full

local svars Symbol year firm_field entity_list list_year SocialCreditCode 企业机构类型 所属集团 corporate corporate_id soe_based_type soe_based_llm firm_qcc_id soe did Symbol_id

sort Symbol_id year
foreach v of local svars {
    by Symbol_id (year): replace `v' = `v'[_n-1] if missing(`v')
}

gen year_1 = 3000-year
sort Symbol_id year_1
foreach v of local svars {
    by Symbol_id (year_1): replace `v' = `v'[_n-1] if missing(`v')
}
drop year_1

sort Symbol_id year


foreach v of varlist pub_num f_u_colla_num pub_num_h f_u_colla_num_h ///
                      pub_num_w f_u_colla_num_w pub_num_h_w f_u_colla_num_h_w ///
                      ln_pub_num ln_f_u_colla_num ln_pub_num_h ln_f_u_colla_num_h ///
                      pub_num_fractional {
    replace `v' = 0 if missing(`v')
}


replace entity_list=1 if list_year!=.

drop did
gen did=0
replace did=1 if entity_list==1 & year>list_year

merge 1:1 Symbol year using ${CN_CN}CSMAR_cv.dta
drop if _merge==2
drop _merge



gen firm_listing_year = substr(LISTINGDATE, 1, 4)
label var firm_listing_year "Listing year of the firm"
destring firm_listing_year, replace
gen firm_age = year-firm_listing_year

gen firm_size=ln(RegisterCapital)
gen cash=ln(CashHoldings)
egen province_code = group(PROVINCECODE)
egen industry_code = group(IndustryCode)

gen dif_year = year-list_year

replace dif_year=-10 if dif_year<-10

* Control variables
gen founding_year=substr(EstablishDate,1,4)
replace founding_year="" if founding_year=="None"
destring founding_year, replace

gen listing_year=substr(LISTINGDATE,1,4)
destring listing_year, replace



global allcontrols firm_age firm_size state_owned cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ province_code industry_code year ListedCoID founding_year listing_year academic_experience


global sum_controls firm_size state_owned cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ founding_year listing_year academic_experience

global controls cash RDSpendSumRatio ROA AssetLiabilityRatio TobinQ academic_experience

foreach v in $controls {
    bysort Symbol_id (year): ipolate `v' year, gen(_tmp) epolate
    replace `v' = _tmp if missing(`v')
    drop _tmp
}

foreach var in $controls {
    drop if `var' == .
}

foreach v in $controls {
    winsor2 `v', replace
}

bysort Symbol_id: egen number = sum(pub_num)
drop if number == 0
drop number

save ${stata_output}CNKI_listedfirm_DID.dta, replace


erase ${temp_output}Symbol_SocialCreditCode.dta

********************************************************************************
******************************* DV: publication num ****************************
********************************************************************************


**************************** (1) all sample ************************************

use ${stata_output}CNKI_listedfirm_DID.dta, clear

* OLS
reghdfe pub_num_w did $controls, absorb(Symbol_id year) vce(r)
est store M1

* ln and OLS
reghdfe ln_pub_num did $controls, absorb(Symbol_id year) vce(r)
est store M2

* Poisson
ppmlhdfe pub_num did $controls, absorb(Symbol_id year) vce(r)
est store M3


************************** (2) matched sample **********************************

use ${stata_output}CNKI_listedfirm_DID_cem.dta, clear

keep if cem_matched==1

bysort Symbol_id: egen number = sum(pub_num)
drop if number == 0
drop number

* OLS
reghdfe pub_num_w did $controls [aweight=cem_weights], absorb(Symbol_id year) vce(r)
est store M4

* ln and OLS
reghdfe ln_pub_num did $controls [aweight=cem_weights], absorb(Symbol_id year) vce(r)
est store M5

* Poisson
ppmlhdfe pub_num did $controls [pweight=cem_weights], absorb(Symbol_id year) vce(r)
est store M6



esttab M1 M2 M3 M4 M5 M6 using ${table_output}CNKI_listedfirm.rtf, ///
    replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
    b(%20.3f) se(%7.3f) r2(%9.3f) ///
    stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
    mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
    nonotes
