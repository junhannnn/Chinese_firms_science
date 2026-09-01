

********************************************************************************
*************************** CN patents filed by CN firms ***********************
********************************************************************************


use "${stata_output}Chinese_patents_filed_by_EL_otherfirms.dta", clear

* merge with ipc
merge 1:1 apn using "${stata_output}CNpatents_mainipc.dta"
drop if _merge==2
drop _merge

gen industry_section = substr(ipc_subclass, 1, 1)
encode industry_section, gen(industry_section_id)


foreach l in A B C D E F G H {
    gen is_`l' = 0
    replace is_`l' = 1 if industry_section == "`l'"
}

egen n_sectors = rowtotal(is_A is_B is_C is_D is_E is_F is_G is_H)
gen byte is_all = (n_sectors>0)


********************************************************************************
* Title mapping (independent of variable existence later)
********************************************************************************
local ttl_all  "All fields"

local ttl_A    "Field A"
local ttl_B    "Field B"
local ttl_C    "Field C"
local ttl_D    "Field D"
local ttl_E    "Field E"
local ttl_F    "Field F"
local ttl_G    "Field G"
local ttl_H    "Field H"


********************************************************************************
* 12 graphs: 11 subfields + ALL
********************************************************************************
local sectors "all A B C D E F G H"

foreach s of local sectors {

    preserve

    * keep sector / ALL observations
    keep if is_`s'==1

    * take title before we drop anything (via mapping locals)
    local ttl "`ttl_`s''"

    * rename for plotting
    rename grtyr year

    *--------------------------------------------------------
    * Yearly aggregates
    *--------------------------------------------------------
    bys year: gen patent_grtyr = _N
    bys year: egen sci_reliant_patent_grtyr = total(cite_science)

    * Unique firms per year (robust)
    bys year fapp_standard: gen byte firm1 = (_n==1)
    bys year: egen unique_firm_yr = total(firm1)
    drop firm1

    * Unique firms with >=1 science-reliant patent per year (robust)
    bys year fapp_standard: egen has_citesci = max(cite_science)
    bys year fapp_standard: gen byte citesci_firm1 = (_n==1 & has_citesci==1)
    bys year: egen unique_citesci_firm_yr = total(citesci_firm1)
    drop citesci_firm1

    * Keep only year-level series
    keep year sci_reliant_patent_grtyr unique_firm_yr unique_citesci_firm_yr patent_grtyr
    duplicates drop

    * Derived metrics
    gen sci_reliant_ratio_grtyr = sci_reliant_patent_grtyr / patent_grtyr
    gen sci_reliant_patent_grtyr_adj1 = sci_reliant_patent_grtyr / unique_firm_yr
    gen sci_reliant_patent_grtyr_adj2 = sci_reliant_patent_grtyr / unique_citesci_firm_yr

    * Sample window
    keep if year>=2010 & year<=2022

    *--------------------------------------------------------
    * Endpoint indicators + labels
    *--------------------------------------------------------
    gen byte ep2010 = (year==2010)
    gen byte ep2022 = (year==2022)

    gen str num_label = string(sci_reliant_patent_grtyr, "%9.0fc")
    gen str pct_label = string(sci_reliant_ratio_grtyr*100, "%9.2f") + "%"

    gen double year_lbl_1 = year
    replace year_lbl_1 = year + 0.50 if year==2010
    replace year_lbl_1 = year - 0.50 if year==2022

    gen double year_lbl_2 = year
    replace year_lbl_2 = year + 0.20 if year==2010
    replace year_lbl_2 = year - 0.20 if year==2022

    *--------------------------------------------------------
    * Plot
    *--------------------------------------------------------
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
        ylabel(0(10000)40000, axis(1) labsize(small) format(%9.0f)) ///
        ylabel(0 0.1 "10%" 0.2 "20%" 0.3 "30%" 0.4 "40%" 0.5 "50%" 0.6 "60%", ///
               axis(2) labsize(small)) ///
        xtitle("Year", size(small) placement(east)) ///
        xlabel(2010(2)2022, angle(45) labsize(small)) ///
        legend(off) ///
        graphregion(margin(vsmall))

    * Save each figure
    graph save "${temp_output}bg_CNfirm_CNpat_`s'.gph", replace

    restore
}

