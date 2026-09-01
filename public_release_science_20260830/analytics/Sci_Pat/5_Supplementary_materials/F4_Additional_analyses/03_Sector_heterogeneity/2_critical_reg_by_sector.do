

use "${stata_output}DID_allfirm-level.dta", clear

********************************************************************************
* Clean IPC4-like industry variable
********************************************************************************

capture confirm variable industry
if _rc {
    di as error "Variable industry not found."
    exit 111
}

capture drop industry_raw industry_clean ipc4_std ipc3_std

capture confirm string variable industry
if _rc {
    tostring industry, gen(industry_raw) force usedisplayformat
}
else {
    gen str80 industry_raw = industry
}

gen str80 industry_clean = upper(strtrim(industry_raw))
replace industry_clean = subinstr(industry_clean, " ", "", .)
replace industry_clean = subinstr(industry_clean, ".", "", .)
replace industry_clean = subinstr(industry_clean, "/", "", .)
replace industry_clean = subinstr(industry_clean, "-", "", .)

gen str4 ipc4_std = substr(industry_clean, 1, 4)
gen str3 ipc3_std = substr(industry_clean, 1, 3)

********************************************************************************
* Initialize NSF/TIP 11 technology-area flags
********************************************************************************

local techvars ai adv_mfg adv_comm biotech quantum semi adv_energy ///
               adv_mat disaster cyber cyberinfra

foreach v of local techvars {
    capture drop is_`v'
    gen byte is_`v' = 0
}

********************************************************************************
* 1. Artificial Intelligence
********************************************************************************

replace is_ai = 1 if inlist(ipc4_std, "G06N", "G06V", "G06T", "G06K", "G10L")
label var is_ai "Artificial Intelligence"

********************************************************************************
* 2. Advanced Manufacturing
********************************************************************************

replace is_adv_mfg = 1 if inlist(ipc3_std, "B21", "B22", "B23", "B24", "B29") ///
                      | inlist(ipc4_std, "B25J", "B30B", "B33Y", "G05B") ///
                      | inlist(ipc4_std, "B22F", "B23K", "B23Q", "B29C")
label var is_adv_mfg "Advanced Manufacturing"

********************************************************************************
* 3. Communications and Wireless
********************************************************************************

replace is_adv_comm = 1 if inlist(ipc4_std, "H04B", "H04L", "H04W", "H01Q")
label var is_adv_comm "Communications and Wireless"

********************************************************************************
* 4. Biotechnology
********************************************************************************

replace is_biotech = 1 if inlist(ipc4_std, "C12N", "C12P", "C12Q", "C07K") ///
                      | inlist(ipc4_std, "A61K", "A61P")
label var is_biotech "Biotechnology"

********************************************************************************
* 5. Quantum Information Science
********************************************************************************

* IPC4 cannot identify quantum precisely.
* This is a broad IPC4-level proxy.
replace is_quantum = 1 if inlist(ipc4_std, "G06N", "G02B", "H01L", "H01S")
label var is_quantum "Quantum Information Science"

********************************************************************************
* 6. Semiconductors and Microelectronics
********************************************************************************

replace is_semi = 1 if inlist(ipc4_std, "H01L", "G11C", "B81B", "B81C") ///
                   | inlist(ipc4_std, "H10B", "H10D", "H10F", "H10H") ///
                   | inlist(ipc4_std, "H10K", "H10N", "H10P", "H10W") ///
                   | inlist(ipc4_std, "C30B", "H05K")
label var is_semi "Semiconductors and Microelectronics"

********************************************************************************
* 7. Energy Technology
********************************************************************************

replace is_adv_energy = 1 if inlist(ipc4_std, "H01M", "F03D", "H02J", ///
                                    "C25B", "F24S", "H02S")
label var is_adv_energy "Energy Technology"

********************************************************************************
* 8. Advanced Materials
********************************************************************************

