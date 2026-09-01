/*******************************************************************************
Project: WOS Pipeline - Master Runner
Script: 00_run_all.do

Purpose
  - Run the WOS Stata workflow in a fixed order with fail-fast handling.
  - Define shared global paths for WOS scripts.

Run Order (active calls in current file state)
  - 01_WOS_data_cleaning.do
  - 02_WOS_DID.do
  - 04_WOS_DID_listed.do
  - 05_WOS_dynamic_effect.do

*******************************************************************************/

version 18.0
clear all
set more off
set linesize 255

*----------------------------*
* 0. Working directory
*----------------------------*
capture cd ".\analytics\WOS\"
if _rc {
    capture cd "./analytics/WOS/"
    if _rc {
        di as error "ERROR: cannot cd to WOS project directory."
        exit 198
    }
}
display as text "Current directory: " c(pwd)

* Store root so each step can safely re-anchor cwd.
global WOS_ROOT "`c(pwd)'"

* ---- unified globals for WOS pipeline ----
* NOTE: keep `python_output` on WOS because 01/04 read Python outputs there.
global python_output "${WOS_ROOT}/../../proc_output/WOS/"
global stata_output  "${WOS_ROOT}/../../stata_output/WOS/"
global table_output  "${WOS_ROOT}/../../table_output/WOS/"
global temp_output   "${WOS_ROOT}/../../temp_output/WOS/"
global figure_output "${WOS_ROOT}/../../figure_output/WOS/"
global CN_CN         "${WOS_ROOT}/../../stata_output/CN_CN/"

* Non-fatal if directories already exist.
cap mkdir "${python_output}"
cap mkdir "${stata_output}"
cap mkdir "${table_output}"
cap mkdir "${temp_output}"
cap mkdir "${figure_output}"
cap mkdir "${CN_CN}"

display as text "=== WOS master run started: " c(current_date) " " c(current_time) " ==="

*----------------------------*
* Helper: run a do-file and stop if it errors
*----------------------------*
capture program drop _run_step
program define _run_step
    syntax, FILE(string) STEP(string)

    * Re-anchor cwd because child scripts may change directories.
    capture cd "${WOS_ROOT}"
    if _rc {
        display as error "ERROR: cannot return to project root: ${WOS_ROOT}"
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
* Run pipeline
*----------------------------*
_run_step, step("01") file("01_WOS_data_cleaning.do")
_run_step, step("02") file("02_WOS_DID.do")
_run_step, step("04") file("04_WOS_DID_listed.do")
_run_step, step("05") file("05_WOS_dynamic_effect.do")

display as result ""
display as result "=== WOS master run finished: " c(current_date) " " c(current_time) " ==="
