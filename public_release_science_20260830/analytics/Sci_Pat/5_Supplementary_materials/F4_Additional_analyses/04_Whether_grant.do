
/*
# This dataset only retains invention patents filed by Chinese firms between 2010 and 2023,
# with an examination outcome available, i.e., either rejection or grant.

# post_el equals 1 if a patent received its examination decision only after the Entity List designation.

# Variables:
# co_applicants: number of co-applicants
# pages: number of pages in the patent document
# backward_citations: number of backward citations
# claims: number of claims
# patent_scope: scope of the patent
# PCT: dummy variable equal to 1 if the patent is a PCT application, and 0 otherwise
# ln_sum_patents: log of the cumulative number of invention patents filed by the firm up to the given year
# roll3_mean_claims: rolling three-year average number of claims in patents filed by the firm

*/


use "${CN_patents}Chinese_patent_application2010-2023.dta", clear

keep if apply_year>=2010 & apply_year<=2022
keep if 申请人国家地区=="中国"
gen ln_sum_patents = ln(sum_patents+1)

* Step 1: run the most restrictive model first
reghdfe granted post_el co_applicants pages backward_citations claims patent_scope PCT ///
    ln_sum_patents roll3_mean_claims, ///
    absorb(firm_id apply_year IPC4digit) vce(cluster firm_id)

gen byte common_sample = e(sample)

* Step 2: re-run all models on the same sample
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


esttab M1 M2 M3 using ${table_output}whether_grant.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress order(did) ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	mtitles("Model 1" "Model 2" "Model 3") ///
	note("Firm, year, and IPC subclass FE")
