#!/bin/bash

declare -r DIRNAME="$(dirname "${0}")"
. "${DIRNAME}/../helpers/functions"
import "../helpers/array"

declare -g -r -a ARRAY=(1 2 3)

function test_index_of () {
  local -r prefix="test_index_of"
  local -i actual code

  actual="$(array::index_of ARRAY 3)"
  code="${?}"
  assert_equals 0 "${code}" "${prefix} - Should return '0' but found '${code}'"
  assert_equals 2 "${actual}" "${prefix} - Expected '2' but found '${actual}'"

  actual="$(array::index_of ARRAY 0)"
  code="${?}"
  assert_equals 1 "${code}" "${prefix} - Should return '1' but found '${code}'"
  assert_equals -1 "${actual}" "${prefix} - Expected '-1' but found '${actual}'"
}

test_index_of
