#!/bin/bash

declare -r HELPERS_DIR="${0%\/*}/../../helpers"
. "${HELPERS_DIR}/array"
. "${HELPERS_DIR}/style"
. "${HELPERS_DIR}/help"
. "${HELPERS_DIR}/parallel"

# metadata_dict, infile, ...tags_to_read
function format_flac::read_tags () {
  local -n metadata=$1
  local -r infile="${2}"
  local -a tags
  local -i i=0
  local line tag key
  shift 2
  array::clean metadata
  while [ $# -ne 0 ]; do
    tags+=("--show-tag=${1}")
    shift
  done
  while read -e line; do
    if [[ "${line}" =~ ^([A-Za-z]+)=(.+)$ ]]; then
      i=0
      tag="${BASH_REMATCH[1]}"
      # In case thes keys have duplicates (don't try this at home, it's not clean at all)
      while [ -n "${metadata[${tag}]}" ]; do
        (( i++ ))
        tag="${BASH_REMATCH[1]}${i}"
      done
      metadata["${tag}"]="${BASH_REMATCH[2]}"
    fi
  done < <(metaflac "${tags[@]}" "${infile}")
  if [ -n "${metadata[ARTIST1]}" ]; then
    if key="$(array::find_key metadata "${metadata[ALBUMARTIST]}")"; then
      metadata["${key}"]="${metadata[ARTIST]}"
      metadata["ARTIST"]="${metadata[ALBUMARTIST]}"
    fi
  fi
}

# tag
function format_flac::get_tag_format () {
  case "${1}" in
    TRACKNUMBER)
      echo "%02d"
      ;;
    DISCNUMBER)
      echo "%d"
      ;;
    *)
      echo "%s"
      ;;
  esac
}

# metadata_dict, template
function format_flac::format_from_template () {
  local -n metadata=$1
  local -a values
  local -i i
  local rematch="${2}" result="${2%%\%*}"
  while [[ "${rematch}" =~ %([A-Z]+)(.*)$ ]]; do
    if [ "${BASH_REMATCH[1]}" = "ARTISTS" ]; then
      i=1
      result+="$(format_flac::get_tag_format ARTIST)"
      values+=("${metadata[ARTIST${i}]}")
      (( i++ ))
      while [ -n "${metadata[ARTIST${i}]}" ]; do
        result+=", $(format_flac::get_tag_format ARTIST)"
        values+=("${metadata[ARTIST${i}]}")
        (( i++ ))
      done
    else
      result+="$(format_flac::get_tag_format "${BASH_REMATCH[1]}")"
      values+=("${metadata[${BASH_REMATCH[1]}]}")
    fi
    result+="${BASH_REMATCH[2]%%\%*}"
    rematch="${BASH_REMATCH[2]}"
  done
  # Remove invalid chars (Unix / Windows)
  # FIX: If quotes are not omitted, they are duplicated.
  printf -v result "${result}" "${values[@]//[<>:\"\/\\|\?\*\']/_}"

  # Limit the result to 125 characters (half of the maximum char limit for filename)
  echo "${result:0:125}"
}

# tracks_directory,
# [track='%TRACKNUMBER - %TITLE'],
# [playlist='00 - %ALBUM'],
# [directory='%DATE %ALBUM']
# [featuring='%TRACKNUMBER - %TITLE (feat. %ARTISTS)']
function format_flac::format_names () {
  local -r track="${2:-%TRACKNUMBER - %TITLE}"
  local -r playlist="${3:-00 - %ALBUM}"
  local -r directory="${4:-%DATE %ALBUM}"
  local -r featuring="${5:-%TRACKNUMBER - %TITLE (feat. %ARTISTS)}"
  local -A infos tracks
  local f filename

  # By default bash return the blob if there aren't any match
  # FIX: Why do I have an echo?
  if [[ "$(echo "${1}"/*.flac)" =~ \*\.flac$ ]]; then
    style::error "Not flac files found in directory: '${1}'" >&2
    return 1
  fi

  # Renames tracks from given template
  for f in "${1}"/*.flac; do
    format_flac::read_tags infos "${f}" TRACKNUMBER TITLE ALBUM DATE TRACKTOTAL ARTIST DISCNUMBER
    # printf can interpret TRACKNUMBER as an octal number if it's begin by 0
    if [[ "${infos[TRACKNUMBER]}" =~ ^0([0-9]+)$ ]]; then
      infos[TRACKNUMBER]="${BASH_REMATCH[1]}"
    fi
    if [ -n "${infos[ARTIST1]}" ]; then
      filename="$(format_flac::format_from_template infos "${featuring}").flac"
    else
      filename="$(format_flac::format_from_template infos "${track}").flac"
    fi
    tracks["${infos[TRACKNUMBER]}"]="${filename}"
    mv "${f}" "${1}/${filename}"
  done

  # Generate playlist in order
  rm -f "${1}"/*.m3u
  filename="${1}/$(format_flac::format_from_template infos "${playlist}").m3u"
  for f in "${tracks[@]}"; do
    echo "${f}" >> "${filename}"
  done

  # Rename the tracks directory
  mv "${1}" "$(format_flac::format_from_template infos "${directory}")"
}

function format_flac::usage () {
  help::usage "-t TRACK" "-p PLAYLIST" "-d DIRECTORY" "-f FEATURING" "FLAC_DIRECTORY" "FLAC_DIRECTORY ..."
}

function format_flac::help () {
  format_flac::usage
  help::description "Format flac filesname."
  help::positional_argument "FLAC_DIRECTORY" "directory with flac file on it"
  help::optional
  help::optional_help
  help::optional_argument "-t" "--track" var="TRACK" desc="format of track filename" default="%TRACKNUMBER - %TITLE"
  help::optional_argument "-p" "--playlist" var="PLAYLIST" desc="format of playlist filename" default="00 - %ALBUM"
  help::optional_argument "-d" "--directory" var="DIRECTORY" desc="format of directory filename" default="%DATE %ALBUM"
  help::optional_argument "-f" "--featuring" var="FEATURING" desc="the format of the track, if the track has more than one artist" default="%TRACKNUMBER - %TITLE (feat. %ARTISTS)"
}

if [ $# -lt 1 ]; then
  format_flac::usage >&2
  style::error "The following arguments are required: FLAC_DIRECTORY" >&2
  exit 1
fi

declare -a directories cmd
declare -i code errno=0
declare track playlist directory featuring
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
    -f | --featuring)
      featuring="${2}"
      ;;
    -h | --help)
      format_flac::help
      exit 0
      ;;
    *)
      if [ -d "${1}" ]; then
        directories+=("${1}")
      else
        style::warning "Ignore this argument, it's not a directory: '${1}'" >&2
      fi
      ;;
  esac
  shift
done

parallel::init
cmd[0]="format_flac::format_names"
for d in "${directories[@]}"; do
  cmd[1]="${d}"
  cmd[2]="${track}"
  cmd[3]="${playlist}"
  cmd[4]="${directory}"
  cmd[5]="${featuring}"
  parallel::run cmd
  #format_flac::format_names "${d}" "${track}" "${playlist}" "${directory}" "${featuring}"
done
wait
