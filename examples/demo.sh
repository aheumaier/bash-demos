#!/bin/bash
set -euo pipefail
IFS=$'\n\t' # Internal Field Separator - controls what Bash calls word splitting.
# 
# ==============================================================================
# Displays all lines in main script that start with '##'
# ------------------------------------------------------------------------------
usage() {
    [ "$*" ] && echo "$(basename $0): $*"
    sed -n '/^##/,/^$/s/^## \{0,1\}//p' "$0"
} #2>/dev/null
# ==============================================================================
# 
#  Global vars
declare -r LOCATION=${2:-"francecentral"}
declare -r LOOPS=${1:-"5"}

# POSIX command lookup example
# command -v will return >0 when the $i is not found
valid_command() {
    local -r command=$1
    command -v "${command}" >/dev/null || {
        echo "terraform: command not found."
        exit 1
    }
}

deployAndDestroy() {
    local -r suffix=$1
    local -r terraform_state_file="terraform${suffix}.tfstate"
    terraform apply -var location="${LOCATION}" -state="${terraform_state_file}" -auto-approve
    terraform destroy -var location="${LOCATION}" -state="${terraform_state_file}" -auto-approve
}

# main looping over seq of LOOPS deployAndDestroy() in parallel
run_main() {
    valid_command "terraform"

    for loop in $(seq "${LOOPS}"); do
        echo "deployAndDestroy" "${loop}" &
    done
    wait # for all threads beeing executed
}

#  Be able to run this one either as standalone or import as lib
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_main
fi
