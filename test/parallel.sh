#!/bin/bash
#

DIRNAME="$(dirname "${0}")"
. "${DIRNAME}/../helpers/parallel"
. "${DIRNAME}/../helpers/functions"

function test_1 () {
  local prefix="test_1"
  local -a com
  assert_equals 0 "${PARALLEL_COUNT}" "${prefix} - PARALLEL_COUNT expected to be equals 0 at the start"
  com=(sleep 3)
  parallel::run com
  com=(sleep 1)
  parallel::run com
  assert_equals 2 "${PARALLEL_COUNT}" "${prefix} - PARALLEL_COUNT expected to be equals 2"
  parallel::wait_all
  assert_equals 0 "${PARALLEL_COUNT}" "${prefix} - PARALLEL_COUNT expected to be equals 0 at the end"
}

function test_2 () {
  local prefix="test_2"
  local -i idt1 idt2
  local -a com
  assert_equals 0 "${PARALLEL_COUNT}" "${prefix} - PARALLEL_COUNT expected to be equals 0 at the start"
  com=(sleep 10)
  parallel::run com idt1
  com=(sleep 2)
  parallel::run com idt2
  assert_equals 2 "${PARALLEL_COUNT}" "${prefix} - PARALLEL_COUNT expected to be equals 2"
  kill -kill "${idt1}"
  parallel::wait "${idt1}" "${idt2}"
  # Same as parallel::wait_all
  assert_equals 0 "${PARALLEL_COUNT}" "${prefix} - PARALLEL_COUNT expected to be equals 0 at the end"
}

parallel::init
test_1
test_2

