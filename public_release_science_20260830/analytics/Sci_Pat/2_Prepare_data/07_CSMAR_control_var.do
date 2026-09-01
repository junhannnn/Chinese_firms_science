/*******************************************************************************
Project: Chinese Publicly Listed Firms - CSMAR Controls and Moderators
Script: 07_CSMAR_control_var.do

Purpose
  - Build listed-firm control variables and moderator inputs from CSMAR data.
  - Save cleaned intermediates and derived CSMAR control outputs for downstream scripts.

Inputs (from ${CSMAR})
  - CSMAR raw datasets referenced throughout this script

Outputs
  - Intermediate files under ${temp_output}
  - Final CSMAR control outputs under ${stata_output}

*******************************************************************************/
* Run via `00_run_all_2.do` (depends on shared path globals set by the runner).



********************************************************************************
****************************** Data Source: CSMAR ******************************
********************************************************************************

* (1) CSMAR - basic info
use ${CSMAR}STK_LISTEDCOINFOANL.dta, clear
gen year = substr(EndDate, 1, 4)
destring year, replace
*keep Symbol ShortName ListedCoID SecurityID SocialCreditCode RegisterCapital PROVINCECODE PROVINCE IndustryName IndustryCode year LISTINGDATE
save ${temp_output}CSMAR_basicinfo.dta, replace


* (2) CSMAR - R&D
use ${CSMAR}PT_LCRDSPENDING.dta, clear
gen year = substr(EndDate, 1, 4)
destring year, replace
gen end = substr(EndDate, 6, 5)
keep if end=="12-31"
keep if StateTypeCode==1
*keep Symbol year RDSpendSum RDSpendSumRatio
save ${temp_output}CSMAR_R&D.dta, replace // vars: Symbol year RDSpendSum RDSpendSumRatio


* (3) CSMAR - ROA
use ${CSMAR}FI_T5.dta, clear
rename Stkcd Symbol
gen year = substr(Accper, 1, 4)
destring year, replace
gen end = substr(Accper, 6, 5)
keep if end=="12-31"
keep if Typrep=="A"
*keep Symbol year F050201B
rename F050201B ROA
order Symbol year ROA
save ${temp_output}CSMAR_ROA.dta, replace // vars: Symbol year ROA


* (4) CSMAR - finance related
import excel ${CSMAR}BDT_FinConstKZ.xlsx, sheet("sheet1") firstrow clear
gen year = substr(Enddate, 1, 4)
destring year, replace
keep Symbol year TobinQ AssetLiabilityRatio CashHoldings
duplicates drop
save ${temp_output}CSMAR_finance.dta, replace // vars: Symbol year TobinQ AssetLiabilityRatio CashHoldings


* (5) CSMAR - English name
use ${CSMAR}AF_Co.dta, clear
keep Stkcd Conmee
rename Stkcd Symbol
rename Conmee English_name
duplicates drop Symbol, force // 1 obs
save ${temp_output}CSMAR_Engname.dta, replace // vars: Symbol English_name


* (6) CSMAR - State-owned enterprises
use ${CSMAR}BDT_ManaGovAbil.dta, clear
gen year = substr(Enddate, 1, 4)
destring year, replace
keep Symbol year PropertyRightsNature
rename PropertyRightsNature state_owned
label var state_owned "1=State-owned enterprises, 0=Private enterprises"
save ${temp_output}CSMAR_stateowned.dta, replace // vars: Symbol year state_owned


use ${CSMAR}BDT_ManaGovAbil.dta, clear
gen year = substr(Enddate, 1, 4)
destring year, replace
keep Symbol ShortName year PropertyRightsNature
rename PropertyRightsNature state_owned
label var state_owned "1=State-owned enterprises, 0=Private enterprises"

sort Symbol year
bysort Symbol: egen min_state = min(state_owned)
bysort Symbol: egen max_state = max(state_owned)

gen change = (min_state == 0 & max_state == 1)

keep Symbol ShortName year state_owned change
duplicates drop
tab change
keep if change == 1
save ${temp_output}Listed_firm_SOE_change.dta, replace

********************************************************************************
******************** Moderator: whether has academic experience ****************
********************************************************************************

* Identify whether TMT members have academic experience

