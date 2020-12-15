#!/bin/bash

declare -r HELPERS_DIR="${0%\/*}/../../helpers"
. "${HELPERS_DIR}/array"
. "${HELPERS_DIR}/style"
. "${HELPERS_DIR}/help"

function set_tag::usage () {
  help::usage "-s TAG [VALUE...]" "-a TAG VALUE [VALUE...]" "TRACK" "TRACK ..."
}

function set_tag::help () {
  set_tag::usage
  help::description "Set flac metadata tags."
  help::positional_argument "TRACK" "Audio file in flac format."
  help::optional
  help::optional_help
  help::optional_argument "-s" "--set" var="TAG [VALUE...]" desc="Set tag values. If value is omitted, then remove the tag of the audio file."
  help::optional_argument "-a" "--append" var="TAG [VALUE...]" desc="Add a tag with associated values."
}

declare -a tags tracks
declare tag
while [ $# -ne 0 ]; do
  case "${1}" in
    -s | --set)
      tag="${2}"
      tags+=("--remove-tag=${tag}")
      shift
      ;;
    -a | --append)
      tag="${2}"
      shift
      ;;
    -h | --help)
      set_tag::help
      exit 0
      ;;
    *)
      if [ -f "${1}" ]; then
        if [[ "${1}" =~ \.flac$ ]]; then
          tracks+=("${1}")
        else
          style::warning "Ignore this file: '${1}'"
        fi
      else
        tags+=("--set-tag=${tag}=${1}")
      fi
      ;;
  esac
  shift
done

if array::is_empty tracks; then
set_tag::usage
  style::error "You must specify at least one track"
  exit 1
fi

metaflac "${tags[@]}" "${tracks[@]}"

