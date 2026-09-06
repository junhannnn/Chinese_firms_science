/*******************************************************************************
Project: Science-linked patents—Chinese-firm analysis
Script:  04_vintage.do

Purpose:
  Estimate how treatment status relates to the publication vintage of science
  cited by Chinese-firm patents. Separate models use the minimum, maximum, mean,
  and median publication-year measures.

Main input:
  ${stata_output}DID_allfirm-level.dta

Main output:
  ${table_output}vintage.rtf

Required setup:
  The master runner defines stata_output and table_output before calling this
  file. The script also requires the community-contributed commands reghdfe and
  esttab.
*******************************************************************************/

* ==============================================================================
* 1. Estimate publication-vintage models
* ==============================================================================

use ${stata_output}DID_allfirm-level.dta, clear

* Model 1: earliest publication year among cited papers.
reghdfe f_paperyear_min did whether_pat, absorb(firm_id year) vce(r)
est store M1

* Model 2: latest publication year among cited papers.
reghdfe f_paperyear_max did whether_pat, absorb(firm_id year) vce(r)
est store M2

* Model 3: mean publication year among cited papers.
reghdfe f_paperyear_mean did whether_pat, absorb(firm_id year) vce(r)
est store M3

* Model 4: median publication year among cited papers.
reghdfe f_paperyear_med did whether_pat, absorb(firm_id year) vce(r)
est store M4

* ==============================================================================
* 2. Export the publication-vintage estimates
* ==============================================================================

esttab M1 M2 M3 M4 using ${table_output}vintage.rtf, ///
	replace star( * 0.11 ** 0.05 *** 0.01 ) nogaps compress ///
	b(%20.3f) se(%7.3f) r2(%9.3f) drop("whether_pat") ///
	stats(N r2, fmt(%15.0fc %9.3f) labels("Observations" "R2")) ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4") ///
	nonotes
