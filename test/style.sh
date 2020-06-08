#!/bin/bash

readonly DIRNAME="$(dirname "${0}")"
. "${DIRNAME}/../helpers/functions"
import "../helpers/style"

function format () {
  echo -en "${1}"
}

function test_1 () {
  local -r prefix="test_1"
  local -r msg="Bonjour"
  local current expected
  current="$(style::bold)${msg}$(style::reset_bold)"
  expected="$(format "\x1b[1m${msg}\x1b[22m")"
  assert_equals "${expected}" "${current}" "${prefix} - Expected '${expected}' but have '${current}'"
  current="$(style::underline)$(style::red)${msg}$(style::reset_underline)$(style::reset_color)"
  expected="$(format "\x1b[4m\x1b[31m${msg}\x1b[24m\x1b[39m")"
  assert_equals "${expected}" "${current}" "${prefix} - Expected '${expected}' but have '${current}'"
}

function test_2 () {
  local -r prefix="test_2"
  local -r msg="Salut"
  local current expected
  current="$(style::run 3 7 34 45)${msg}$(style::run 23 27 39 49)"
  expected="$(format "\x1b[3;7;34;45m")${msg}$(format "\x1b[23;27;39;49m")"
  assert_equals "${expected}" "${current}" "${prefix} - Expected '${expected}' but have '${current}'"
}

test_1
test_2
