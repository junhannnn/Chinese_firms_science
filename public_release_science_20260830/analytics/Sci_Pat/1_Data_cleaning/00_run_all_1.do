
/*******************************************************************************
Project: CN Patents
Script: 00_run_all_1.do

Purpose
  - Run the full Stata pipeline end-to-end in a fixed order.
  - Stop immediately if any step errors.

Run Order
  - 01_build_cn_patents_database.do
  - 02_construct_cn_patents_variables.do
  - 03_link_cn_patents_to_ros.do
  - 04_build_analysis_sample.do
  - 05_identify_cn_patents_by_el.do
  - 06_flag_cn_patents_by_el.do

Notes
  - This runner also defines shared global paths used by downstream scripts.
*******************************************************************************/

version 18.0
clear all
set more off
set linesize 255

*----------------------------*
* 0. Working directory + unified paths
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

* ---- unified globals (shared by 01-06) ----
global python_output   "${SCI_PAT_ROOT}/../../proc_output/CN_CN/"
global stata_output    "${SCI_PAT_ROOT}/../../stata_output/CN_CN/"
global figure_output   "${SCI_PAT_ROOT}/../../figure_output/CN_CN/"
global table_output    "${SCI_PAT_ROOT}/../../table_output/CN_CN/"
global temp_output     "${SCI_PAT_ROOT}/../../temp_output/CN_CN/"
global CN_patents      "${SCI_PAT_ROOT}/../../dataset/CN_patents/"
global other_data      "${SCI_PAT_ROOT}/../../dataset/Miscellaneous/"

global raw_data        "${SCI_PAT_ROOT}/../../dataset/"
global CN_US           "${SCI_PAT_ROOT}/../../stata_output/CN_US/"
global CSMAR           "${SCI_PAT_ROOT}/../../dataset/CSMAR/"
global USpatents       "${SCI_PAT_ROOT}/../../dataset/US_patents/"
global PCS             "${SCI_PAT_ROOT}/../../dataset/PCS/"
global USpatents_stata "${SCI_PAT_ROOT}/../../stata_output/CN_US/"

* REQUIRED by 01_build_cn_patents_database.do
global raw_CN_patents1 "${SCI_PAT_ROOT}/../../dataset/CN_patents/Invention Patent Grants 1985-2023/"
global raw_CN_patents2 "${SCI_PAT_ROOT}/../../dataset/CN_patents/Invention Patent Grants 2024-2025/"

* Ensure output/cache folders exist before downstream scripts write files.
* Non-fatal if a folder already exists.
cap mkdir "${python_output}"
cap mkdir "${stata_output}"
cap mkdir "${figure_output}"
cap mkdir "${table_output}"
cap mkdir "${temp_output}"
cap mkdir "${CN_patents}"
cap mkdir "${other_data}"

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
* Run pipeline (01-06)
*----------------------------*
* Execute sequentially because each step depends on outputs from prior steps.
_run_step, step("01") file("1_Data_cleaning/01_build_cn_patents_database.do")
_run_step, step("02") file("1_Data_cleaning/02_construct_cn_patents_variables.do")
_run_step, step("03") file("1_Data_cleaning/03_link_cn_patents_to_ros.do")
_run_step, step("04") file("1_Data_cleaning/04_build_analysis_sample.do")
_run_step, step("05") file("1_Data_cleaning/05_identify_cn_patents_by_el.do")
_run_step, step("06") file("1_Data_cleaning/06_flag_cn_patents_by_el.do")

display as result ""
display as result "=== Master run finished: " c(current_date) " " c(current_time) " ==="
