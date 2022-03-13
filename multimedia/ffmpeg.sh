#!/bin/bash
# Convert h265 to h264 8 bits, copy all other streams.
#

source "$(dirname "${BASH_SOURCE}")/../helpers/base.sh"
base::import "helpers/argsparse.sh"
base::import "helpers/functions"

if [ $# -ne 2 ]; then
    print_usage "<infile> <outfile>"
    exit 1
fi

infile="$(argparse::infile "${1}")"
assert_code
outfile="$(argparse::outfile "${2}" ".mkv")"
ffmpeg -i "${1}" \
    -c:v libx264 \
    -preset veryfast \
    -crf 24 \
    -vf format=yuv420p \
    -c:a copy \
    -c:s copy \
    -map 0 \
    "${outfile}"
