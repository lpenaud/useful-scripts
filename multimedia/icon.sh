#!/bin/bash
# Create 16x16 icon from an picture (jpg, png, WebP...).
#

DIRNAME="$(dirname ${0})"
. "${DIRNAME}/../helpers/functions"

if [ $# -eq 0 ] || [ $# -gt 2 ]; then
  print_usage "<infile>" "<infile> <outfile>"
  exit 1
fi

infile="$(parse_input_file "${1}")"
assert_code
if [ $# -eq 2 ]; then
  outfile="$(parse_output_file "${2}" ".ico" "${infile}")"
else
  outfile="$(filename_ext "${infile}").ico"
fi
log_exec convert -resize 16x16 "${infile}" "${outfile}"
