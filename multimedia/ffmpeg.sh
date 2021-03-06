#!/bin/bash
# Convert h265 to h264 8 bits, copy all other streams.
#

DIRNAME="$(dirname ${0})"
DEBUG=true
. "${DIRNAME}/../helpers/functions"

if [ $# -ne 2 ]; then
    print_usage "<infile> <outfile>"
    exit 1
fi

infile="$(parse_input_file "${1}")"
assert_code
outfile="$(parse_output_file "${2}" ".mkv" "${infile}")"
log_exec ffmpeg -i "${1}" -c:v libx264 -preset veryfast -crf 24 -vf format=yuv420p -c:a copy -c:s copy -map 0 "${outfile}"
