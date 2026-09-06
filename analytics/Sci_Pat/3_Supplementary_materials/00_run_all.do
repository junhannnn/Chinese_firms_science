/*******************************************************************************
Project: Supplementary Materials - Master Runner
Script: 3_Supplementary_materials/00_run_all.do

Purpose
  - Run the supplementary-material Stata scripts with fail-fast error handling.
  - Set default shared globals before execution.
  - Validate the complete Stata do-file manifest before running any analysis.
  - Re-anchor the working directory and reset shared globals before each step,
    because several supplementary scripts change session state.

Run Order (current file state)
  - F1_Alternative_outcome/01_Alternative_measures.do
  - F1_Alternative_outcome/02_Science_closeness.do
  - F1_Alternative_outcome/03_high_JIF.do
  - F2_Negative_control/01_UM.do
  - F2_Negative_control/02_new_investment.do
  - F2_Negative_control/03_new_subs.do
  - F3_Alternative_identification/01-05_*.do
  - F4_Additional_analyses/01_whether_grant.do
  - F4_Additional_analyses/02_critical_time_trend_by_sector.do
  - F4_Additional_analyses/03_critical_reg_by_sector.do
  - F4_Additional_analyses/04_section_time_trend_by_sector.do
  - F4_Additional_analyses/05_section_reg_by_sector.do

Notes
  - Notebook-only prerequisite steps are not executed by this Stata runner.
  - A complete run requires raw/intermediate inputs that are documented but
    excluded from the lean public release.
  - Paths are written from `analytics/Sci_Pat`, except the adversary-country
    Excel preparation step, which is run from the release root because that
    child script uses `.\dataset\...` paths.
*******************************************************************************/

version 18.0
clear all
set more off
set linesize 255

*----------------------------*
* 0. Working directory
*----------------------------*

* Accept launches from the release root, analytics/Sci_Pat, or this folder.
capture confirm file "3_Supplementary_materials/00_run_all.do"
if _rc {
    capture confirm file "00_run_all.do"
    if !_rc {
        capture cd ".."
    }
    else {
        capture cd "analytics/Sci_Pat"
    }
}

capture confirm file "3_Supplementary_materials/00_run_all.do"
if _rc {
    di as error "ERROR: cannot locate analytics/Sci_Pat from the current directory."
    di as error "Start Stata in the release root, analytics/Sci_Pat, or 3_Supplementary_materials."
    exit 601
}
display as text "Current directory: " c(pwd)

* Store project root so each step can reset cwd before running.
global SCI_PAT_ROOT "`c(pwd)'"
global RELEASE_ROOT "${SCI_PAT_ROOT}/../.."
global RUN5_ROOT    "${SCI_PAT_ROOT}/3_Supplementary_materials"

* ---- centralized paths for supplementary-material scripts ----
global RUN5_STATA_CN_CN "${SCI_PAT_ROOT}/../../stata_output/CN_CN/"
global RUN5_STATA_CNKI  "${SCI_PAT_ROOT}/../../stata_output/CNKI/"
global RUN5_STATA_WOS   "${SCI_PAT_ROOT}/../../stata_output/WOS/"

global RUN5_TABLE_CN_CN "${SCI_PAT_ROOT}/../../table_output/CN_CN/"
global RUN5_TABLE_WOS   "${SCI_PAT_ROOT}/../../table_output/WOS/"

* Backward-compatible defaults (in case a script still references these names).
global stata_output "${RUN5_STATA_CN_CN}"
global figure_output "${SCI_PAT_ROOT}/../../figure_output/CN_CN/"
global table_output "${RUN5_TABLE_CN_CN}"
global temp_output "${SCI_PAT_ROOT}/../../temp_output/CN_CN/"
global python_output "${SCI_PAT_ROOT}/../../proc_output/CN_CN/"
global raw_data "${SCI_PAT_ROOT}/../../dataset/CSMAR/"
global CN_patents "${SCI_PAT_ROOT}/../../dataset/CN_patents/"
global PCS "${SCI_PAT_ROOT}/../../dataset/PCS/"
global USpatents_stata "${SCI_PAT_ROOT}/../../stata_output/CN_US/"
global USpatents "${SCI_PAT_ROOT}/../../dataset/US_patents/"
global CN_US "${SCI_PAT_ROOT}/../../stata_output/CN_US/"
global dataset "${SCI_PAT_ROOT}/../../dataset/Miscellaneous/"
global subs_data "${SCI_PAT_ROOT}/../../dataset/CSMAR/CSMAR_subsidiary/"

display as text "=== Supplementary-materials master run started: " c(current_date) " " c(current_time) " ==="

*----------------------------*
* 1. Do-file manifest
*----------------------------*

local run_ids "f1_01 f1_02 f1_03 f2_01 f2_02 f2_03 f3_01 f3_02 f3_03 f3_04 f3_05 f4_01 f4_02 f4_03 f4_04 f4_05"

