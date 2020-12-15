#!/bin/bash

declare -r HELPERS_DIR="${0%\/*}/../../helpers"
. "${HELPERS_DIR}/array"
. "${HELPERS_DIR}/help"

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
    DISCNUMBER)
      echo -n "%d"
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
  local rematch="${2}" result="${2%%\%*}"
  while [[ "${rematch}" =~ %([A-Z]+)(.*)$ ]]; do
    result+="$(get_tag_format "${BASH_REMATCH[1]}")${BASH_REMATCH[2]%%\%*}"
    values+=("${metadata[${BASH_REMATCH[1]}]}")
    rematch="${BASH_REMATCH[2]}"
  done
  printf "${result}" "${values[@]}"
}

# tracks_directory, [track='%TRACKNUMBER - %TITLE'], [playlist='00 - %ALBUM'], [directory='%DATE %ALBUM']
function format_names () {
  local -r track="${2:-%TRACKNUMBER - %TITLE}"
  local -r directory="${4:-%DATE %ALBUM}"
  local -r playlist="${3:-00 - %ALBUM}"
  local -A infos
  local -a tracks
  local f filename

  # By default bash return the blob if there aren't any match
  if [[ "${1}"/*.flac =~ \*\.flac$ ]]; then
    style::error "Not flac files found in directory: '${1}'" >&2
    return 1
  fi

  # Renames tracks from given template
  for f in "${tracks[@]}"; do
    read_tags infos "${f}" TRACKNUMBER TITLE ALBUM DATE TRACKTOTAL ARTIST DISCNUMBER
    # printf can interpret TRACKNUMBER as an octal number if it's begin by 0
    if [[ "${infos[TRACKNUMBER]}" =~ ^0([0-9]+)$ ]]; then
      infos[TRACKNUMBER]="${BASH_REMATCH[1]}"
    fi
    filename="$(format_from_template infos "${track}").flac"
    mv "${f}" "${1}/${filename}"
  done

  # Generate playlist from 
  rm -f "${1}"/*.m3u
  filename="${1}/$(format_from_template infos "${playlist}").m3u"
  for f in "${1}"/*.flac; do
    echo "${f##*/}" >> "${filename}"
  done

  # Set TRACKTOTAL tag if it's not set
  if [ -z "${infos[TRACKTOTAL]}" ]; then
    metaflac --set-tag=TRACKTOTAL="${#tracks[@]}" "${1}"/*.flac
  fi

  # Rename the tracks directory
  mv "${1}" "$(format_from_template infos "${directory}")"
}

function _usage () {
  help::usage "-t TRACK" "-p PLAYLIST" "-d DIRECTORY" "FLAC_DIRECTORY" "FLAC_DIRECTORY ..."
}

function _help () {
  _usage
  help::description "Format flac filesname."
  help::positional_argument "FLAC_DIRECTORY" "Directory with flac file in it."
  help::optional
  help::optional_argument "-h" "--help" "show this help message and exit"
  help::optional_argument "-t" "--track" "TRACK" "format of track filename" "%TRACKNUMBER - %TITLE"
  help::optional_argument "-p" "--playlist" "PLAYLIST" "format of playlist filename" "00 - %ALBUM"
  help::optional_argument "-d" "--directory" "DIRECTORY" "format of directory filename" "%DATE %ALBUM"
}

if [ $# -lt 1 ]; then
  _usage >&2
  exit 1
fi

declare -a directories
declare -i code errno=0
declare track playlist directory
while [ $# -ne 0 ]; do
  case "${1}" in
    -t | --track)
      track="${2}"
      shift
      ;;
    -p | --playlist)
      playlist="${2}"
      shift
      ;;
    -d | --directory)
      directory="${2}"
      shift
      ;;
    -h | --help)
      _help
      exit 0
      ;;
    *)
      if [ -d "${1}" ]; then
        directories+=("${1}")
      else
        echo "TRACKS_DIRECTORY '${1}' must be a directory" >&2
      fi
      ;;
  esac
  shift
done

for d in "${directories[@]}"; do
  format_names "${d}" "${track}" "${playlist}" "${directory}"
  code=$?
  if [ "${code}" -ne 0 ]; then
    errno="${code}"
  fi
done
exit "${errno}"

