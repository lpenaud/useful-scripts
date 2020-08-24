#!/bin/bash

declare -r DIRNAME="$(dirname "${0}")"
. "${DIRNAME}/../helpers/functions"
import "../helpers/array"

function set_cmd () {
  local -n args=$1
  local -a result=(gs -dNOPAUSE -dBATCH -dSAFER -sDEVICE=pdfwrite "-sOUTPUTFILE=${2}")
  for arg in "${args[@]}"; do
    result+=("${arg}")
  done
  args=("${result[@]}")
}

function main () {
  local -a cmd documents tmp_doc
  # $first and $last aren't integer variable because bash set their value to 0 even if is set to empty
  local first last list is_sub outfile="-"
  while [ $# -ne 0 ]; do
    case "${1}" in
      -o | --output)
        outfile="${2}"
        shift
        ;;
      -f | --first)
        assert_is_positive "${2}" "Expected a positive number for '${1}' flag but found '${2}'"
        first="${2}"
        shift
        ;;
      -a | --last)
        assert_is_positive "${2}" "Expected a positive number for '${1}' flag but found '${2}'"
        last="${2}"
        shift
        ;;
      -l | --list)
        if [[ ! "${2}" =~ ^([0-9](,|-)?)+$ ]]; then
          raise 1 "Expected a value which match with ^([0-9](,|-)?)+$ for '${1}' but found '${2}'"
        fi
        list="${2}"
        shift
        ;;
      *)
        if [ ! -f "${1}" ]; then
          raise 1 "Expected an existing pdf file but found '${1}'"
        fi
        if [ -n "${first}" ]; then
          cmd+=("-dFirstPage=${first}")
          first=""
        fi
        if [ -n "${last}" ]; then
          cmd+=("-dLastPage=${last}")
          last=""
        fi
        if [ -n "${list}" ]; then
          cmd+=("-sPageList=${list}")
          list=""
        fi
        if [ "${#cmd[@]}" -eq 0 ]; then
          documents+=("${1}")
        else
          # GhostScript doesn't work like mkvmerge
          cmd+=("${1}")
          tmp_doc+=("$(mktemp --suffix=.pdf)")
          set_cmd cmd "$(array::get_last_value tmp_doc)"
          echo "${cmd[@]}" >&2
          "${cmd[@]}" >> /dev/null
          cmd=()
        fi
        ;;
    esac
    shift
  done
  set_cmd cmd "${outfile}"
  cmd+=("${documents[@]}")
  cmd+=("${tmp_doc[@]}")
  echo "${cmd[@]}" >&2
  "${cmd[@]}" >> /dev/null
  if [ "${#tmp_doc[@]}" -ne 0 ]; then
    cmd=(rm "${tmp_doc[@]}")
    echo "${cmd[@]}" >&2
    "${cmd[@]}"
  fi
}

if [ $# -eq 0 ]; then
  print_usage "<...pdf files>" \
    "(--first -f) <first page> <pdf file>" \
    "(--last -a) <last page> <pdf file>" \
    "(--list -l) <range pages> <pdf file>" \
    "(--output -o) <outfile>"
  exit 1
fi

main "$@"
