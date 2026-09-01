

********************************************************************************
*************************** CN patents filed by CN firms ***********************
********************************************************************************

use "${stata_output}Chinese_patents_filed_by_EL_otherfirms.dta", clear

* Merge with IPC
merge 1:1 apn using "${stata_output}CNpatents_mainipc.dta"
drop if _merge==2
drop _merge

********************************************************************************
* IPC4 cleaning
********************************************************************************

* This code assumes your IPC4 variable is ipc_subclass.
* If your actual variable name is different, change ipc_subclass below.

capture drop ipc_raw ipc_clean ipc4_std ipc3_std

capture confirm string variable ipc_subclass
if _rc {
    tostring ipc_subclass, gen(ipc_raw) force usedisplayformat
}
else {
    gen str80 ipc_raw = ipc_subclass
}

gen str80 ipc_clean = upper(strtrim(ipc_raw))
replace ipc_clean = subinstr(ipc_clean, " ", "", .)
replace ipc_clean = subinstr(ipc_clean, ".", "", .)
replace ipc_clean = subinstr(ipc_clean, "/", "", .)
replace ipc_clean = subinstr(ipc_clean, "-", "", .)

gen str4 ipc4_std = substr(ipc_clean, 1, 4)
gen str3 ipc3_std = substr(ipc_clean, 1, 3)

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
* H04L, G06F, and H04W are broad IPC4-level proxies.
replace is_cyber = 1 if inlist(ipc4_std, "H04L", "G06F", "H04W")
label var is_cyber "Cybersecurity"

********************************************************************************
* Derived helpers
********************************************************************************

capture drop n_sectors is_all_cta

egen n_sectors = rowtotal(is_ai is_adv_mfg is_adv_comm is_biotech ///
                          is_quantum is_semi is_adv_energy is_adv_mat ///
                          is_cyberinfra is_disaster is_cyber)
label var n_sectors "Number of NSF/TIP technology areas matched"

gen byte is_all_cta = (n_sectors > 0)
label var is_all_cta "All NSF/TIP critical technology areas"

********************************************************************************
* Title mapping
********************************************************************************

local ttl_ai          "Artificial Intelligence"
local ttl_adv_mfg     "Advanced Manufacturing"
local ttl_adv_comm    "Communications and Wireless"
local ttl_biotech     "Biotechnology"
local ttl_quantum     "Quantum Information Science"
local ttl_semi        "Semiconductors and Microelectronics"
local ttl_adv_energy  "Energy Technology"
local ttl_adv_mat     "Advanced Materials"
local ttl_cyberinfra  "Cyberinfrastructure and Advanced Computing"
local ttl_disaster    "Disaster Risk and Resilience"
local ttl_cyber       "Cybersecurity"
local ttl_all_cta     "All critical technology areas"

********************************************************************************
* 12 graphs: 11 subfields + ALL
********************************************************************************

local sectors all_cta ai adv_mfg adv_comm biotech quantum semi adv_energy ///
              adv_mat cyberinfra disaster cyber

