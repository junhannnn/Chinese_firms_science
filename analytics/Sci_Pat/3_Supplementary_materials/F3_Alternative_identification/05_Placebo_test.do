/*******************************************************************************
Project: Science-linked patents—supplementary alternative identification
Script:  5_Placebo_test.do

Purpose:
  Evaluate the staggered-DID results using treatment-unit placebos and mixed
  treatment-unit/timing placebos. Apply each test to the level and log-transformed
  science-reliant patent outcomes and combine the paired diagnostic graphs.

Main input (from ${stata_output}):
  - DID_allfirm-level.dta

Main outputs (under ${figure_output}):
  - placebo_unit.gph: treatment-unit placebo results
  - placebo_mixed1.gph: unrestricted mixed-placebo results
  - placebo_mixed2.gph: restricted mixed-placebo results

Notes:
  Run through 3_Supplementary_materials/00_run_all.do so the shared path globals
  are available. Temporary outcome-specific graph files are deleted after each
  pair is combined.
*******************************************************************************/

* ==============================================================================
* 1. Estimate and store the baseline DID models
* ==============================================================================

use ${stata_output}DID_allfirm-level.dta, clear

reghdfe f_cite_science_num_w did whether_pat, absorb(firm_id year) vce(r)
est store OLS_sci
reghdfe ln_f_cite_science_num did whether_pat, absorb(firm_id year) vce(r)
est store LnOLS_sci

* ==============================================================================
* 2. Run treatment-unit placebo tests and combine the results
* ==============================================================================

didplacebo OLS_sci, treatvar(did) pbounit rep(500) seed(1)
graph save ${figure_output}placebo_sci_OLS1.gph, replace

didplacebo LnOLS_sci, treatvar(did) pbounit rep(500) seed(1)
graph save ${figure_output}placebo_sci_LnOLS1.gph, replace
* Combine the level and log-outcome placebo graphs.
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
* ==============================================================================
* 3. Run unrestricted treatment-unit and timing placebo tests
* ==============================================================================

didplacebo OLS_sci, treatvar(did) pbomix(2)
graph save ${figure_output}placebo_sci_OLS2.gph, replace

didplacebo LnOLS_sci, treatvar(did) pbomix(2)
graph save ${figure_output}placebo_sci_LnOLS2.gph, replace
* Combine the level and log-outcome placebo graphs.
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
* ==============================================================================
* 4. Run restricted treatment-unit and timing placebo tests
* ==============================================================================

didplacebo OLS_sci, treatvar(did) pbomix(3) rantimescope(2017 2022)
graph save ${figure_output}placebo_sci_OLS3.gph, replace

didplacebo LnOLS_sci, treatvar(did) pbomix(3) rantimescope(2017 2022)
graph save ${figure_output}placebo_sci_LnOLS3.gph, replace
* Combine the level and log-outcome placebo graphs.
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
