#!/bin/bash

declare -r DIRNAME="${0%\/*}"
. "${DIRNAME}/../../helpers/functions"
. "${DIRNAME}/../../helpers/array"

# metadata_dict, infile, ...tags_to_read
function read_tags () {
  local -n metadata=$1
  local -r infile="${2}"
  local -a tags
  local line
  shift 2
  while [ $# -ne 0 ]; do
    tags+=("--show-tag=${1}")
    shift
  done
  while read -e line; do
    if [[ "${line}" =~ ^([A-Za-z]+)=(.+)$ ]]; then
      metadata["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
    fi
  done < <(metaflac ${tags[@]} "${infile}")
}

# directory
function format_names () {
  local -A infos
  local -a tracks
  local f filename
  for f in "${1}"/*.flac; do
    tracks+=("${f}")
  done
  if array::is_empty tracks; then
    echo "Not flac files found" >&2
    return 1
  fi
  for f in "${tracks[@]}"; do
    read_tags infos "${f}" TRACKNUMBER TITLE ALBUM DATE TRACKTOTAL
    printf -v filename "%s/%02d - %s.flac" "${1}" "${infos[TRACKNUMBER]}" "${infos[TITLE]}"
    mv "${f}" "${filename}"
    echo "${filename}" >> "00 - ${infos[ALBUM]}.m3u"
  done
  if [ -z "${infos[TRACKTOTAL]}" ]; then
    metaflac --set-tag=TRACKTOTAL="${#tracks[@]}" "${1}"/*.flac
  fi
  mv "${1}" "${infos[DATE]} ${infos[ALBUM]}"
}

# exit_code
if [ $# -ne 1 ]; then
  print_usage "DIRECTORY" >&2
  exit 1
fi

if [ ! -d "${1}" ]; then
  echo "DIRECTORY must be a directory" >&2
  exit 1
fi
format_names "${1}"
exit