replace is_adv_mat = 1 if inlist(ipc4_std, "C01B", "C03C", "C04B", "C08J") ///
                      | inlist(ipc4_std, "C08K", "C08L", "C09D", "C09K") ///
                      | inlist(ipc4_std, "C21D", "C22C", "C22F", "C23C") ///
                      | inlist(ipc4_std, "C23F", "C25D", "B32B", "B82Y") ///
                      | inlist(ipc4_std, "H01B")
label var is_adv_mat "Advanced Materials"

********************************************************************************
* 9. Cyberinfrastructure and Advanced Computing
********************************************************************************

replace is_cyberinfra = 1 if inlist(ipc4_std, "G06F", "G06N", "G06E", "G06T") ///
                         | inlist(ipc4_std, "G06V", "G11C", "H04L")
label var is_cyberinfra "Cyberinfrastructure and Advanced Computing"

********************************************************************************
* 10. Disaster Risk and Resilience
********************************************************************************

replace is_disaster = 1 if inlist(ipc4_std, "G08B", "G01W", "G01V", "E02B") ///
                       | inlist(ipc4_std, "A62C", "A62D", "G01S")
label var is_disaster "Disaster Risk and Resilience"

********************************************************************************
* 11. Cybersecurity
********************************************************************************

* IPC4 cannot isolate cybersecurity precisely.
* This is a broad IPC4-level proxy.
replace is_cyber = 1 if inlist(ipc4_std, "H04L", "G06F", "H04W")
label var is_cyber "Cybersecurity"

********************************************************************************
* Derived helpers
********************************************************************************

capture drop n_sectors is_all_cta

egen n_sectors = rowtotal(is_ai is_adv_comm is_biotech is_adv_mfg ///
                          is_quantum is_semi is_adv_energy is_adv_mat ///
                          is_cyberinfra is_disaster is_cyber)
label var n_sectors "Number of NSF/TIP technology areas matched"

gen byte is_all_cta = (n_sectors > 0)
label var is_all_cta "All NSF/TIP critical technology areas"




*** OLS
reghdfe f_cite_science_num_w did whether_pat, absorb(firm_id year) vce(r)
est store M1
reghdfe f_cite_science_num_w did##is_all_cta whether_pat, absorb(firm_id year) vce(r)
est store M2

* ln and OLS
reghdfe ln_f_cite_science_num did whether_pat, absorb(firm_id year) vce(r)
est store M3
reghdfe ln_f_cite_science_num did##is_all_cta whether_pat, absorb(firm_id year) vce(r)
est store M4

* Poisson
ppmlhdfe f_cite_science_num did whether_pat, absorb(firm_id year) vce(r)
est store M5
ppmlhdfe f_cite_science_num did##is_all_cta whether_pat, absorb(firm_id year) vce(r)
est store M6


esttab M1 M2 M3 M4 M5 M6 using ${table_output}industry_difference_cri.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	nonotes
	
	
	

reghdfe f_cite_science_num_w did whether_pat if is_all_cta==0, absorb(firm_id year) vce(r)
est store M1
reghdfe f_cite_science_num_w did whether_pat if is_all_cta==1, absorb(firm_id year) vce(r)
est store M2

reghdfe ln_f_cite_science_num did whether_pat if is_all_cta==0, absorb(firm_id year) vce(r)
est store M3
reghdfe ln_f_cite_science_num did whether_pat if is_all_cta==1, absorb(firm_id year) vce(r)
est store M4

ppmlhdfe f_cite_science_num did whether_pat if is_all_cta==0, absorb(firm_id year) vce(r)
est store M5
ppmlhdfe f_cite_science_num did whether_pat if is_all_cta==1, absorb(firm_id year) vce(r)
est store M6

esttab M1 M2 M3 M4 M5 M6 using ${table_output}robust_drop_one_industry_cri.rtf, ///
	replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ///
	b(%20.3f) se(%7.3f) r2(%9.3f) ///
	stats(N r2 r2_p, fmt(%15.0fc %9.3f %9.3f) labels("Observations" "R2" "Pseudo R2")) ///
	nonotes