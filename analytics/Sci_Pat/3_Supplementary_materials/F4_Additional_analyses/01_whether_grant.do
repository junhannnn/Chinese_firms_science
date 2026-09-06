/*******************************************************************************
Project: Science-linked patents—supplementary additional analyses
Script:  01_whether_grant.do

Purpose:
  Estimate whether examination after Entity List designation is associated with
  the probability that a Chinese invention-patent application is granted. Compare
  specifications with and without patent controls and fixed effects on a common
  estimation sample.

Main input (from ${CN_patents}):
  - Chinese_patent_application2010-2023.dta

Main output (under ${table_output}):
  - whether_grant.rtf: grant-outcome estimates from three specifications

Notes:
  The analysis retains Chinese applications filed from 2010 through 2022 with an
  observed grant or rejection outcome. `post_el` identifies decisions occurring
  after Entity List designation. Patent controls cover co-applicants, pages,
  backward citations, claims, scope, PCT status, cumulative patenting, and the
  rolling three-year mean number of claims.
*******************************************************************************/

* ==============================================================================
* 1. Prepare the patent-application sample
* ==============================================================================

use "${CN_patents}Chinese_patent_application2010-2023.dta", clear

keep if apply_year>=2010 & apply_year<=2022
keep if 申请人国家地区=="中国"
gen ln_sum_patents = ln(sum_patents+1)

* ==============================================================================
* 2. Define the common estimation sample using the most restrictive model
* ==============================================================================

reghdfe granted post_el co_applicants pages backward_citations claims patent_scope PCT ///
    ln_sum_patents roll3_mean_claims, ///
    absorb(firm_id apply_year IPC4digit) vce(cluster firm_id)

gen byte common_sample = e(sample)

* ==============================================================================
* 3. Estimate all specifications on the common sample
* ==============================================================================

reghdfe granted post_el if common_sample == 1, ///
    absorb(firm_id apply_year IPC4digit) vce(cluster firm_id)
est store M1

reghdfe granted post_el co_applicants pages backward_citations claims patent_scope PCT ///
    ln_sum_patents roll3_mean_claims if common_sample == 1, ///
    vce(cluster firm_id)
est store M2

reghdfe granted post_el co_applicants pages backward_citations claims patent_scope PCT ///
    ln_sum_patents roll3_mean_claims if common_sample == 1, ///
    absorb(firm_id apply_year IPC4digit) vce(cluster firm_id)
est store M3
* ==============================================================================
* 4. Export the grant-outcome results table
* ==============================================================================

esttab M1 M2 M3 using ${table_output}whether_grant.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3") ///
	note("Firm, year, and IPC subclass FE")