foreach s of local sectors {

    preserve

    local ttl "`ttl_`s''"

    * Keep sector / ALL observations
    keep if is_`s' == 1

    * Rename for plotting
    capture drop year
    rename grtyr year

    * Sample window
    keep if year >= 2010 & year <= 2022

    * If no observations, create an empty graph to avoid breaking graph combine
    count
    if r(N) == 0 {
        clear
        set obs 1
        gen year = 2010
        gen y = 0

        twoway (scatter y year, msymbol(none)), ///
            title("{bf:`ttl'}", size(medsmall)) ///
            note("No matched patents in 2010-2022", size(vsmall)) ///
            ytitle("Number", size(small)) ///
            xtitle("Year", size(small) placement(east)) ///
            xlabel(2010(2)2022, angle(45) labsize(small)) ///
            ylabel(0 "0", labsize(small)) ///
            legend(off) ///
            graphregion(margin(vsmall))

        graph save "${temp_output}bg_CNfirm_CNpat_`s'.gph", replace

        restore
        continue
    }

    ********************************************************************************
    * Yearly aggregates
    ********************************************************************************

    * Science-reliant patent indicator
    capture drop cite_science_bin
    gen byte cite_science_bin = (cite_science > 0) if !missing(cite_science)
    replace cite_science_bin = 0 if missing(cite_science_bin)

    * Patent count
    gen byte patent_one = 1

    * Unique firms per year
    sort year fapp_standard
    by year fapp_standard: gen byte firm1 = (_n == 1 & !missing(fapp_standard))

    * Unique firms with at least one science-reliant patent per year
    by year fapp_standard: egen has_citesci = max(cite_science_bin)
    by year fapp_standard: gen byte citesci_firm1 = ///
        (_n == 1 & has_citesci == 1 & !missing(fapp_standard))

    * Collapse to year level
    collapse ///
        (sum) patent_grtyr = patent_one ///
              sci_reliant_patent_grtyr = cite_science_bin ///
              unique_firm_yr = firm1 ///
              unique_citesci_firm_yr = citesci_firm1, ///
        by(year)

    * Derived metrics
    gen sci_reliant_ratio_grtyr = sci_reliant_patent_grtyr / patent_grtyr ///
        if patent_grtyr > 0

    gen sci_reliant_patent_grtyr_adj1 = sci_reliant_patent_grtyr / unique_firm_yr ///
        if unique_firm_yr > 0

    gen sci_reliant_patent_grtyr_adj2 = sci_reliant_patent_grtyr / unique_citesci_firm_yr ///
        if unique_citesci_firm_yr > 0

    ********************************************************************************
    * Endpoint indicators and labels
    ********************************************************************************

    gen byte ep2010 = (year == 2010)
    gen byte ep2022 = (year == 2022)

    gen str20 num_label = strtrim(string(sci_reliant_patent_grtyr, "%9.0fc"))
    gen str20 pct_label = strtrim(string(sci_reliant_ratio_grtyr * 100, "%9.2f")) + "%"

    gen double year_lbl_1 = year
    replace year_lbl_1 = year + 0.50 if year == 2010
    replace year_lbl_1 = year - 0.50 if year == 2022

    gen double year_lbl_2 = year
    replace year_lbl_2 = year + 0.20 if year == 2010
    replace year_lbl_2 = year - 0.20 if year == 2022

    ********************************************************************************
    * Plot
    ********************************************************************************

    twoway ///
        (connected sci_reliant_patent_grtyr year, ///
            yaxis(1) lwidth(medium) lcolor(red*1.4) lpattern(solid) ///
            msymbol(square) mcolor(red*1.5) msize(vsmall)) || ///
        (connected sci_reliant_ratio_grtyr year, ///
            yaxis(2) lwidth(medium) lcolor(ebblue*1.2) lpattern(dash) ///
            msymbol(circle) mcolor(ebblue*1.5) msize(vsmall)) || ///
        (scatter sci_reliant_patent_grtyr year_lbl_1 if ep2010, ///
            yaxis(1) msymbol(none) ///
            mlabel(num_label) mlabposition(6) mlabgap(0) ///
            mlabsize(small) mlabcolor(red*1.5)) || ///
        (scatter sci_reliant_patent_grtyr year_lbl_2 if ep2022, ///
            yaxis(1) msymbol(none) ///
            mlabel(num_label) mlabposition(11) mlabgap(-1) ///
            mlabsize(small) mlabcolor(red*1.5)) || ///
        (scatter sci_reliant_ratio_grtyr year_lbl_1 if ep2010, ///
            yaxis(2) msymbol(none) ///
            mlabel(pct_label) mlabposition(6) mlabgap(1) ///
            mlabsize(small) mlabcolor(ebblue*1.5)) || ///
        (scatter sci_reliant_ratio_grtyr year_lbl_1 if ep2022, ///
            yaxis(2) msymbol(none) ///
            mlabel(pct_label) mlabposition(12) mlabgap(1) ///
            mlabsize(small) mlabcolor(ebblue*1.5)), ///
        title("{bf:`ttl'}", size(medsmall)) ///
        ytitle("Number", axis(1) size(small)) ///
        ytitle("Share", axis(2) size(small)) ///
        ylabel(, axis(1) labsize(small) format(%9.0f)) ///
        ylabel(0 0.1 "10%" 0.2 "20%" 0.3 "30%" 0.4 "40%" ///
               0.5 "50%" 0.6 "60%", axis(2) labsize(small)) ///
        xtitle("Year", size(small) placement(east)) ///
        xlabel(2010(2)2022, angle(45) labsize(small)) ///
        legend(off) ///
        graphregion(margin(vsmall))

    graph save "${temp_output}bg_CNfirm_CNpat_`s'.gph", replace

    restore
}

