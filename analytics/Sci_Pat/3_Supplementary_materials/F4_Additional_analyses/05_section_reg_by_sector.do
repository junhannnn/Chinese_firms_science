/*******************************************************************************
Project: Science-linked patents - supplementary sector robustness
Script:  05_section_reg_by_sector.do

Purpose:
  Check whether the estimated sanction effect is driven by any single broad
  IPC technology section. Re-estimate the baseline model after excluding each
  section in turn, using level OLS, log-transformed OLS, and Poisson models.
  The three output tables correspond to the three blocks of Table S44.

Main input (from ${stata_output}):
  - DID_allfirm-level.dta

Main outputs (under ${table_output}):
  - robust_drop_one_industry_1.rtf: Table S44, block (1), OLS
  - robust_drop_one_industry_2.rtf: Table S44, block (2), Ln + OLS
  - robust_drop_one_industry_3.rtf: Table S44, block (3), Poisson

Notes:
  - Run after defining stata_output and table_output, as in the supplementary
    00_run_all.do runner. Required commands: reghdfe, ppmlhdfe, and esttab.
  - The first character of the existing firm industry code defines its IPC
    section; this script does not recompute the firm's industry assignment.
  - The input is assumed to contain all eight sections A-H. encode assigns
    their numeric identifiers alphabetically, so IDs 1-8 correspond to A-H.
  - Within each output, Models 1-8 exclude sections A-H, respectively. These
    are exclusions from the estimation sample, not reference categories in
    an interaction model. Model names are reused for each outcome.
  - All models control for whether_pat, absorb firm and year fixed effects,
    and use heteroskedasticity-robust standard errors via vce(r).
*******************************************************************************/

* ==============================================================================
* 1. Construct the broad IPC-section identifier
* ==============================================================================

use ${stata_output}DID_allfirm-level.dta, clear

* Count distinct industry_id values in the loaded panel as a diagnostic.
bysort industry_id: gen tag1 = (_n == 1)
count if tag1 == 1

* Extract the IPC section from the existing industry code and encode A-H.
* Expected mapping for the exclusions below:
*   1=A Human Necessities; 2=B Performing Operations / Transporting;
*   3=C Chemistry / Metallurgy; 4=D Textiles / Paper;
*   5=E Fixed Constructions;
*   6=F Mechanical Engineering / Lighting / Heating / Weapons;
*   7=G Physics; 8=H Electricity.
gen industry_section = substr(industry, 1, 1)
encode industry_section, gen(industry_section_id)

* Check the number of section groups; the intended A-H classification has eight.
bysort industry_section_id: gen tag2 = (_n == 1)
count if tag2 == 1

* ==============================================================================
* 2. Table S44, block (1): OLS with the winsorized patent count
* ==============================================================================

* Use the precomputed winsorized outcome f_cite_science_num_w.
* Each model retains the other seven sections; M1 drops A, ..., M8 drops H.
reghdfe f_cite_science_num_w did whether_pat if industry_section_id!=1, absorb(firm_id year) vce(r)
est store M1
reghdfe f_cite_science_num_w did whether_pat if industry_section_id!=2, absorb(firm_id year) vce(r)
est store M2
reghdfe f_cite_science_num_w did whether_pat if industry_section_id!=3, absorb(firm_id year) vce(r)
est store M3
reghdfe f_cite_science_num_w did whether_pat if industry_section_id!=4, absorb(firm_id year) vce(r)
est store M4
reghdfe f_cite_science_num_w did whether_pat if industry_section_id!=5, absorb(firm_id year) vce(r)
est store M5
reghdfe f_cite_science_num_w did whether_pat if industry_section_id!=6, absorb(firm_id year) vce(r)
est store M6
reghdfe f_cite_science_num_w did whether_pat if industry_section_id!=7, absorb(firm_id year) vce(r)
est store M7
reghdfe f_cite_science_num_w did whether_pat if industry_section_id!=8, absorb(firm_id year) vce(r)
est store M8
* Export Models 1-8 in excluded-section order A-H. The patent-dummy control
* remains in every regression but its coefficient is omitted from the table.
esttab M1 M2 M3 M4 M5 M6 M7 M8 using ${table_output}robust_drop_one_industry_1.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ///
	b(%20.3f) se(%7.3f) r2(%9.3f) drop("whether_pat") ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	nonotes
