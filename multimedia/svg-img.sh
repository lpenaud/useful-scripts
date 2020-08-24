#!/bin/bash
# See https://inkscape.org/en/doc/inkscape-man.html

readonly DIRNAME="$(dirname "${0}")"
readonly DEBUG=true
. "${DIRNAME}/../helpers/functions"

declare -r -a FORMATS=("svg" "png" "ps" "eps" "pdf" "emf" "wmf" "xaml")

function usage () {
  print_usage "<src> [dst]" \
    "(--format -f) <...formats> (--outfile -o) <file> <infile>"
  exit 1
}

function simple_export () {
  local -r infile="$(parse_input_file "${1}")"
  local -i status="$?"
  local outfile="${2}"
  if [ "${status}" -ne 0 ]; then
    exit "${status}"
  fi
  if [ ! -e "$(get_dirname "${outfile}")" ]; then
    usage
  fi
  log_exec inkscape --export-filename="${outfile}" "${infile}"
}

if [ $# -eq 0 ]; then
  usage
fi

if [ $# -eq 2 ]; then
  simple_export "${1}" "${2}"
fi
