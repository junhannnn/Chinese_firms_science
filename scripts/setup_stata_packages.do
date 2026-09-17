version 18.0
set more off

/*
Install the user-written Stata commands used by the released analysis scripts.
Run this once in an internet-enabled Stata session before executing the main
analysis do-files:

    do scripts/setup_stata_packages.do

The commands are installed from SSC into the user's normal PLUS directory.
If a package is unavailable from SSC in a given Stata setup, the script leaves a
clear warning so it can be installed manually before dependent analyses run.
*/

local packages "ftools reghdfe ppmlhdfe winsor2 estout cem distinct ivreghdfe asdoc eventdd pretrends honestdid coefplot didplacebo"

foreach pkg of local packages {
    capture which `pkg'
    if _rc {
        display as text "Installing `pkg' from SSC..."
        capture noisily ssc install `pkg', replace
        if _rc {
            display as error "Could not install `pkg' automatically from SSC. Install it manually before running dependent analyses."
        }
    }
    else {
        display as result "`pkg' is already installed."
    }
}

display as result "Stata package setup finished."