graph combine ///
	"${temp_output}bg_CNfirm_CNpat_all.gph" ///
    "${temp_output}bg_CNfirm_CNpat_A.gph" ///
    "${temp_output}bg_CNfirm_CNpat_B.gph" ///
    "${temp_output}bg_CNfirm_CNpat_C.gph" ///
    "${temp_output}bg_CNfirm_CNpat_D.gph" ///
    "${temp_output}bg_CNfirm_CNpat_E.gph" ///
    "${temp_output}bg_CNfirm_CNpat_F.gph" ///
    "${temp_output}bg_CNfirm_CNpat_G.gph" ///
    "${temp_output}bg_CNfirm_CNpat_H.gph", ///
    rows(3) cols(3) ///
    imargin(tiny) ///
    graphregion(margin(small))

gr_edit .plotregion1.graph1.yaxis1.reset_rule 0 100000 20000 , tickset(major) ruletype(range) 


graph save ${figure_output}bg_CNfirm_CNpat_bysectionsector.gph, replace


local flist : dir "${temp_output}" files "bg_CNfirm_CNpat_*.gph"
foreach f of local flist {
    erase "${temp_output}`f'"
}



********************************************************************************
* Bubble plots (2010 vs 2022): 11 sectors as points
********************************************************************************

* 防止 postfile 句柄残留
capture postclose P

* Make sure year variable exists
capture confirm variable year
if _rc rename grtyr year

local sectors "A B C D E F G H"

tempfile sectorstats
postfile P str40 sector int year double sci_reliant_patent ///
          double patent_total double share using `sectorstats', replace
		  
		  
foreach s of local sectors {

    preserve
        keep if is_`s'==1

        * yearly totals within this sector (robust even if apn is string)
        gen byte one = 1
        collapse (sum) patent_total=one (sum) sci_reliant_patent=cite_science, by(year)

        gen double share = sci_reliant_patent / patent_total
        keep if inlist(year,2010,2022)

        local lab "`ttl_`s''"

        quietly forvalues i=1/`=_N' {
            post P ("`lab'") (year[`i']) (sci_reliant_patent[`i']) (patent_total[`i']) (share[`i'])
        }
    restore
}

