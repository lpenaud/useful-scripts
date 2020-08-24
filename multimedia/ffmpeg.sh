#!/bin/bash
# Convert h265 to h264 8 bits, copy all other streams.
#

declare -r FILENAME="$(realpath -P "${0}")"
declare -r DIRNAME="${FILENAME%\/*}"
declare -r DEBUG=true
. "${DIRNAME}/../helpers/functions"

if [ $# -ne 2 ]; then
  print_usage "<infile> <outfile>"
  exit 1
fi

infile="$(parse_input_file "${1}")"
assert_code
outfile="$(parse_output_file "${2}" ".mkv" "${infile}")"
declare -a cmd
cmd=(ffmpeg -i "${1}" -c:v libx264 -preset veryfast -crf 24 -vf format=yuv420p -c:a copy -c:s copy -map 0 "${outfile}")
echo "${cmd[@]}" >&2
"${cmd[@]}"
