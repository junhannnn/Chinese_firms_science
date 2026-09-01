

********************************************************************************
*************** Staggered DID analysis: closeness to science (CNKI) ************
********************************************************************************

use ${stata_output}DID_allfirm-level.dta, clear

reghdfe f_cnki_closeness_max did, absorb(firm_id year) vce(r)
est store M1


********************************************************************************
*************** Staggered DID analysis: closeness to science (WOS) ************
********************************************************************************

use ${stata_output}DID_allfirm-level.dta, clear

* max
reghdfe f_wos_closeness_max did, absorb(firm_id year) vce(r)
est store M2


esttab M1 M2 using ${table_output}science_closeness.rtf, ///
    replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ///
    b(%20.3f) se(%7.3f) r2(%9.3f) ///
    stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
    mtitles("Model 1" "Model 2") ///
    nonotes

