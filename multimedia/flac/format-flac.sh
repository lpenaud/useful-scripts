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

# tag
function get_tag_format () {
  case "${1}" in
    TRACKNUMBER)
      echo -n "%02d"
      ;;
    *)
      echo -n "%s"
      ;;
  esac
}

# metadata_dict, template
function format_from_template () {
  local -n metadata=$1
  local -a values
  local rematch="${2}" result
  while [[ "${rematch}" =~ %([A-Z]+)(.*)$ ]]; do
    result+="$(get_tag_format "${BASH_REMATCH[1]}")${BASH_REMATCH[2]%%\%*}"
    values+=("${metadata[${BASH_REMATCH[1]}]}")
    rematch="${BASH_REMATCH[2]}"
  done
  printf "${result}.flac" "${values[@]}"
}

# directory, [template='%TRACKNUMBER - %TITLE']
function format_names () {
  local -A infos
  local -a tracks
  local f filename template="${2:-%TRACKNUMBER - %TITLE}"
  for f in "${1}"/*.flac; do
    tracks+=("${f}")
  done
  if array::is_empty tracks; then
    echo "Not flac files found" >&2
    return 1
  fi
  rm -f "${1}"/*.m3u
  for f in "${tracks[@]}"; do
    read_tags infos "${f}" TRACKNUMBER TITLE ALBUM DATE TRACKTOTAL ARTIST
    # printf can interpret TRACKNUMBER as an octal number
    if [[ "${infos[TRACKNUMBER]}" =~ ^0([0-9]+)$ ]]; then
      infos[TRACKNUMBER]="${BASH_REMATCH[1]}"
    fi
    filename="$(format_from_template infos "${template}")"
    mv "${f}" "${1}/${filename}"
    echo "${filename}" >> "${1}/00 - ${infos[ALBUM]}.m3u"
  done
  if [ -z "${infos[TRACKTOTAL]}" ]; then
    metaflac --set-tag=TRACKTOTAL="${#tracks[@]}" "${1}"/*.flac
  fi
  mv "${1}" "${infos[DATE]} ${infos[ALBUM]}"
}

# exit_code
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  print_usage "DIRECTORY [FORMAT='%TRACKNUMBER - %TITLE']" >&2
  exit 1
fi

if [ ! -d "${1}" ]; then
  echo "DIRECTORY must be a directory" >&2
  exit 1
fi
format_names "${1}" "${2}"
exit