local f1_01_step "F1-01"
local f1_01_file "${RUN5_ROOT}/F1_Alternative_outcome/01_Alternative_measures.do"
local f1_02_step "F1-02"
local f1_02_file "${RUN5_ROOT}/F1_Alternative_outcome/02_Science_closeness.do"
local f1_03_step "F1-03"
local f1_03_file "${RUN5_ROOT}/F1_Alternative_outcome/03_high_JIF.do"

local f2_01_step "F2-01"
local f2_01_file "${RUN5_ROOT}/F2_Negative_control/01_UM.do"
local f2_02_step "F2-02"
local f2_02_file "${RUN5_ROOT}/F2_Negative_control/02_new_investment.do"
local f2_03_step "F2-03"
local f2_03_file "${RUN5_ROOT}/F2_Negative_control/03_new_subs.do"

local f3_01_step "F3-01"
local f3_01_file "${RUN5_ROOT}/F3_Alternative_identification/01_US_foreign_adversaries.do"
local f3_02_step "F3-02"
local f3_02_file "${RUN5_ROOT}/F3_Alternative_identification/02_export_US_adver.do"
local f3_03_step "F3-03"
local f3_03_file "${RUN5_ROOT}/F3_Alternative_identification/03_merge_export_patent.do"
local f3_04_step "F3-04"
local f3_04_file "${RUN5_ROOT}/F3_Alternative_identification/04_IV_reg.do"
local f3_05_step "F3-05"
local f3_05_file "${RUN5_ROOT}/F3_Alternative_identification/05_Placebo_test.do"

local f4_01_step "F4-01"
local f4_01_file "${RUN5_ROOT}/F4_Additional_analyses/01_whether_grant.do"
local f4_02_step "F4-02"
local f4_02_file "${RUN5_ROOT}/F4_Additional_analyses/02_critical_time_trend_by_sector.do"
local f4_03_step "F4-03"
local f4_03_file "${RUN5_ROOT}/F4_Additional_analyses/03_critical_reg_by_sector.do"
local f4_04_step "F4-04"
local f4_04_file "${RUN5_ROOT}/F4_Additional_analyses/04_section_time_trend_by_sector.do"
local f4_05_step "F4-05"
local f4_05_file "${RUN5_ROOT}/F4_Additional_analyses/05_section_reg_by_sector.do"

* Check every do-file before any step can create or replace outputs.
local preflight_failed 0
foreach run_id of local run_ids {
    local step `"``run_id'_step'"'
    local file `"``run_id'_file'"'

    capture confirm file `"`file'"'
    if _rc {
        display as error "MISSING Step `step': `file'"
        local preflight_failed 1
    }
}

if `preflight_failed' {
    display as error "ERROR: do-file preflight failed; no analysis steps were run."
    exit 601
}

*----------------------------*
* 2. Run supplementary-material pipeline
*----------------------------*

foreach run_id of local run_ids {
    local step `"``run_id'_step'"'
    local file `"``run_id'_file'"'
    local run_cwd "${SCI_PAT_ROOT}"

    * F3-01 alone uses release-root-relative dataset paths.
    if `"`step'"' == "F3-01" {
        local run_cwd "${RELEASE_ROOT}"
    }

    capture cd `"`run_cwd'"'
    local cwd_rc = _rc
    if `cwd_rc' {
        display as error "ERROR: cannot cd to run directory: `run_cwd'"
        exit 198
    }

    * Restore canonical defaults in case a prior child script changed globals.
    global stata_output "${RUN5_STATA_CN_CN}"
    global figure_output "${SCI_PAT_ROOT}/../../figure_output/CN_CN/"
    global table_output "${RUN5_TABLE_CN_CN}"
    global temp_output "${SCI_PAT_ROOT}/../../temp_output/CN_CN/"
    global python_output "${SCI_PAT_ROOT}/../../proc_output/CN_CN/"
    global raw_data "${SCI_PAT_ROOT}/../../dataset/CSMAR/"
    global CN_patents "${SCI_PAT_ROOT}/../../dataset/CN_patents/"
    global PCS "${SCI_PAT_ROOT}/../../dataset/PCS/"
    global USpatents_stata "${SCI_PAT_ROOT}/../../stata_output/CN_US/"
    global USpatents "${SCI_PAT_ROOT}/../../dataset/US_patents/"
    global CN_US "${SCI_PAT_ROOT}/../../stata_output/CN_US/"
    global dataset "${SCI_PAT_ROOT}/../../dataset/Miscellaneous/"
    global subs_data "${SCI_PAT_ROOT}/../../dataset/CSMAR/CSMAR_subsidiary/"

    display as text ""
    display as text "------------------------------------------------------------"
    display as text "Running Step `step': `file'"
    display as text "------------------------------------------------------------"

    * Keep orchestration at do-file scope: F3-02 and F3-03 call `clear all`,
    * which would otherwise drop a helper program used as the runner.
    capture noisily do `"`file'"'
    local step_rc = _rc
    if `step_rc' {
        display as error "ERROR in Step `step' (`file'). Return code = `step_rc'"
        display as error "Pipeline stopped."
        exit `step_rc'
    }

    display as result "Step `step' completed successfully."
}

display as result ""
display as result "=== Supplementary-materials master run finished: " c(current_date) " " c(current_time) " ==="
