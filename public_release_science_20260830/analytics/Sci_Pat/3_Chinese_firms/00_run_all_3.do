/*******************************************************************************
Project: Chinese Firms - Master Runner (01-04)
Script: 00_run_all_3.do

Purpose
  - Run the Chinese-firms analysis pipeline with fail-fast error handling.
  - Set unified shared globals used by the `3_Chinese_firms` Stata scripts.

Run Order (current file state)
  - 3_Chinese_firms/01_DID_panel.do
  - 3_Chinese_firms/02_moderators.do
  - 3_Chinese_firms/03_knowledge_source.do
  - 3_Chinese_firms/04_vintage.do

Notes
  - Notebook step `3_Chinese_firms/05_plot_coef.ipynb` is not executed here.
*******************************************************************************/

version 18.0
clear all
set more off
set linesize 255

*----------------------------*
* 0. Working directory
*----------------------------*

capture cd ".\analytics\Sci_Pat\"
if _rc {
    capture cd "./analytics/Sci_Pat/"
    if _rc {
        di as error "ERROR: cannot cd to project directory."
        exit 198
    }
}
display as text "Current directory: " c(pwd)

* Store project root so shared paths remain stable even if child scripts change cwd.
global SCI_PAT_ROOT "`c(pwd)'"

* ---- unified globals (shared by 3_Chinese_firms do-files) ----

global stata_output "${SCI_PAT_ROOT}/../../stata_output/CN_CN/"
global figure_output "${SCI_PAT_ROOT}/../../figure_output/CN_CN/"
global table_output "${SCI_PAT_ROOT}/../../table_output/CN_CN/"
global temp_output "${SCI_PAT_ROOT}/../../temp_output/CN_CN/"

display as text "=== Master run started: " c(current_date) " " c(current_time) " ==="

*----------------------------*
* Helper: run a do-file and stop if it errors
*----------------------------*
capture program drop _run_step
program define _run_step
    syntax, FILE(string) STEP(string)

    * Re-anchor cwd because child scripts may change directories.
    capture cd "${SCI_PAT_ROOT}"
    if _rc {
        display as error "ERROR: cannot return to project root: ${SCI_PAT_ROOT}"
        exit 198
    }

    display as text ""
    display as text "------------------------------------------------------------"
    display as text "Running Step `step': `file'"
    display as text "------------------------------------------------------------"

    * fail fast if file is missing
    capture confirm file "`file'"
    if _rc {
        display as error "ERROR: cannot find do-file: `file'"
        exit 601
    }

    capture noisily do "`file'"
    if _rc {
        display as error "ERROR in Step `step' (`file'). Return code = " _rc
        display as error "Pipeline stopped."
        exit _rc
    }
    else {
        display as result "Step `step' completed successfully."
    }
end

*----------------------------*
* Run pipeline (01–04)
*----------------------------*
_run_step, step("01") file("3_Chinese_firms/01_DID_panel.do")
_run_step, step("02") file("3_Chinese_firms/02_moderators.do")
_run_step, step("03") file("3_Chinese_firms/03_knowledge_source.do")
_run_step, step("04") file("3_Chinese_firms/04_vintage.do")

display as result ""
display as result "=== Master run finished: " c(current_date) " " c(current_time) " ==="
