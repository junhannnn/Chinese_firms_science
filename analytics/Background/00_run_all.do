/*******************************************************************************
Project: Background figures
Script:  00_run_all.do

Purpose:
  Configure shared project paths and run the four background-figure scripts in
  a fixed order. The runner stops immediately if a child script returns an
  error, preventing later figures from being produced from an incomplete run.

Main inputs:
  - PCS_CNIPA.do and PCS_USPTO.do, with patent data under dataset/PCS and
    stata_output/CN_CN or stata_output/CN_US.
  - CNKI.do and WOS.do, with publication data under stata_output/CNKI and
    stata_output/WOS.

Main outputs:
  - figure_output/CN_CN/time_trend_CNfirm_CNIPA.gph
  - figure_output/CN_CN/time_trend_CNfirm_USPTO.gph
  - figure_output/CNKI/time_trend_CNfirm_CNKI.gph
  - figure_output/WOS/time_trend_CNfirm_WOS.gph

Run order:
  PCS_CNIPA.do, PCS_USPTO.do, CNKI.do, then WOS.do.

Notes:
  Run this file while Stata's current working directory is either the repository
  root or analytics/Background. It defines the path globals used by the child
  scripts and restores the analytics/Background folder between steps so relative
  paths continue to resolve.
*******************************************************************************/

* ==============================================================================
* 1. Configure the Stata session and locate the Background directory
* ==============================================================================

version 18.0
clear all
set more off
set linesize 255

capture confirm file "00_run_all.do"
if _rc {
    capture cd "./analytics/Background/"
    if _rc {
        di as error "ERROR: cannot locate the Background directory."
        di as error "Start this runner from the repository root or analytics/Background."
        exit 198
    }
}
display as text "Current directory: " c(pwd)
global RUNNER_DIR `"`c(pwd)'"'
display as text "Runner directory: " "$RUNNER_DIR"

display as text "=== Master run started: " c(current_date) " " c(current_time) " ==="

* ==============================================================================
* 2. Define an error-checked child-script runner
* ==============================================================================

capture program drop _run_step
program define _run_step
    syntax, FILE(string) STEP(string)

    display as text ""
    display as text "------------------------------------------------------------"
    display as text "Running Step `step': `file'"
    display as text "------------------------------------------------------------"

    * Child scripts may change the working directory; reset to runner folder first.
    capture cd "$RUNNER_DIR"

    capture noisily do "`file'"
    if _rc {
        display as error "ERROR in Step `step' (`file'). Return code = " _rc
        display as error "Pipeline stopped."
        exit _rc
    }
    else {
        * Restore runner folder so the next relative do-file path is resolvable.
        capture cd "$RUNNER_DIR"
        display as result "Step `step' completed successfully."
    }
end

* ==============================================================================
* 3. Run the background-figure scripts
* ==============================================================================

* Configure patent-data inputs and the shared CN_CN output directories.
global stata_output "../../stata_output/CN_CN/"
global figure_output "../../figure_output/CN_CN/"
global temp_output "../../temp_output/CN_CN/"
global PCS "../../dataset/PCS/"
global USpatents_stata "../../stata_output/CN_US/"
_run_step, step("PCS_CNIPA") file("PCS_CNIPA.do")
_run_step, step("PCS_USPTO") file("PCS_USPTO.do")

* Configure CNKI-specific input and output directories, then create its figure.
global stata_output "../../stata_output/CNKI/"
global figure_output "../../figure_output/CNKI/"
_run_step, step("CNKI") file("CNKI.do")

* Configure WOS-specific input and output directories, then create its figure.
global stata_output "../../stata_output/WOS/"
global figure_output "../../figure_output/WOS/"
_run_step, step("WOS") file("WOS.do")

display as result ""
display as result "=== Master run finished: " c(current_date) " " c(current_time) " ==="
