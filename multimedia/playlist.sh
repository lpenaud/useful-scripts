#!/bin/bash

declare -r DIRNAME="$(dirname "${0}")"
. "${DIRNAME}/../helpers/functions"
import "../helpers/parallel"

function usage () {
  print_usage "[...album directories]"
  exit 1
}

function main () {
  local track folder m3u
  local -i i=0
  assert_dir "${1}"
  folder="$(get_basename "${1}")"
  # Get album name (YYYY <album name>)
  m3u="${1}/00 - ${folder:5}.m3u"
  rm -f "${m3u}"
  for track in "${1}"/*.flac; do
    echo "$(get_basename "${track}")" >> "${m3u}"
    (( i++ ))
  done
  echo "Filename: '${m3u}'"
  echo "Number of tracks: ${i}"
}

declare -a cmd
parallel::init
cmd+=(main)
while [ $# -ne 0 ]; do
  cmd[1]="${1}"
  parallel::run cmd
  shift
done
wait
