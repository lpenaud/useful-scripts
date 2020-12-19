#!/bin/bash

declare -r HELPERS_DIR="${0%\/*}/../../helpers"
. "${HELPERS_DIR}/style"
. "${HELPERS_DIR}/help"
. "${HELPERS_DIR}/array"
. "${HELPERS_DIR}/parallel"

declare -r DEFAULT_FILENAME="cover"

# track
function export_picture::main::get_picture_mime_type () {
  local line
  while read -e line; do
    if [[ "${line}" =~ ^[[:space:]]*MIME[[:space:]]type:[[:space:]](.*)$ ]]; then
      echo "${BASH_REMATCH[1]}"
      return 0
    fi
  done < <(metaflac --list --block-type=PICTURE "${1}" | head)
  style::error "The track '${1}' haven't picture" >&2
  return 1
}

function export_picture::usage () {
  help::usage "-f FILENAME" "TRACK" "TRACK ..."
}

function export_picture::help () {
  export_picture::usage
  help::description "Exports the cover image contained in a track in flac format." \
    "The cover image is exported in the same directory of the source track."
  help::positional_argument "TRACK" "a track in flac format with a cover image on it"
  help::optional
  help::optional_help
  help::optional_argument "-f" "--file" var="FILENAME" \
    desc="filename without extension of the cover image" default="${DEFAULT_FILENAME}"
}

# track, filename=cover
function export_picture::main () {
  local filename="$(dirname "${1}")/${2:-"${DEFAULT_FILENAME}"}"
  local -r mimetype="$(export_picture::main::get_picture_mime_type "${1}")"
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

declare -a tracks
declare filename
while [ $# -ne 0 ]; do
  case "${1}" in
    -f | --filename)
      filename="${2}"
      shift
      ;;
    -h | --help)
      export_picture::help
      exit 0
      ;;
    *)
      if [ -f "${1}" ] && [[ "${1}" =~ \.flac$ ]]; then
        tracks+=("${1}")
      else
        style::warning "Ignore this non flac file: '${1}'" >&2
      fi
      ;;
  esac
  shift
done

if array::is_empty tracks; then
  export_picture::usage >&2
  style::error "The following arguments are required: TRACK" >&2
  exit 1
fi

declare -a cmd
declare track
parallel::init
cmd[0]="export_picture::main"
cmd[2]="${filename}"
for track in "${tracks[@]}"; do
  cmd[1]="${track}"
  parallel::run cmd
done
exit
