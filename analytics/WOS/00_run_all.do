/*******************************************************************************
Project: WOS analysis
Script:  00_run_all.do

Purpose:
  Configure shared paths and run the WOS baseline, listed-firm, and dynamic-
  effects scripts in a fixed order. The runner stops immediately if a child
  script is missing or returns an error.

Main inputs:
  - 01_WOS_DID.do
  - 03_WOS_DID_listed.do
  - 04_WOS_dynamic_effect.do

Main outputs:
  - ${table_output}summary_stats_wos.doc
  - ${table_output}WOS.rtf and ${table_output}WOS_listedfirm.rtf
  - ${stata_output}WOS_event_table.dta
  - ${figure_output}WOS_dynamic.gph

Run order:
  01_WOS_DID.do, 03_WOS_DID_listed.do, then 04_WOS_dynamic_effect.do.

Notes:
  Run this file while Stata's current working directory is either the repository
  root or analytics/WOS. When launching it from another directory, pass either
  of those locations as the first do-file argument. The 02_WOS_CSMAR_fuzzy.ipynb
  prerequisite is not executed by this Stata runner.
*******************************************************************************/

* ==============================================================================
* 1. Configure the Stata session and locate the WOS directory
* ==============================================================================

version 18.0
clear all
set more off
set linesize 255

* An optional argument allows calls from a working directory outside the release.
args project_dir
if `"`project_dir'"' != "" {
    capture cd `"`project_dir'"'
    if _rc {
        di as error "ERROR: cannot cd to the supplied project directory: `project_dir'"
        exit 198
    }
}

capture confirm file "01_WOS_DID.do"
if _rc {
    capture cd "./analytics/WOS/"
    if _rc {
        di as error "ERROR: cannot locate the WOS directory."
        di as error "Start from the release root or analytics/WOS, or pass either path as argument 1."
        exit 198
    }
}
display as text "Current directory: " c(pwd)

* Store the WOS script directory so relative paths remain stable across steps.
global WOS_ROOT "`c(pwd)'"

* Define shared data, table, figure, and temporary-output directories.
global python_output "${WOS_ROOT}/../../proc_output/WOS/"
global stata_output  "${WOS_ROOT}/../../stata_output/WOS/"
global table_output  "${WOS_ROOT}/../../table_output/WOS/"
global temp_output   "${WOS_ROOT}/../../temp_output/WOS/"
global figure_output "${WOS_ROOT}/../../figure_output/WOS/"
global CN_CN         "${WOS_ROOT}/../../stata_output/CN_CN/"

* Create output directories when absent; existing directories are left unchanged.
cap mkdir "${python_output}"
cap mkdir "${stata_output}"
cap mkdir "${table_output}"
cap mkdir "${temp_output}"
cap mkdir "${figure_output}"
cap mkdir "${CN_CN}"

display as text "=== WOS master run started: " c(current_date) " " c(current_time) " ==="

* ==============================================================================
* 2. Define an error-checked child-script runner
* ==============================================================================

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

* ==============================================================================
* 3. Run the WOS analysis pipeline
* ==============================================================================

_run_step, step("01") file("01_WOS_DID.do")
_run_step, step("03") file("03_WOS_DID_listed.do")
_run_step, step("04") file("04_WOS_dynamic_effect.do")

display as result ""
display as result "=== WOS master run finished: " c(current_date) " " c(current_time) " ==="