* ==============================================================================
* 3. Table S44, block (2): OLS with the log-transformed patent count
* ==============================================================================

* Use the precomputed ln_f_cite_science_num outcome and repeat exclusions A-H.
* Store the new estimates as M1-M8 after exporting the preceding OLS block.
reghdfe ln_f_cite_science_num did whether_pat if industry_section_id!=1, absorb(firm_id year) vce(r)
est store M1
reghdfe ln_f_cite_science_num did whether_pat if industry_section_id!=2, absorb(firm_id year) vce(r)
est store M2
reghdfe ln_f_cite_science_num did whether_pat if industry_section_id!=3, absorb(firm_id year) vce(r)
est store M3
reghdfe ln_f_cite_science_num did whether_pat if industry_section_id!=4, absorb(firm_id year) vce(r)
est store M4
reghdfe ln_f_cite_science_num did whether_pat if industry_section_id!=5, absorb(firm_id year) vce(r)
est store M5
reghdfe ln_f_cite_science_num did whether_pat if industry_section_id!=6, absorb(firm_id year) vce(r)
est store M6
reghdfe ln_f_cite_science_num did whether_pat if industry_section_id!=7, absorb(firm_id year) vce(r)
est store M7
reghdfe ln_f_cite_science_num did whether_pat if industry_section_id!=8, absorb(firm_id year) vce(r)
est store M8
* Export the log-outcome estimates in the same excluded-section order A-H.
esttab M1 M2 M3 M4 M5 M6 M7 M8 using ${table_output}robust_drop_one_industry_2.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ///
	b(%20.3f) se(%7.3f) r2(%9.3f) drop("whether_pat") ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	nonotes
* ==============================================================================
* 4. Table S44, block (3): Poisson with the original patent count
* ==============================================================================

* Fit Poisson pseudo-maximum-likelihood models using f_cite_science_num.
* Repeat exclusions A-H. ppmlhdfe may additionally remove observations because
* of separation or singleton fixed-effect groups, so N can differ from OLS.
ppmlhdfe f_cite_science_num did whether_pat if industry_section_id!=1, absorb(firm_id year) vce(r)
est store M1
ppmlhdfe f_cite_science_num did whether_pat if industry_section_id!=2, absorb(firm_id year) vce(r)
est store M2
ppmlhdfe f_cite_science_num did whether_pat if industry_section_id!=3, absorb(firm_id year) vce(r)
est store M3
ppmlhdfe f_cite_science_num did whether_pat if industry_section_id!=4, absorb(firm_id year) vce(r)
est store M4
ppmlhdfe f_cite_science_num did whether_pat if industry_section_id!=5, absorb(firm_id year) vce(r)
est store M5
ppmlhdfe f_cite_science_num did whether_pat if industry_section_id!=6, absorb(firm_id year) vce(r)
est store M6
ppmlhdfe f_cite_science_num did whether_pat if industry_section_id!=7, absorb(firm_id year) vce(r)
est store M7
ppmlhdfe f_cite_science_num did whether_pat if industry_section_id!=8, absorb(firm_id year) vce(r)
est store M8
* Export the count-outcome estimates in excluded-section order A-H. The shared
* export layout includes both R2 and pseudo-R2 slots; unavailable values are blank.
esttab M1 M2 M3 M4 M5 M6 M7 M8 using ${table_output}robust_drop_one_industry_3.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ///
	b(%20.3f) se(%7.3f) r2(%9.3f) drop("whether_pat") ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	nonotes
