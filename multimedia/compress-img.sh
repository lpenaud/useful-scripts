#!/bin/bash
# 
# Compress picture
#TODO: Webp support
#TODO: Add -resize WxH
#TODO: Color?

DIRNAME="$(dirname ${0})"
. "${DIRNAME}/../helpers/functions"

function compress () {
  local ext="$(get_extension "${1}")"
  local dst="${2}.jpg"
  local force="n"
  if [[ ! "${ext,,}" =~ (png|jpe{0,1}g|webp|gif)$ ]]; then
    echo "Warning: Ignore '${1}'" >&2
    return 1
  fi
  if [ -e "${dst}" ]; then
    read -p "Overwrite '${dst}' [y/N]? " force
    if [ ! "${force,,}" = "y" ]; then
      echo "Warning: Ignore '${1}'" >&2
      return 2
    fi
  fi
  log_exec convert -sampling-factor 4:2:0 -strip -quality 85 -interlace JPEG -colorspace sRGB "${1}" "${dst}"
}

infiles=()
while [ $# -ne 0 ]; do
  case "${1}" in
    -p | --prefix)
      prefix="${2}"
      shift
      ;;
    -o | --outdir)
      outdir="${2}"
      shift
      ;;
    *)
      # TODO: Directory test
      infiles+=("$(parse_input_file "${1}")")
      if [ $? -ne 0 ]; then
        error=true
      fi
      ;;
  esac
  shift
done

if [ ${#infiles[@]} -eq 0 ]; then
  print_usage "[(-o --outdir) OUTDIR] [(-p --prefix) PREFIX] <infile> [...infiles]"
  exit 1
fi
if [ -n "${error}" ]; then
  exit 1
fi

if [ -z "${outdir}" ]; then
  for infile in "${infiles[@]}"; do
    compress "${infile}" "$(get_filename "${infile}")${prefix}"
  done
else
  log_exec mkdir -p "$(get_dirname "${outdir}")"
  for infile in "${infiles[@]}"; do
    compress "${infile}" "${outdir}/$(get_basename "${infile}" true)${prefix}"
  done
fi
