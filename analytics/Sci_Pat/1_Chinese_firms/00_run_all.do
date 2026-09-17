/*******************************************************************************
Project: Science-linked patents—Chinese-firm analysis
Script:  00_run_all.do

Purpose:
  Configure shared paths and run the four Chinese-firm analysis scripts in a
  fixed order. The runner stops immediately if a child script is missing or
  returns an error.

Main inputs:
  - 01_DID_panel.do
  - 02_moderators.do
  - 03_knowledge_source.do
  - 04_vintage.do

Main outputs:
  Summary statistics, baseline and moderator estimates, knowledge-source
  comparisons, matching diagnostics, and publication-vintage estimates written
  under table_output.

Run order:
  01_DID_panel.do, 02_moderators.do, 03_knowledge_source.do, then 04_vintage.do.

Notes:
  Run this file from the release root, analytics/Sci_Pat, or 1_Chinese_firms.
  When launching it elsewhere, pass any of those locations as the first do-file
  argument.
*******************************************************************************/

* ==============================================================================
* 1. Configure the Stata session and working directory
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
capture confirm file "1_Chinese_firms/00_run_all.do"
if _rc {
    capture confirm file "00_run_all.do"
    if !_rc {
        capture cd ".."
    }
    else {
        capture cd "./analytics/Sci_Pat/"
    }
}

capture confirm file "1_Chinese_firms/00_run_all.do"
if _rc {
    di as error "ERROR: cannot locate analytics/Sci_Pat."
    di as error "Start from the release root, analytics/Sci_Pat, or 1_Chinese_firms, or pass one as argument 1."
    exit 198
}
display as text "Current directory: " c(pwd)

* Store the Sci_Pat directory so relative paths remain stable across steps.
global SCI_PAT_ROOT "`c(pwd)'"

* Define shared processed-data, figure, table, and temporary-output directories.
global stata_output "${SCI_PAT_ROOT}/../../stata_output/CN_CN/"
global figure_output "${SCI_PAT_ROOT}/../../figure_output/CN_CN/"
global table_output "${SCI_PAT_ROOT}/../../table_output/CN_CN/"
global temp_output "${SCI_PAT_ROOT}/../../temp_output/CN_CN/"

display as text "=== Master run started: " c(current_date) " " c(current_time) " ==="

* ==============================================================================
* 2. Define and validate the child-script manifest
* ==============================================================================

local run_steps "01 02 03 04"
local run_files "1_Chinese_firms/01_DID_panel.do 1_Chinese_firms/02_moderators.do 1_Chinese_firms/03_knowledge_source.do 1_Chinese_firms/04_vintage.do"

* Confirm every child script exists before any analysis step creates output.
local run_index 0
local preflight_failed 0
foreach file of local run_files {
    local ++run_index
    local step : word `run_index' of `run_steps'
    capture confirm file "`file'"
    if _rc {
        display as error "MISSING Step `step': `file'"
        local preflight_failed 1
    }
}

if `preflight_failed' {
    display as error "ERROR: do-file preflight failed; no analysis steps were run."
    exit 601
}

* ==============================================================================
* 3. Run the Chinese-firm analysis pipeline
* ==============================================================================

* Keep orchestration at do-file scope because 01_DID_panel.do calls clear all.
local run_index 0
foreach file of local run_files {
    local ++run_index
    local step : word `run_index' of `run_steps'

    capture cd "${SCI_PAT_ROOT}"
    local cwd_rc = _rc
    if `cwd_rc' {
        display as error "ERROR: cannot return to project root: ${SCI_PAT_ROOT}"
        exit 198
    }

    display as text ""
    display as text "------------------------------------------------------------"
    display as text "Running Step `step': `file'"
    display as text "------------------------------------------------------------"

    capture noisily do "`file'"
    local step_rc = _rc
    if `step_rc' {
        display as error "ERROR in Step `step' (`file'). Return code = `step_rc'"
        display as error "Pipeline stopped."
        exit `step_rc'
    }

    display as result "Step `step' completed successfully."
}

display as result ""
display as result "=== Master run finished: " c(current_date) " " c(current_time) " ==="