********************************************************************************
* Combine graphs
********************************************************************************

graph combine ///
    "${temp_output}bg_CNfirm_CNpat_all_cta.gph" ///
    "${temp_output}bg_CNfirm_CNpat_ai.gph" ///
    "${temp_output}bg_CNfirm_CNpat_adv_mfg.gph" ///
    "${temp_output}bg_CNfirm_CNpat_adv_comm.gph" ///
    "${temp_output}bg_CNfirm_CNpat_biotech.gph" ///
    "${temp_output}bg_CNfirm_CNpat_quantum.gph" ///
    "${temp_output}bg_CNfirm_CNpat_semi.gph" ///
    "${temp_output}bg_CNfirm_CNpat_adv_energy.gph" ///
    "${temp_output}bg_CNfirm_CNpat_adv_mat.gph" ///
    "${temp_output}bg_CNfirm_CNpat_cyberinfra.gph" ///
    "${temp_output}bg_CNfirm_CNpat_disaster.gph" ///
    "${temp_output}bg_CNfirm_CNpat_cyber.gph", ///
    rows(3) cols(4) ///
    imargin(tiny) ///
    graphregion(margin(small))

gr_edit .plotregion1.graph2.yaxis1.reset_rule 0 8000 2000 , tickset(major) ruletype(range) 
gr_edit .plotregion1.graph5.yaxis1.reset_rule 0 7000 1500 , tickset(major) ruletype(range) 

graph save "${figure_output}bg_CNfirm_CNpat_bysector.gph", replace

********************************************************************************
* Clean temporary graph files
********************************************************************************

local flist : dir "${temp_output}" files "bg_CNfirm_CNpat_*.gph"
foreach f of local flist {
    erase "${temp_output}`f'"
}



********************************************************************************
* Bubble plots (2010 vs 2022): 11 sectors as points
* Full sector names shown as labels
********************************************************************************

capture postclose P

* Make sure year variable exists
capture confirm variable year
if _rc rename grtyr year

********************************************************************************
* Title mapping
********************************************************************************

local ttl_ai          "Artificial Intelligence"
local ttl_adv_mfg     "Advanced Manufacturing"
local ttl_adv_comm    "Communications" //Communications and Wireless
local ttl_biotech     "Biotechnology"
local ttl_quantum     "Quantum Information Science"
local ttl_semi        "Semiconductors and Microelectronics"
local ttl_adv_energy  "Energy Technology"
local ttl_adv_mat     "Advanced Materials"
local ttl_cyberinfra  "Advanced Computing" //Cyberinfrastructure and Advanced Computing
local ttl_disaster    "Disaster Risk and Resilience"
local ttl_cyber       "Cybersecurity"

********************************************************************************
* Sector list
********************************************************************************

local sectors "ai adv_mfg adv_comm biotech quantum semi adv_energy adv_mat cyberinfra disaster cyber"

tempfile sectorstats

