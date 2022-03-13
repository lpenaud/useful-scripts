#!/bin/bash
# Create 16x16 icon from an picture (jpg, png, WebP...).
#

source "$(dirname "${BASH_SOURCE}")/../helpers/base.sh"
base::import "helpers/functions"

if [ $# -eq 0 ] || [ $# -gt 2 ]; then
  print_usage "<infile>" "<infile> <outfile>"
  exit 1
fi

infile="$(argparse::infile "${1}")"
assert_code
if [ $# -eq 2 ]; then
  outfile="$(argparse::outfile "${2}" ".ico")"
else
  outfile="$(get_filename "${infile}").ico"
fi
convert -resize 16x16 "${infile}" "${outfile}"
