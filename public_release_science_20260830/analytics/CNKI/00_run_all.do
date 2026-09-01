/*******************************************************************************
Project: CNKI Analysis - Master Runner (01-03)
Script: 00_run_all.do

Purpose
  - Run the CNKI Stata pipeline with fail-fast error handling.
  - Set a unified project working directory and shared output globals.

Run Order (current file state)
  - CNKI/01_CNKI_DID.do
  - CNKI/02_public_listed_firms.do
  - CNKI/03_CNKI_dynamic_effect.do

*******************************************************************************/

version 18.0
clear all
set more off
set linesize 255

*----------------------------*
* 0. Working directory
*----------------------------*
capture cd ".\analytics\CNKI\"
if _rc {
    capture cd "./analytics/CNKI/"
    if _rc {
        di as error "ERROR: cannot cd to CNKI project directory."
        exit 198
    }
}
display as text "Current directory: " c(pwd)

* Store project root so shared paths remain stable even if child scripts change cwd.
global CNKI_ROOT "`c(pwd)'"

* ---- unified globals (shared by CNKI do-files) ----
global python_output "${CNKI_ROOT}/../../proc_output/CNKI/"
global stata_output "${CNKI_ROOT}/../../stata_output/CNKI/"
global table_output "${CNKI_ROOT}/../../table_output/CNKI/"
global figure_output "${CNKI_ROOT}/../../figure_output/CNKI/"
global temp_output "${CNKI_ROOT}/../../temp_output/CNKI/"
global CN_CN "${CNKI_ROOT}/../../stata_output/CN_CN/"

display as text "=== CNKI master run started: " c(current_date) " " c(current_time) " ==="

*----------------------------*
* Helper: run a do-file and stop if it errors
*----------------------------*
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

*----------------------------*
* Run pipeline (01-03)
*----------------------------*
_run_step, step("01") file("01_CNKI_DID.do")
_run_step, step("02") file("02_public_listed_firms.do")
_run_step, step("03") file("03_CNKI_dynamic_effect.do")

display as result ""
display as result "=== CNKI master run finished: " c(current_date) " " c(current_time) " ==="
