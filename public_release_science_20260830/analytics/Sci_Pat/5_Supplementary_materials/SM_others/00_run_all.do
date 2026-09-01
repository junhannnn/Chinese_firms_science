/*******************************************************************************
Project: Background Supplementary Materials - Master Runner (SM01-SM04, SM06)
Script: SM_others/00_run_all.do

Purpose
  - Run SM plotting/calculation scripts in a fixed order.
  - Stop immediately if any step errors.

Run Order
  - 01_ROS_US_firm.do
  - 02_Papers_cited_CN_US.do
  - 03_Publicly listed firms/1_US_DISCERN_plot.do
  - 03_Publicly listed firms/2_2_CN_CNKI_plot.do
  - 03_Publicly listed firms/3_6_CN_WOS_plot.do
  - 04_front_page_citation.do
  - 06_Pretrend.do

Notes
  - Path globals are centralized in this runner.
  - Child scripts should not define their own cd/global path blocks.
  - Relative paths below are written from the SM_others folder.
*******************************************************************************/

version 18.0
clear all
set more off
set linesize 255

*----------------------------*
* 0. Working directory (SM_others folder)
*----------------------------*
capture cd ".\analytics\Sci_Pat\5_Supplementary_materials\SM_others\"
if _rc {
    capture cd "./analytics/Sci_Pat/5_Supplementary_materials/SM_others/"
    if _rc {
        di as error "ERROR: cannot cd to Sci_Pat/5_Supplementary_materials/SM_others directory."
        exit 198
    }
}

display as text "Current directory: " c(pwd)
global RUNNER_DIR `"`c(pwd)'"'
display as text "Runner directory: " "$RUNNER_DIR"

display as text "=== SM master run started: " c(current_date) " " c(current_time) " ==="

*----------------------------*
* Helper: run a do-file and stop if it errors
*----------------------------*
capture program drop _run_step
program define _run_step
    syntax, FILE(string) STEP(string)

    display as text ""
    display as text "------------------------------------------------------------"
    display as text "Running Step `step': `file'"
    display as text "------------------------------------------------------------"

    * Child scripts may change directories; reset before each run.
    capture cd "$RUNNER_DIR"

    capture noisily do "`file'"
    if _rc {
        display as error "ERROR in Step `step' (`file'). Return code = " _rc
        display as error "Pipeline stopped."
        exit _rc
    }
    else {
        capture cd "$RUNNER_DIR"
        display as result "Step `step' completed successfully."
    }
end

*----------------------------*
* Run SM scripts sequentially
*----------------------------*
* Step SM01 paths (Sci_Pat inputs + CN_CN outputs).
global stata_output "../../../../stata_output/CN_CN/"
global figure_output "../../../../figure_output/CN_CN/"
global temp_output "../../../../temp_output/CN_CN/"
global PCS "../../../../dataset/PCS/"
global USpatents_stata "../../../../stata_output/CN_US/"
global USpatents "../../../../dataset/US_patents/"
global CN_patents "../../../../dataset/CN_patents/"
_run_step, step("SM01") file("01_ROS_US_firm.do")

* Step SM02 paths (Sci_Pat inputs + CN_CN outputs).
global stata_output "../../../../stata_output/CN_CN/"
global temp_output "../../../../temp_output/CN_CN/"
global USpatents_stata "../../../../stata_output/CN_US/"
global PCS "../../../../dataset/PCS/"
global figure_output "../../../../figure_output/CN_CN/"
_run_step, step("SM02") file("02_Papers_cited_CN_US.do")

* Step SM03A paths (DISCERN/WOS outputs).
global stata_output "../../../../stata_output/WOS/"
global temp_output "../../../../temp_output/WOS/"
global figure_output "../../../../figure_output/WOS/"
global discern "../../../../dataset/DISCERN/output_files/stata_files/"
_run_step, step("SM03A") file("03_Publicly listed firms/1_US_DISCERN_plot.do")

* Step SM03B paths (CNKI outputs).
global stata_output "../../../../stata_output/CNKI/"
global temp_output "../../../../temp_output/CNKI/"
global figure_output "../../../../figure_output/CNKI/"
global python_output "../../../../proc_output/CNKI/"
_run_step, step("SM03B") file("03_Publicly listed firms/2_2_CN_CNKI_plot.do")

* Step SM03C paths (WOS listed-firm outputs).
global stata_output "../../../../stata_output/WOS/"
global temp_output "../../../../temp_output/WOS/"
global figure_output "../../../../figure_output/WOS/"
global python_output "../../../../proc_output/WOS_listed/"
_run_step, step("SM03C") file("03_Publicly listed firms/3_6_CN_WOS_plot.do")

* Step SM04 paths (Sci_Pat inputs + CN_CN outputs).
global stata_output "../../../../stata_output/CN_CN/"
global figure_output "../../../../figure_output/CN_CN/"
global table_output "../../../../table_output/CN_CN/"
global temp_output "../../../../temp_output/CN_CN/"
global PCS "../../../../dataset/PCS/"
global USpatents_stata "../../../../stata_output/CN_US/"
_run_step, step("SM04") file("04_front_page_citation.do")

* Step SM06 paths (Sci_Pat inputs + CN_CN outputs).
global stata_output "../../../../stata_output/CN_CN/"
global figure_output "../../../../figure_output/CN_CN/"
_run_step, step("SM06") file("06_Pretrend.do")

display as result ""
display as result "=== SM master run finished: " c(current_date) " " c(current_time) " ==="
