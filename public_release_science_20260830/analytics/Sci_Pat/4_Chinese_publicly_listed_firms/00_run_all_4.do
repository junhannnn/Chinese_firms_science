/*******************************************************************************
Project: Chinese Publicly Listed Firms — Master Runner (01–05)
Script: 00_run_all_4.do

Purpose
  - Run the listed-firm analysis Stata pipeline with fail-fast error handling.
  - Set a unified project working directory and shared output globals.

Run Order (current file state)
  - 01_main_effect.do
  - 02_moderators.do
  - 03_dynamic_effect_main.do
  - 04_dynamic_effect_mo.do
  - 05_gov_subsidy.do

Notes
  - This runner assumes upstream datasets (for example
    `DID_listedfirm-level.dta`) have already been generated.
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

* ---- unified globals (shared by listed-firm scripts) ----

global stata_output "${SCI_PAT_ROOT}/../../stata_output/CN_CN/"
global figure_output "${SCI_PAT_ROOT}/../../figure_output/CN_CN/"
global table_output "${SCI_PAT_ROOT}/../../table_output/CN_CN/"
global temp_output "${SCI_PAT_ROOT}/../../temp_output/CN_CN/"
global CN_patents "${SCI_PAT_ROOT}/../../dataset/CN_patents/"


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
* Run pipeline (01–05)
*----------------------------*
_run_step, step("01") file("4_Chinese_publicly_listed_firms/01_main_effect.do")
_run_step, step("02") file("4_Chinese_publicly_listed_firms/02_moderators.do")
_run_step, step("03") file("4_Chinese_publicly_listed_firms/03_dynamic_effect_main.do")
_run_step, step("04") file("4_Chinese_publicly_listed_firms/04_dynamic_effect_mo.do")
_run_step, step("05") file("4_Chinese_publicly_listed_firms/05_gov_subsidy.do")

display as result ""
display as result "=== Master run finished: " c(current_date) " " c(current_time) " ==="
