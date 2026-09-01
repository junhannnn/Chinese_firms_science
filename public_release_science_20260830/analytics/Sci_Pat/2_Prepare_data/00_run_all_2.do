/*******************************************************************************
Project: EL Firms — Master Runner (01–07)
Script: 00_run_all_2.do

Purpose
  - Run the prepare-data Stata pipeline with fail-fast error handling.
  - Set a unified project working directory and shared output globals.
  - Execute the active prepare-data steps currently listed in the pipeline section.

Run Order (active calls in current file state)
  - 01_descriptive_statistics_el_firms.do
  - 02_build_firm_controls_all_firms.do
  - 04_prepare_inputs.do
  - 06_build_firm_year_panel.do
  - 07_CSMAR_control_var.do
  - 08_build_listedfirm_year_panel.do
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

* ---- unified globals (shared by pipeline steps in this runner) ----

global python_output "${SCI_PAT_ROOT}/../../proc_output/CN_CN/"
global stata_output "${SCI_PAT_ROOT}/../../stata_output/CN_CN/"
global figure_output "${SCI_PAT_ROOT}/../../figure_output/CN_CN/"
global table_output  "${SCI_PAT_ROOT}/../../table_output/CN_CN/"
global temp_output "${SCI_PAT_ROOT}/../../temp_output/CN_CN/"

global raw_data "${SCI_PAT_ROOT}/../../dataset/"
global CN_patents "${SCI_PAT_ROOT}/../../dataset/CN_patents/1985-2025/"
global CN_US "${SCI_PAT_ROOT}/../../stata_output/CN_US/"
global other_data "${SCI_PAT_ROOT}/../../dataset/Miscellaneous/"
global CSMAR "${SCI_PAT_ROOT}/../../dataset/CSMAR/"
global CN_patents_simi "${SCI_PAT_ROOT}/../../dataset/CN_patents/"

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
* Run pipeline (01–08)
*----------------------------*
_run_step, step("01") file("2_Prepare_data/01_descriptive_statistics_el_firms.do")
_run_step, step("02") file("2_Prepare_data/02_build_firm_controls_all_firms.do")
_run_step, step("04") file("2_Prepare_data/04_prepare_inputs.do")
_run_step, step("06") file("2_Prepare_data/06_build_firm_year_panel.do")
_run_step, step("07") file("2_Prepare_data/07_CSMAR_control_var.do")
_run_step, step("08") file("2_Prepare_data/08_build_listedfirm_year_panel.do")

display as result ""
display as result "=== Master run finished: " c(current_date) " " c(current_time) " ==="
