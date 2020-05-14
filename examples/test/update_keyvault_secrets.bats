#!/usr/bin/env bats
load 'libs/bats-support/load'
load 'libs/bats-assert/load'
load 'test_helper'

profile_script="./update_keyvault_secrets.sh"

@test "test run_main should be successfull " {
    function cat() { echo "THIS WOULD CAT ${*}"; }
    export -f cat
    source ${profile_script}
    run run_main
    assert_success
}