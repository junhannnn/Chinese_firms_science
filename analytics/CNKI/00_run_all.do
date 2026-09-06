/*******************************************************************************
Project: CNKI analysis
Script:  00_run_all.do

Purpose:
  Configure shared paths and run the three CNKI analysis scripts in a fixed
  order. The runner stops immediately if a child script is missing or returns
  an error.

Main inputs:
  - 01_CNKI_DID.do
  - 02_public_listed_firms.do
  - 03_CNKI_dynamic_effect.do
  - The datasets documented in each child script

Main outputs:
  - ${table_output}CNKI_summary_stats.doc
  - ${table_output}CNKI_main.rtf and ${table_output}CNKI_listedfirm.rtf
  - ${stata_output}CNKI_event_table.dta
  - ${figure_output}CNKI_dynamic.gph

Run order:
  01_CNKI_DID.do, 02_public_listed_firms.do, then 03_CNKI_dynamic_effect.do.

Notes:
  Run this file while Stata's current working directory is either the repository
  root or analytics/CNKI. The path globals defined here are used by all three
  child scripts.
*******************************************************************************/

* ==============================================================================
* 1. Configure the Stata session and locate the CNKI directory
* ==============================================================================

version 18.0
clear all
set more off
set linesize 255

capture confirm file "01_CNKI_DID.do"
if _rc {
    capture cd "./analytics/CNKI/"
    if _rc {
        di as error "ERROR: cannot locate the CNKI directory."
        di as error "Start this runner from the repository root or analytics/CNKI."
        exit 198
    }
}
display as text "Current directory: " c(pwd)

* Store the CNKI script directory so relative paths remain stable across steps.
global CNKI_ROOT "`c(pwd)'"

* Define shared data, table, figure, and temporary-output directories.
global python_output "${CNKI_ROOT}/../../proc_output/CNKI/"
global stata_output "${CNKI_ROOT}/../../stata_output/CNKI/"
global table_output "${CNKI_ROOT}/../../table_output/CNKI/"
global figure_output "${CNKI_ROOT}/../../figure_output/CNKI/"
global temp_output "${CNKI_ROOT}/../../temp_output/CNKI/"
global CN_CN "${CNKI_ROOT}/../../stata_output/CN_CN/"

display as text "=== CNKI master run started: " c(current_date) " " c(current_time) " ==="

* ==============================================================================
* 2. Define an error-checked child-script runner
* ==============================================================================

capture program drop _run_step
program define _run_step
    syntax, FILE(string) STEP(string)

    * Re-anchor cwd because child scripts may change directories.
    capture cd "${CNKI_ROOT}"
    if _rc {
        display as error "ERROR: cannot return to project root: ${CNKI_ROOT}"
        exit 198
    }

    display as text ""
    display as text "------------------------------------------------------------"
    display as text "Running Step `step': `file'"
    display as text "------------------------------------------------------------"

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

* ==============================================================================
* 3. Run the CNKI analysis pipeline
* ==============================================================================

_run_step, step("01") file("01_CNKI_DID.do")
_run_step, step("02") file("02_public_listed_firms.do")
_run_step, step("03") file("03_CNKI_dynamic_effect.do")

display as result ""
display as result "=== CNKI master run finished: " c(current_date) " " c(current_time) " ==="
