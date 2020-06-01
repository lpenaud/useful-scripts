#!/bin/bash
#

DIRNAME="$(dirname "${0}")"
. "${DIRNAME}/../helpers/parallel"
. "${DIRNAME}/../helpers/functions"

function test_1 () {
  local prefix="test_1"
  assert_equals 0 "${PARALLEL_COUNT}" "${prefix} - PARALLEL_COUNT expected to be equals 0 at the start"
  parallel::run "sleep 3"
  parallel::run "sleep 2"
  assert_equals 2 "${PARALLEL_COUNT}" "${prefix} - PARALLEL_COUNT expected to be equals 2"
  parallel::wait_all
  assert_equals 0 "${PARALLEL_COUNT}" "${prefix} - PARALLEL_COUNT expected to be equals 0 at the end"
}

function test_2 () {
  local prefix="test_2"
  local -a tasks
  assert_equals 0 "${PARALLEL_COUNT}" "${prefix} - PARALLEL_COUNT expected to be equals 0 at the start"
  tasks+=("$(parallel::run "sleep 10")")
  tasks+=("$(parallel::run "sleep 2")")
  echo "${PARALLEL_COUNT}"
  assert_equals 2 "${PARALLEL_COUNT}" "HEIN"
  assert_equals 2 "${#tasks}" "SIZE"
  kill -kill "${tasks[0]}"
  parallel::wait "${tasks[0]}"
  echo "${tasks[0]} was terminated by a SIG$(kill −l $?) signal."
  parallel::wait_all
}

parallel::init
test_1
test_2

