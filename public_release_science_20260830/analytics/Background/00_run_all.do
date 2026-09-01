/*******************************************************************************
Project: Background Figures
Script: 00_run_all.do

Purpose
  - Run the background plotting scripts in a fixed order.
  - Stop immediately if any step errors.

Run Order
  - PCS_CNIPA.do
  - PCS_USPTO.do
  - CNKI.do
  - WOS.do

Notes
  - Path globals are centralized in this runner.
  - Child scripts should not define their own cd/global path blocks.
*******************************************************************************/

version 18.0
clear all
set more off
set linesize 255

*----------------------------*
* 0. Working directory (this folder)
*----------------------------*
capture cd ".\analytics\Background\"
if _rc {
    capture cd "./analytics/Background/"
    if _rc {
        di as error "ERROR: cannot cd to Background directory."
        exit 198
    }
}
display as text "Current directory: " c(pwd)
global RUNNER_DIR `"`c(pwd)'"'
display as text "Runner directory: " "$RUNNER_DIR"

display as text "=== Master run started: " c(current_date) " " c(current_time) " ==="

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

    * Child scripts may change the working directory; reset to runner folder first.
    capture cd "$RUNNER_DIR"

    capture noisily do "`file'"
    if _rc {
        display as error "ERROR in Step `step' (`file'). Return code = " _rc
        display as error "Pipeline stopped."
        exit _rc
    }
    else {
        * Restore runner folder so the next relative do-file path is resolvable.
        capture cd "$RUNNER_DIR"
        display as result "Step `step' completed successfully."
    }
end

*----------------------------*
* Run plotting scripts
*----------------------------*
* Execute sequentially to ensure a deterministic, reproducible run order.
* Sci_Pat inputs + CN_CN outputs
global stata_output "../../stata_output/CN_CN/"
global figure_output "../../figure_output/CN_CN/"
global temp_output "../../temp_output/CN_CN/"
global PCS "../../dataset/PCS/"
global USpatents_stata "../../stata_output/CN_US/"
_run_step, step("PCS_CNIPA") file("PCS_CNIPA.do")
_run_step, step("PCS_USPTO") file("PCS_USPTO.do")

* CNKI
global python_output "../../proc_output/CNKI/"
global stata_output "../../stata_output/CNKI/"
global table_output "../../table_output/CNKI/"
global figure_output "../../figure_output/CNKI/"
global temp_output "../../temp_output/CNKI/"
_run_step, step("CNKI") file("CNKI.do")

* WOS
global stata_output "../../stata_output/WOS/"
global table_output "../../table_output/WOS/"
global temp_output "../../temp_output/WOS/"
global figure_output "../../figure_output/WOS/"
_run_step, step("WOS") file("WOS.do")

display as result ""
display as result "=== Master run finished: " c(current_date) " " c(current_time) " ==="