/* (1) Existing field in CSMAR

use ${CSMAR}TMT_FIGUREINFO.dta, clear
gen year = substr(Reptdt, 1, 4)
destring year, replace
keep Stkcd year PersonID Academic
duplicates drop
label var Academic "1=University teaching, 2=Research institute position, 3=Association research work, 4=No academic research background"

gen academic_exp = 0
replace academic_exp = 1 if Academic == "1" | Academic == "1,2" | Academic == "1,2,3" | Academic == "1,3"
label var academic_exp "1=has academic experience"

order Stkcd year PersonID Academic academic_exp

bys Stkcd year: egen academic_experience = sum(academic_exp)
label var academic_experience "Proportion of academic background in the TMT"
keep Stkcd year academic_experience
duplicates drop
rename Stkcd Symbol

destring Symbol, replace

save ${temp_output}CSMAR_academic_exp.dta, replace // vars: Symbol year academic_experience

*/

* (2) Identify from resume text - use this
use ${CSMAR}TMT_FIGUREINFO.dta, clear
gen year = substr(Reptdt, 1, 4)
destring year, replace
keep Stkcd year PersonID Resume
duplicates drop

gen academic_exp = 0
replace academic_exp = 1 if strpos(Resume, "博士")

bys Stkcd year: egen academic_experience = mean(academic_exp)
label var academic_experience "Proportion of academic background in the TMT"
keep Stkcd year academic_experience
duplicates drop
rename Stkcd Symbol


save ${temp_output}CSMAR_academic_exp.dta, replace // vars: Symbol year academic_experience

********************************************************************************
***** Moderator:  The proportion of employees who are postgraduate students ****
********************************************************************************

use ${CSMAR}STK_CompanyStaff.dta, clear
keep if EmployStructure=="学历"
gen year = substr(EndDate, 1, 4)
destring year, replace

drop if strpos(EmployDetail, "合计") > 0

gen high_aca = 0
replace high_aca = 1 if strpos(EmployDetail, "硕士") > 0 | strpos(EmployDetail, "研究生") > 0 | strpos(EmployDetail, "博士") > 0
keep if high_aca == 1

bys Symbol year: egen master_above = sum(Amount)
order Symbol year high_aca master_above
keep Symbol year master_above
duplicates drop
save ${temp_output}process.dta, replace // vars: Symbol year master_above


use ${CSMAR}STK_CompanyStaff.dta, clear
keep if EmployStructure=="总人数"
gen year = substr(EndDate, 1, 4)
destring year, replace
keep Symbol year Amount EmployDetail
bys Symbol year: egen total_emp = max(Amount)
keep Symbol year total_emp
duplicates drop

merge 1:1 Symbol year using ${temp_output}process.dta
drop if _merge == 2
drop _merge

gen master_above_ratio = master_above / total_emp

save ${temp_output}CSMAR_master_above.dta, replace // vars: Symbol year total_emp master_above master_above_ratio


erase ${temp_output}process.dta


********************************************************************************
************** Moderator:  Overseas revenue share and affiliations *************
********************************************************************************

use ${CSMAR}OFDI_OPERATEINCOME.dta, clear
gen year = substr(EndDate, 1, 4)
destring year, replace


split EndDate, p("-")
keep if EndDate2 == "12"
keep if VestingPeriod == 1 // Current period
keep if StateTypeCode == 1 // Consolidated financial statements

keep Symbol year Category Area EarningsProportion

bys Symbol year: egen oversea_ratio = sum(EarningsProportion)
keep Symbol year oversea_ratio
duplicates drop
label var oversea_ratio "Overseas income/total income"
save ${temp_output}CSMAR_oversea_ratio.dta, replace // vars: Symbol year oversea_ratio



use ${CSMAR}OFDI_AFFCOMPINFO.dta, clear
* Optional filter example: keep only the United States in `CountryName`
keep if CountryName=="美国"
*drop if CountryName == "中国香港" | CountryName == "中国澳门" | CountryName == "中国台湾"
keep if RelationshipID == "1" // 1. Subsidiary of the listed company; 2. Associate; 3. Joint venture
keep Symbol
duplicates drop
gen US_aff = 1

