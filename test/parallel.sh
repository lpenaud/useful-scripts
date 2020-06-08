#!/bin/bash
#

DIRNAME="$(dirname "${0}")"
. "${DIRNAME}/../helpers/parallel"
. "${DIRNAME}/../helpers/functions"

function test_1 () {
  local prefix="test_1"
  local -a com
  assert_equals 0 "$(parallel::count)" "${prefix} - parallel::count expected to be equals 0 at the start but $(parallel::count)"
  com=(sleep 3)
  parallel::run com
  com=(sleep 1)
  parallel::run com
  assert_equals 2 "$(parallel::count)" "${prefix} - parallel::count expected to be equals 2 but $(parallel::count)"
  wait
  assert_equals 0 "$(parallel::count)" "${prefix} - parallel::count expected to be equals 0 at the end but $(parallel::count)"
}

function test_2 () {
  local prefix="test_2"
  local -i idt1 idt2
  local -a com
  assert_equals 0 "$(parallel::count)" "${prefix} - parallel::count expected to be equals 0 at the start but $(parallel::count)"
  com=(sleep 10)
  parallel::run com idt1
  com=(sleep 2)
  parallel::run com idt2
  assert_equals 2 "$(parallel::count)" "${prefix} - parallel::count expected to be equals 2 but $(parallel::count)"
  kill -kill "${idt1}"
  wait "${idt1}" "${idt2}"
  assert_equals 0 "$(parallel::count)" "${prefix} - parallel::count expected to be equals 0 at the end but $(parallel::count)"
}

parallel::init
test_1
test_2
wait
