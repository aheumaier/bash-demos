#!/usr/bin/env bats

load '../../test_helper/bats-support/load'
load '../../test_helper/bats-assert/load'


@test "addition using bc" {
  result="$(echo 2+2 | bc)"
  [ "$result" -eq 4 ]
}

@test "addition using dc" {
  result="$(echo 2 2+p | dc)"
  [ "$result" -eq 4 ]
}

@test "invoking foo with a nonexistent file prints an error" {
  run cat nonexistent_filename
  [ "$status" -eq 1 ]
  [ "$output" = "foo: no such file 'nonexistent_filename'" ]
}