postclose P
use `sectorstats', clear


* 让 mlabel 一定能显示：把 string sector encode 成数值 + value label
encode sector, gen(secid)
label var secid "Sector"



* 2010
twoway ///
 (scatter share sci_reliant_patent if year==2010 & secid==1,  msymbol(circle)    mcolor(blue%55)   mlcolor(blue)   msize(bubble_size) mlabel(secid) mlabcolor(black) mlabsize(small) mlabposition(3) mlabgap(2)) || ///
 (scatter share sci_reliant_patent if year==2010 & secid==2,  msymbol(square)    mcolor(red%55)    mlcolor(red)    msize(bubble_size) mlabel(secid) mlabcolor(black) mlabsize(small) mlabposition(4) mlabgap(2)) || ///
 (scatter share sci_reliant_patent if year==2010 & secid==3,  msymbol(triangle)  mcolor(green%55)  mlcolor(green)  msize(bubble_size) mlabel(secid) mlabcolor(black) mlabsize(small) mlabposition(3) mlabgap(2)) || ///
 (scatter share sci_reliant_patent if year==2010 & secid==4,  msymbol(diamond)   mcolor(orange%55) mlcolor(orange) msize(bubble_size) mlabel(secid) mlabcolor(black) mlabsize(small) mlabposition(3) mlabgap(2)) || ///
 (scatter share sci_reliant_patent if year==2010 & secid==5,  msymbol(plus)      mcolor(purple%55) mlcolor(purple) msize(bubble_size) mlabel(secid) mlabcolor(black) mlabsize(small) mlabposition(3) mlabgap(2)) || ///
 (scatter share sci_reliant_patent if year==2010 & secid==6,  msymbol(X)         mcolor(teal%55)   mlcolor(teal)   msize(bubble_size) mlabel(secid) mlabcolor(black) mlabsize(small) mlabposition(3) mlabgap(2)) || ///
 (scatter share sci_reliant_patent if year==2010 & secid==7,  msymbol(circle_hollow)  mcolor(brown%55)  mlcolor(brown)  msize(bubble_size) mlabel(secid) mlabcolor(black) mlabsize(small) mlabposition(3) mlabgap(2)) || ///
 (scatter share sci_reliant_patent if year==2010 & secid==8,  msymbol(square_hollow)  mcolor(navy%55)   mlcolor(navy)   msize(bubble_size) mlabel(secid) mlabcolor(black) mlabsize(small) mlabposition(3) mlabgap(2)), ///
 title("{bf: Year 2010}", size(medium)) ///
 xtitle("{bf:Number of science-linked patents filed by Chinese firms}", size(medsmall)) ///
 ytitle("{bf:Share of science-linked patents filed by Chinese firms}", size(medium)) ///
 ylabel(0 0.1 "10%" 0.2 "20%" 0.3 "30%" 0.4 "40%" 0.5 "50%" 0.6 "60%", labsize(medsmall)) ///
 xlabel(0(200)1600, angle(45) labsize(medsmall)) ///
 legend(off) ///
 graphregion(margin(medsmall)) ///
 plotregion(margin(medsmall)) ///
 xscale(extend)

graph save "${temp_output}bubble_2010_bysector.gph", replace

* 2022
twoway ///
 (scatter share sci_reliant_patent if year==2022 & secid==1,  msymbol(circle)    mcolor(blue%55)   mlcolor(blue)   msize(bubble_size) mlabel(secid) mlabcolor(black) mlabsize(small) mlabposition(3) mlabgap(2)) || ///
 (scatter share sci_reliant_patent if year==2022 & secid==2,  msymbol(square)    mcolor(red%55)    mlcolor(red)    msize(bubble_size) mlabel(secid) mlabcolor(black) mlabsize(small) mlabposition(3) mlabgap(2)) || ///
 (scatter share sci_reliant_patent if year==2022 & secid==3,  msymbol(triangle)  mcolor(green%55)  mlcolor(green)  msize(bubble_size) mlabel(secid) mlabcolor(black) mlabsize(small) mlabposition(4) mlabgap(2)) || ///
 (scatter share sci_reliant_patent if year==2022 & secid==4,  msymbol(diamond)   mcolor(orange%55) mlcolor(orange) msize(bubble_size) mlabel(secid) mlabcolor(black) mlabsize(small) mlabposition(3) mlabgap(2)) || ///
 (scatter share sci_reliant_patent if year==2022 & secid==5,  msymbol(plus)      mcolor(purple%55) mlcolor(purple) msize(bubble_size) mlabel(secid) mlabcolor(black) mlabsize(small) mlabposition(3) mlabgap(2)) || ///
 (scatter share sci_reliant_patent if year==2022 & secid==6,  msymbol(X)         mcolor(teal%55)   mlcolor(teal)   msize(bubble_size) mlabel(secid) mlabcolor(black) mlabsize(small) mlabposition(3) mlabgap(2)) || ///
 (scatter share sci_reliant_patent if year==2022 & secid==7,  msymbol(circle_hollow)  mcolor(brown%55)  mlcolor(brown)  msize(bubble_size) mlabel(secid) mlabcolor(black) mlabsize(small) mlabposition(3) mlabgap(2)) || ///
 (scatter share sci_reliant_patent if year==2022 & secid==8,  msymbol(square_hollow)  mcolor(navy%55)   mlcolor(navy)   msize(bubble_size) mlabel(secid) mlabcolor(black) mlabsize(small) mlabposition(3) mlabgap(2)), ///
 title("{bf: Year 2022}", size(medium)) ///
 xtitle("{bf:Number of science-linked patents filed by Chinese firms}", size(medsmall)) ///
 ytitle("{bf:Share of science-linked patents filed by Chinese firms}", size(medium)) ///
 ylabel(0 0.1 "10%" 0.2 "20%" 0.3 "30%" 0.4 "40%" 0.5 "50%" 0.6 "60%", labsize(medsmall)) ///
 xlabel(0(5000)40000, angle(45) labsize(medsmall)) ///
 legend(off) ///
 graphregion(margin(medsmall)) ///
 plotregion(margin(medsmall)) ///
 xscale(extend)

graph save "${temp_output}bubble_2022_bysector.gph", replace


* Combine
graph combine ///
    "${temp_output}bubble_2010_bysector.gph" ///
    "${temp_output}bubble_2022_bysector.gph", ///
    cols(2) imargin(tiny) graphregion(margin(small))

gr_edit .plotregion1.graph1.xaxis1.reset_rule 0 10000 2000 , tickset(major) ruletype(range) 
gr_edit .plotregion1.graph2.xaxis1.reset_rule 0 50000 10000 , tickset(major) ruletype(range) 

graph save ${figure_output}bg_CNfirm_CNpat_bysectionsector_bubble.gph, replace


erase ${temp_output}bubble_2010_bysector.gph
erase ${temp_output}bubble_2022_bysector.gph

