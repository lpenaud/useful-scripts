#!/bin/bash

declare -r DIRNAME="${0%\/*}"
. "${DIRNAME}/../functions"

# track
function get_picture_mime_type () {
  local line
  while read -e line; do
    if [[ "${line}" =~ ^[[:space:]]*MIME[[:space:]]type:[[:space:]](.*)$ ]]; then
      echo "${BASH_REMATCH[1]}"
      return 0
    fi
  done < <(metaflac --list --block-type=PICTURE "${1}" | head)
  echo "The track ${1} haven't picture" >&2
  return 1
}

# track, filename=cover
function export_picture () {
  local filename="$(get_dirname "${1}")/${2:-cover}"
  local -r mimetype="$(get_picture_mime_type "${1}")"
  if [ $? -ne 0 ]; then
    return 1
  fi
  case "${mimetype}" in
    "image/jpeg")
      filename+=".jpg"
      ;;
    "image/png")
      filename+=".png"
      ;;
    *)
      echo "Unknow mime type '${mimetype}'" >&2
      return 1
      ;;
  esac
  metaflac --export-picture-to="${filename}" "${1}"
}

if [ $# -lt 1 ] && [ $# -gt 2 ]; then
  print_usage "TRACK [FILENAME=cover]" >&2
  exit 1
fi

if [ ! -f "${1}" ] && [[ ! "${1}" =~ \.flac$ ]]; then
  echo "TRACK must be a flac file" >&2
  exit 1
fi
export_picture "${1}" "${2}"
exit
