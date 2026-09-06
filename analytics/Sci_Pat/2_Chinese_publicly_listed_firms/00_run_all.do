/*******************************************************************************
Project: Science-linked patents—Chinese publicly listed firms
Script:  00_run_all.do

Purpose:
  Configure shared project paths and execute the four listed-firm analysis
  scripts in sequence. The runner stops if a child script is missing or returns
  an error.

Main inputs:
  - 01_main_effect.do
  - 02_moderators.do
  - 03_dynamic_effect_main.do
  - 04_dynamic_effect_mo.do
  - Upstream analysis datasets referenced by the child scripts

Main outputs:
  Analysis datasets, tables, figures, and temporary files written under the
  shared output directories defined below.

Run order:
  01_main_effect.do, 02_moderators.do, 03_dynamic_effect_main.do,
  then 04_dynamic_effect_mo.do.

Notes:
  Run this file from the release root, analytics/Sci_Pat, or
  2_Chinese_publicly_listed_firms. When launching it elsewhere, pass any of
  those locations as the first do-file argument. Required upstream datasets
  must be prepared before running this file.
*******************************************************************************/

* ==============================================================================
* 1. Initialize the Stata session and define shared project paths
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

* Normalize the working directory to analytics/Sci_Pat.
capture confirm file "2_Chinese_publicly_listed_firms/00_run_all.do"
if _rc {
    capture confirm file "00_run_all.do"
    if !_rc {
        capture cd ".."
    }
    else {
        capture cd "./analytics/Sci_Pat/"
    }
}

capture confirm file "2_Chinese_publicly_listed_firms/00_run_all.do"
if _rc {
    di as error "ERROR: cannot locate analytics/Sci_Pat."
    di as error "Start from the release root, analytics/Sci_Pat, or 2_Chinese_publicly_listed_firms, or pass one as argument 1."
    exit 198
}
display as text "Current directory: " c(pwd)

* Store the project root so paths remain stable if a child script changes cwd.
global SCI_PAT_ROOT "`c(pwd)'"

* Define shared input and output directories for the listed-firm scripts.
global stata_output "${SCI_PAT_ROOT}/../../stata_output/CN_CN/"
global figure_output "${SCI_PAT_ROOT}/../../figure_output/CN_CN/"
global table_output "${SCI_PAT_ROOT}/../../table_output/CN_CN/"
global temp_output "${SCI_PAT_ROOT}/../../temp_output/CN_CN/"
global CN_patents "${SCI_PAT_ROOT}/../../dataset/CN_patents/"

display as text "=== Master run started: " c(current_date) " " c(current_time) " ==="

* ==============================================================================
* 2. Define the fail-fast child-script runner
* ==============================================================================

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

    * Stop before execution if the requested child script is missing.
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
* 3. Execute the listed-firm analysis pipeline
* ==============================================================================

_run_step, step("01") file("2_Chinese_publicly_listed_firms/01_main_effect.do")
_run_step, step("02") file("2_Chinese_publicly_listed_firms/02_moderators.do")
_run_step, step("03") file("2_Chinese_publicly_listed_firms/03_dynamic_effect_main.do")
_run_step, step("04") file("2_Chinese_publicly_listed_firms/04_dynamic_effect_mo.do")

display as result ""
display as result "=== Master run finished: " c(current_date) " " c(current_time) " ==="