label var US_aff "Firms with affiliated companies in the US"
save ${temp_output}CSMAR_US_aff.dta, replace // vars: Symbol US_aff



********************************************************************************
**************************** Moderator:  State subsidy *************************
********************************************************************************

*** All subsidies
use ${CSMAR}PT_LCGovGrants.dta, clear
keep if regexm(Item, "合计")

gen year = substr(Accper, 1, 4)
destring year, replace
keep Stkcd year Amount DataSources
duplicates drop
drop if Amount == .

bys Stkcd year DataSources: egen subsidy_onesource = max(Amount)
keep Stkcd year DataSources subsidy_onesource
duplicates drop

bys Stkcd year: egen subsidy = sum(subsidy_onesource)
keep Stkcd year subsidy
duplicates drop
rename Stkcd Symbol
save ${temp_output}CSMAR_subsidy.dta, replace // vars: Symbol year subsidy


********************************************************************************
******************************** Moderator:  tax *******************************
********************************************************************************

use ${CSMAR}TIRD_TaxIndicator.dta, clear

gen year = substr(EndDate, 1, 4)
destring year, replace
keep Symbol year RDAddDedTaxDeduction IncomeTaxDeduction
duplicates drop

save ${temp_output}CSMAR_tax.dta, replace // vars: Symbol year RDAddDedTaxDeduction IncomeTaxDeduction


////////////////////////////////////////////////////////////////////////////////
////////////////////////////// Merge Intermediate Files /////////////////////////
////////////////////////////////////////////////////////////////////////////////

use ${temp_output}CSMAR_basicinfo.dta, clear
merge 1:1 Symbol year using ${temp_output}CSMAR_R&D.dta
drop if _merge == 2
drop _merge
merge 1:1 Symbol year using ${temp_output}CSMAR_ROA.dta
drop if _merge == 2
drop _merge
merge 1:1 Symbol year using ${temp_output}CSMAR_finance.dta
drop if _merge == 2
drop _merge
merge m:1 Symbol using ${temp_output}CSMAR_Engname.dta // If matching only on Symbol, this should be m:1
drop if _merge == 2
drop _merge
merge 1:1 Symbol year using ${temp_output}CSMAR_stateowned.dta
drop if _merge == 2
drop _merge

* Moderators
merge 1:1 Symbol year using ${temp_output}CSMAR_academic_exp.dta
drop if _merge == 2
drop _merge
merge 1:1 Symbol year using ${temp_output}CSMAR_master_above.dta
drop if _merge == 2
drop _merge
merge 1:1 Symbol year using ${temp_output}CSMAR_oversea_ratio.dta
drop if _merge == 2
drop _merge
merge m:1 Symbol using ${temp_output}CSMAR_US_aff.dta
drop if _merge == 2
drop _merge

* State subsidy
merge m:1 Symbol year using ${temp_output}CSMAR_subsidy.dta
drop if _merge == 2
drop _merge

* tax
merge m:1 Symbol year using ${temp_output}CSMAR_tax.dta
drop if _merge == 2
drop _merge

/*
foreach var in RDSpendSum ROA CashHoldings AssetLiabilityRatio TobinQ RegisterCapital IndustryCode PROVINCE SocialCreditCode {
    drop if missing(`var')
}

drop if SocialCreditCode=="None"
*/

order Symbol year
destring Symbol, replace

*duplicates drop Symbol year, force
save ${stata_output}CSMAR_cv.dta, replace // vars: Symbol SocialCreditCode year...




keep Symbol English_name
duplicates drop
export delimited using ${stata_output}CSMAR_Engname.csv, replace





erase ${temp_output}CSMAR_basicinfo.dta
erase ${temp_output}CSMAR_R&D.dta
erase ${temp_output}CSMAR_ROA.dta
erase ${temp_output}CSMAR_finance.dta
erase ${temp_output}CSMAR_Engname.dta
erase ${temp_output}CSMAR_stateowned.dta
erase ${temp_output}CSMAR_academic_exp.dta
erase ${temp_output}CSMAR_master_above.dta
erase ${temp_output}CSMAR_oversea_ratio.dta
erase ${temp_output}CSMAR_US_aff.dta
erase ${temp_output}CSMAR_subsidy.dta
erase ${temp_output}CSMAR_tax.dta
