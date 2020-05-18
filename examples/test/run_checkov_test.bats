#!/usr/bin/env bats
load 'libs/bats-support/load'
load 'libs/bats-assert/load'
load 'test_helper'

profile_script="./run-checkov_refactor.sh"

@test "find_folders_by() should successful find right content" {
    source ${profile_script}
    run find_folders_by
    assert_success
}

@test "run_checov() should successful execute a checov run" {
    function docker() { echo "THIS WOULD docker ${*}"; }
    export -f docker
    source ${profile_script}
    run run_checkov
    assert_success
}

@test "test run_main() should be successfull " {
    function find_folders_by() { find ./samples/  -type f -name main.tf -printf '%h\n' | sort -u; }
    export -f find_folders_by
    function run_checov() { echo "THIS WOULD run_checov ${*}"; }
    export -f run_checov
    source ${profile_script}
    run run_main
    assert_success
}