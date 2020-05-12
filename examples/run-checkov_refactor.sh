#!/bin/bash
#
# Runs the Checkov static analysis tool on all subdirectories
# of the target given as argument .
#
#  Usage ./run_checkov.sh {WORKk_DIR}
#
set -euo pipefail

# The target directory for scanning.
WORK_DIR=${1-$(pwd)}

#######################################
# run_checkov() doccker command
# Arguments:
#   test_dir folder
# Outputs:
#   Writes test command outputs to stdout
#   Exits on $? != 0
#######################################
run_checkov() {
  local test_dir=$1
  docker run -t -v "${test_dir}":/tf bridgecrew/checkov:release-1.0.235 -d /tf
  if [ $? != 0 ]; then
    printf "{FAIL] Found test errors in %s" "${test_dir}"  exit 1
  fi
}

#######################################
# find_folders_by() file pattern
# Globals:
#   WORK_DIR -path
# Arguments:
#   pattern - regex
# Outputs:
#   Writes folders list to stdout
#######################################
find_folders_by() {
  local pattern=${1:-"main.tf"}
  find "${WORK_DIR}" -type f -name "${pattern}" -printf '%h\n' | sort -u
}

#######################################
# Runs the Checkov static analysis tool on all subdirectories
#######################################
run_main() {
  for folder in $(find_folders_by "main.tf"); do
    run_checkov "${folder}" &
  done
  wait
}

#######################################
#  Be able to run this one either as standalone or import as lib
#######################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_main
fi
