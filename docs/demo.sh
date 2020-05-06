#!/bin/bash
set -euo pipefail
IFS=$'\n\t' # Internal Field Separator - controls what Bash calls word splitting.

#  Global vars
LOCATION="francecentral"
LOOPS=5

deployAndDestroy() {
    local suffix=$1
    terraform_state_file="terraform${suffix}.tfstate"
    terraform apply -var location="${LOCATION}" -state="${terraform_state_file}" -auto-approve
    terraform destroy -var location="${LOCATION}" -state="${terraform_state_file}" -auto-approve
}

# main looping over seq of LOOPS deployAndDestroy() in parallel
run_main() {
    # POSIX command lookup example
    # command -v will return >0 when the $i is not found
    command -v "terraform" >/dev/null && continue || {
        echo "$i command not found."
        exit 1
    }
    for loop in $(seq $LOOPS); do
        deployAndDestroy $loop &
    done
    wait # for all threads beeing executed
}

#  Be able to run this one either as standalone or import as lib
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_main
fi
