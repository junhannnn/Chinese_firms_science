
**************************************************
* 1. All firms
**************************************************
use ${stata_output}DID_allfirm-level.dta, clear
drop if dif_year!=. & !inrange(dif_year, -3, 3)

eventdd f_cite_science_num_w whether_pat, timevar(dif_year) ///
    method(hdfe, absorb(firm_id year)) ///
    baseline(0) vce(r) level(95) ///
    graph_op(ytitle("# of Chinese science-reliant patents") ///
             xtitle("Sanction Year") ///
			 title("(A) Chinese firms (full sample)", size(medium)) ///
             xscale(range(-3 3)) ///
             legend(off) ///
             graphregion(color(white)) ///
             bgcolor(white) ///
             scheme(journal))

matrix b_A = e(b)[1,2..7]
matrix V_A = e(V)[2..7,2..7]
matrix list b_A
matrix list V_A

pretrends power 0.8, b(b_A) v(V_A) pre(1/3) post(4/6)
local slope80 = r(slope)
pretrends, b(b_A) v(V_A) ///
	time(-3 -2 -1 0 1 2 3) ref(0) ///
	slope(`slope80') ///
    title("{bf: Roth pre-trends diagnostic: All firms (full sample)}", size(medsmall)) ///
    legend(position(5) ring(0) cols(1) size(small)) ///
    ytitle("Coefficient") ///
    xtitle("Sanction Year")
gr_edit .xaxis1.reset_rule -3 3 1 , tickset(major) ruletype(range) 
graph save ${figure_output}pretrends_1.gph, replace

matrix l_vec = (1/3 \ 1/3 \ 1/3)
honestdid, b(b_A) vcov(V_A) numpre(3) l_vec(l_vec) mvec(0(0.1)0.5)

local plotopts ///
    xtitle("Mbar") ///
    ytitle("95% robust""confidence interval") ///
    title("{bf: HonestDiD sensitivity: All firms (full sample)}", size(medsmall)) ///
    yline(0, lpattern(dash)) ///
	ylabel(-0.1(0.2)0.9) ///
    legend(off)
honestdid, cached coefplot `plotopts'

graph save ${figure_output}honestdid_1.gph, replace

**************************************************
* 2. Publicly listed firms
**************************************************
use ${stata_output}DID_listedfirm-level.dta, clear
drop if dif_year!=. & !inrange(dif_year, -3, 3)

eventdd f_cite_science_num_w whether_pat, timevar(dif_year) ///
    method(hdfe, absorb(ListedCoID year)) ///
    baseline(0) vce(r) level(95) ///
    graph_op(ytitle("# of Chinese science-reliant patents") ///
             xtitle("Sanction Year") ///
			 title("(C) Chinese listed firms (full sample)", size(medium)) ///
             xscale(range(-3 3)) ///
             legend(off) ///
             graphregion(color(white)) ///
             bgcolor(white) ///
             scheme(journal))

matrix b_C = e(b)[1,2..7]
matrix V_C = e(V)[2..7,2..7]
matrix list b_C
matrix list V_C

pretrends power 0.8, b(b_C) v(V_C) pre(1/3) post(4/6)
local slope80 = r(slope)
pretrends, b(b_C) v(V_C) ///
	time(-3 -2 -1 0 1 2 3) ref(0) ///
	slope(`slope80') ///
    title("{bf: Roth pre-trends diagnostic: Publicly listed firms (full sample)}", size(medsmall)) ///
    legend(position(11) ring(0) cols(1) size(small)) ///
    ytitle("Coefficient") ///
    xtitle("Sanction Year")
gr_edit .xaxis1.reset_rule -3 3 1 , tickset(major) ruletype(range) 
graph save ${figure_output}pretrends_2.gph, replace

matrix l_vec = (1/3 \ 1/3 \ 1/3)
honestdid, b(b_C) vcov(V_C) numpre(3) l_vec(l_vec) mvec(0(0.1)0.5)

local plotopts ///
    xtitle("Mbar") ///
    ytitle("95% robust""confidence interval") ///
    title("{bf: HonestDiD sensitivity: Publicly listed firms (full sample)}", size(medsmall)) ///
    yline(0, lpattern(dash)) ///
	ylabel(-1(2)6) ///
    legend(off)
honestdid, cached coefplot `plotopts'

graph save ${figure_output}honestdid_2.gph, replace




graph combine ${figure_output}pretrends_1.gph ${figure_output}pretrends_2.gph ${figure_output}honestdid_1.gph ${figure_output}honestdid_2.gph
graph save ${figure_output}pretrend_test_full.gph, replace

erase ${figure_output}pretrends_1.gph
erase ${figure_output}pretrends_2.gph
erase ${figure_output}honestdid_1.gph
erase ${figure_output}honestdid_2.gph
