/*******************************************************************************
Project: Science-linked patents—Chinese-firm analysis
Script:  02_moderators.do

Purpose:
  Test whether the moderator for firms' reliance on U.S. patent
  technology changes the estimated difference-in-differences (DID) effect on
  science-linked patenting. The script compares level, log-transformed, and
  Poisson specifications in the full sample and CEM-weighted sample.

Main inputs:
  - ${stata_output}DID_allfirm_mo.dta (full panel with moderator)
  - ${stata_output}DID_allfirm_mo_cem.dta (CEM panel, moderator, and weights)

Main outputs:
  - ${table_output}mo_summary_stats.doc (moderator summary statistics)
  - ${table_output}main_mo_uspat.rtf (full-sample and CEM estimates)

Required setup:
  The master runner defines stata_output and table_output before calling this
  file. The script also requires the community-contributed commands asdoc,
  reghdfe, ppmlhdfe, and esttab.
*******************************************************************************/

* ==============================================================================
* 1. Estimate moderator models for the full sample
* ==============================================================================

use ${stata_output}DID_allfirm_mo.dta, clear

* Export descriptive statistics for the binary moderator.
asdoc tabstat moderator, ///
    save(${table_output}mo_summary_stats.doc) replace ///
    stat(N mean sd min max)

* Each model includes the DID indicator, moderator, their interaction, and the
* patent-activity indicator, with firm and year fixed effects.
* Model 1: linear specification for winsorized science-linked patent counts.
reghdfe f_cite_science_num_w did##moderator whether_pat, absorb(firm_id year) vce(r)
est store M1

* Model 2: linear specification for log-transformed counts.
reghdfe ln_f_cite_science_num did##moderator whether_pat, absorb(firm_id year) vce(r)
est store M2

* Model 3: Poisson specification for counts.
ppmlhdfe f_cite_science_num did##moderator whether_pat, absorb(firm_id year) vce(r)
est store M3

* ==============================================================================
* 2. Estimate CEM-weighted moderator models
* ==============================================================================

use ${stata_output}DID_allfirm_mo_cem.dta, clear

* Model 4: CEM analytically weighted linear specification for winsorized counts.
reghdfe f_cite_science_num_w did##moderator whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r)
est store M4

* Model 5: CEM analytically weighted linear specification for log counts.
reghdfe ln_f_cite_science_num did##moderator whether_pat [aweight=cem_weights], absorb(firm_id year) vce(r)
est store M5

* Model 6: CEM probability-weighted Poisson specification for counts.
ppmlhdfe f_cite_science_num did##moderator whether_pat [pweight=cem_weights], absorb(firm_id year) vce(r)
est store M6

* Export the full-sample and CEM-weighted estimates in one table.
esttab M1 M2 M3 M4 M5 M6 using ${table_output}main_mo_uspat.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	nobaselevels drop("1.moderator" "whether_pat") ///
	mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
	mgroups("Full sample" "Matched sample", pattern(1 0 0 1 0 0)) ///
	nonotes 
