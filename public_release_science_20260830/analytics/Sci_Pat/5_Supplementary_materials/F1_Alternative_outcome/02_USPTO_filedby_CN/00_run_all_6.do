/*******************************************************************************
Project: Robustness Checks - USPTO Patents Filed by Chinese Firms (Master Runner)
Script: 00_run_all_6.do

Purpose
  - Run the USPTO-based robustness-check Stata scripts in this subfolder with
    fail-fast error handling.
  - Set shared globals used across steps (including `${temp_output}` required by
    `06_moderator_USPTO.do`).
  - Re-anchor the working directory to the project root before each step,
    because several scripts change `cd` during execution.

Run Order (current file state)
  - 5_Supplementary_materials/F1_Alternative_outcome/02_USPTO_filedby_CN/04_Entity_list_match_patent_USPTO.do
  - 5_Supplementary_materials/F1_Alternative_outcome/02_USPTO_filedby_CN/05_DID_USPTO.do
  - 5_Supplementary_materials/F1_Alternative_outcome/02_USPTO_filedby_CN/06_moderator_USPTO.do
  - 5_Supplementary_materials/F1_Alternative_outcome/02_USPTO_filedby_CN/07_knowledge_source_USPTO.do
  - 5_Supplementary_materials/F1_Alternative_outcome/02_USPTO_filedby_CN/08_vintage_USPTO.do

Notes
  - Notebook steps `01_*.ipynb`, `02_*.ipynb`, and `03_*.ipynb` are not executed
    here. This runner assumes their required outputs already exist.
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

* Store project root so each step can reset cwd before running.
global SCI_PAT_ROOT "`c(pwd)'"

* ---- centralized paths for USPTO robustness scripts (04-08) ----
global python_output "${SCI_PAT_ROOT}/../../proc_output/CN_CN/"
global stata_output "${SCI_PAT_ROOT}/../../stata_output/CN_CN/"
global figure_output "${SCI_PAT_ROOT}/../../figure_output/CN_CN/"
global table_output "${SCI_PAT_ROOT}/../../table_output/CN_CN/"
global temp_output "${SCI_PAT_ROOT}/../../temp_output/CN_CN/"
global USpatents "${SCI_PAT_ROOT}/../../dataset/US_patents/"
global CN_US "${SCI_PAT_ROOT}/../../stata_output/CN_US/"

display as text "=== USPTO robustness master run started: " c(current_date) " " c(current_time) " ==="

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
* Run pipeline (04-08)
*----------------------------*
_run_step, step("04") file("5_Supplementary_materials/F1_Alternative_outcome/02_USPTO_filedby_CN/04_Entity_list_match_patent_USPTO.do")
_run_step, step("05") file("5_Supplementary_materials/F1_Alternative_outcome/02_USPTO_filedby_CN/05_DID_USPTO.do")
_run_step, step("06") file("5_Supplementary_materials/F1_Alternative_outcome/02_USPTO_filedby_CN/06_moderator_USPTO.do")
_run_step, step("07") file("5_Supplementary_materials/F1_Alternative_outcome/02_USPTO_filedby_CN/07_knowledge_source_USPTO.do")
_run_step, step("08") file("5_Supplementary_materials/F1_Alternative_outcome/02_USPTO_filedby_CN/08_vintage_USPTO.do")

display as result ""
display as result "=== USPTO robustness master run finished: " c(current_date) " " c(current_time) " ==="