postfile P str80 sector int year double sci_reliant_patent ///
          double patent_total double share using `sectorstats', replace

foreach s of local sectors {

    preserve

        keep if is_`s' == 1

        count
        if r(N) == 0 {
            restore
            continue
        }

        * Use same science-linked definition as the line graphs
        capture drop cite_science_bin
        gen byte cite_science_bin = (cite_science > 0) if !missing(cite_science)
        replace cite_science_bin = 0 if missing(cite_science_bin)

        gen byte one = 1

        collapse ///
            (sum) patent_total = one ///
                  sci_reliant_patent = cite_science_bin, ///
            by(year)

        gen double share = sci_reliant_patent / patent_total if patent_total > 0

        keep if inlist(year, 2010, 2022)

        count
        if r(N) == 0 {
            restore
            continue
        }

        local lab "`ttl_`s''"

        quietly forvalues i = 1/`=_N' {
            post P ("`lab'") (year[`i']) ///
                   (sci_reliant_patent[`i']) ///
                   (patent_total[`i']) ///
                   (share[`i'])
        }

    restore
}

postclose P

use `sectorstats', clear

********************************************************************************
* Encode sectors for symbol/color assignment
********************************************************************************

encode sector, gen(secid)
label var secid "Sector"

********************************************************************************
* Bubble size
********************************************************************************

gen double bubble_w = patent_total
replace bubble_w = 1 if missing(bubble_w) | bubble_w <= 0

********************************************************************************
* Build plotting layers
********************************************************************************

local symbols "circle square triangle diamond plus X circle_hollow square_hollow triangle_hollow diamond_hollow asterisk"
local colors  "blue red green orange purple teal brown navy maroon forest_green cranberry"

levelsof secid, local(secids)

local plots2010 ""
local plots2022 ""
local idx = 1

foreach j of local secids {

    local sym : word `idx' of `symbols'
    local col : word `idx' of `colors'

    local one2010 "(scatter share sci_reliant_patent [aw=bubble_w] if year == 2010 & secid == `j', msymbol(`sym') mcolor(`col'%55) mlcolor(`col') mlabel(sector) mlabcolor(black) mlabsize(medsmall) mlabposition(3) mlabgap(2))"

    local one2022 "(scatter share sci_reliant_patent [aw=bubble_w] if year == 2022 & secid == `j', msymbol(`sym') mcolor(`col'%55) mlcolor(`col') mlabel(sector) mlabcolor(black) mlabsize(medsmall) mlabposition(3) mlabgap(2))"

    if `idx' == 1 {
        local plots2010 `"`one2010'"'
        local plots2022 `"`one2022'"'
    }
    else {
        local plots2010 `"`plots2010' || `one2010'"'
        local plots2022 `"`plots2022' || `one2022'"'
    }

    local idx = `idx' + 1
}

********************************************************************************
* 2010 bubble plot
********************************************************************************

twoway `plots2010', ///
    title("{bf:Year 2010}", size(medium)) ///
    xtitle("{bf:Number of science-linked patents filed by Chinese firms}", size(medsmall)) ///
    ytitle("{bf:Share of science-linked patents filed by Chinese firms}", size(medium)) ///
    ylabel(0 0.1 "10%" 0.2 "20%" 0.3 "30%" 0.4 "40%" ///
           0.5 "50%" 0.6 "60%", labsize(medsmall)) ///
    xlabel(0(200)1600, angle(45) labsize(medsmall)) ///
    legend(off) ///
    graphregion(margin(medsmall)) ///
    plotregion(margin(medsmall)) ///
    xscale(extend)

graph save "${temp_output}bubble_2010_bysector.gph", replace

********************************************************************************
* 2022 bubble plot
********************************************************************************

twoway `plots2022', ///
    title("{bf:Year 2022}", size(medium)) ///
    xtitle("{bf:Number of science-linked patents filed by Chinese firms}", size(medsmall)) ///
    ytitle("{bf:Share of science-linked patents filed by Chinese firms}", size(medium)) ///
    ylabel(0 0.1 "10%" 0.2 "20%" 0.3 "30%" 0.4 "40%" ///
           0.5 "50%" 0.6 "60%", labsize(medsmall)) ///
    xlabel(0(5000)40000, angle(45) labsize(medsmall)) ///
    legend(off) ///
    graphregion(margin(medsmall)) ///
    plotregion(margin(medsmall)) ///
    xscale(extend)

graph save "${temp_output}bubble_2022_bysector.gph", replace

********************************************************************************
* Combine
********************************************************************************

graph combine ///
    "${temp_output}bubble_2010_bysector.gph" ///
    "${temp_output}bubble_2022_bysector.gph", ///
    cols(2) imargin(tiny) graphregion(margin(small))

gr_edit .plotregion1.graph1.plotregion1.plot6.style.editstyle label(position(2)) editcopy
gr_edit .plotregion1.graph1.plotregion1.plot7.style.editstyle label(position(4)) editcopy
gr_edit .plotregion1.graph1.plotregion1.plot4.style.editstyle label(position(2)) editcopy
gr_edit .plotregion1.graph1.plotregion1.plot11.style.editstyle label(position(2)) editcopy
gr_edit .plotregion1.graph2.plotregion1.plot1.style.editstyle label(position(12)) editcopy
gr_edit .plotregion1.graph2.plotregion1.plot10.style.editstyle label(position(2)) editcopy

graph save "${figure_output}bg_CNfirm_CNpat_bysector_bubble.gph", replace

********************************************************************************
* Clean temporary graph files
********************************************************************************

capture erase "${temp_output}bubble_2010_bysector.gph"
capture erase "${temp_output}bubble_2022_bysector.gph"