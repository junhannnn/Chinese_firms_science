


********************************************************************************
************************* 1. Change treatment Unit *****************************
********************************************************************************

use ${stata_output}DID_allfirm-level.dta, clear

reghdfe f_cite_science_num_w did whether_pat, absorb(firm_id year) vce(r)
est store OLS_sci
reghdfe ln_f_cite_science_num did whether_pat, absorb(firm_id year) vce(r)
est store LnOLS_sci

didplacebo OLS_sci, treatvar(did) pbounit rep(500) seed(1)
graph save ${figure_output}placebo_sci_OLS1.gph, replace

didplacebo LnOLS_sci, treatvar(did) pbounit rep(500) seed(1)
graph save ${figure_output}placebo_sci_LnOLS1.gph, replace


********************************** combine *************************************

graph combine ${figure_output}placebo_sci_OLS1.gph ${figure_output}placebo_sci_LnOLS1.gph, row(1) imargin(zero) ///
title("In-space Placebo Test", size(*0.8))

gr_edit .plotregion1.graph1.title.style.editstyle size(medium) editcopy
gr_edit .plotregion1.graph1.title.text = {}
gr_edit .plotregion1.graph1.title.text.Arrpush (A) DV: # of science-reliant patents

gr_edit .plotregion1.graph2.title.style.editstyle size(medium) editcopy
gr_edit .plotregion1.graph2.title.text = {}
gr_edit .plotregion1.graph2.title.text.Arrpush (B) DV: ln (# of science-reliant patents+1)

gr_edit .plotregion1.graph1.xaxis1.reset_rule -1.2 1.2 0.4 , tickset(major) ruletype(range)
gr_edit .plotregion1.graph2.xaxis1.reset_rule -1.2 1.2 0.4 , tickset(major) ruletype(range)

graph save ${figure_output}placebo_unit.gph, replace

erase ${figure_output}placebo_sci_OLS1.gph
erase ${figure_output}placebo_sci_LnOLS1.gph



********************************************************************************
************** 2. Change both treatment Time and Unit (unrestricted) ***********
********************************************************************************

didplacebo OLS_sci, treatvar(did) pbomix(2)
graph save ${figure_output}placebo_sci_OLS2.gph, replace

didplacebo LnOLS_sci, treatvar(did) pbomix(2)
graph save ${figure_output}placebo_sci_LnOLS2.gph, replace


********************************** combine *************************************

graph combine ${figure_output}placebo_sci_OLS2.gph ${figure_output}placebo_sci_LnOLS2.gph, row(1) imargin(zero) ///
title("Unrestricted Mixed Placebo Test for Staggered DID", size(*0.8))

gr_edit .plotregion1.graph1.title.style.editstyle size(medium) editcopy
gr_edit .plotregion1.graph1.title.text = {}
gr_edit .plotregion1.graph1.title.text.Arrpush (A) DV: # of science-reliant patents

gr_edit .plotregion1.graph2.title.style.editstyle size(medium) editcopy
gr_edit .plotregion1.graph2.title.text = {}
gr_edit .plotregion1.graph2.title.text.Arrpush (B) DV: ln (# of science-reliant patents+1)

gr_edit .plotregion1.graph1.xaxis1.reset_rule -1.2 1.2 0.4 , tickset(major) ruletype(range)
gr_edit .plotregion1.graph2.xaxis1.reset_rule -1.2 1.2 0.4 , tickset(major) ruletype(range)

graph save ${figure_output}placebo_mixed1.gph, replace


erase ${figure_output}placebo_sci_OLS2.gph
erase ${figure_output}placebo_sci_LnOLS2.gph



********************************************************************************
************** 3. Change both treatment Time and Unit (unrestricted) ***********
********************************************************************************

didplacebo OLS_sci, treatvar(did) pbomix(3) rantimescope(2017 2022)
graph save ${figure_output}placebo_sci_OLS3.gph, replace

didplacebo LnOLS_sci, treatvar(did) pbomix(3) rantimescope(2017 2022)
graph save ${figure_output}placebo_sci_LnOLS3.gph, replace


********************************** combine *************************************

graph combine ${figure_output}placebo_sci_OLS3.gph ${figure_output}placebo_sci_LnOLS3.gph, row(1) imargin(zero) ///
title("Restricted Mixed Placebo Test for Staggered DID", size(*0.8))

gr_edit .plotregion1.graph1.title.style.editstyle size(medium) editcopy
gr_edit .plotregion1.graph1.title.text = {}
gr_edit .plotregion1.graph1.title.text.Arrpush (A) DV: # of science-reliant patents

gr_edit .plotregion1.graph2.title.style.editstyle size(medium) editcopy
gr_edit .plotregion1.graph2.title.text = {}
gr_edit .plotregion1.graph2.title.text.Arrpush (B) DV: ln (# of science-reliant patents+1)

gr_edit .plotregion1.graph1.xaxis1.reset_rule -1.2 1.2 0.4 , tickset(major) ruletype(range)
gr_edit .plotregion1.graph2.xaxis1.reset_rule -1.2 1.2 0.4 , tickset(major) ruletype(range)

graph save ${figure_output}placebo_mixed2.gph, replace


erase ${figure_output}placebo_sci_OLS3.gph
erase ${figure_output}placebo_sci_LnOLS3.gph
