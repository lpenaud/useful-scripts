#!/bin/bash
# 
# Compress picture
#TODO: Add -resize WxH
#TODO: Color?

readonly DIRNAME="$(dirname ${0})"
. "${DIRNAME}/../helpers/functions"
import "../helpers/infiles"
import "../helpers/parallel"

declare -a infiles

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
    -f | --force)
      force=y
      ;;
    --webp)
      webp=y
      ;;
    *)
      if [ -d "${1}" ]; then
        add_infiles infiles "${1}" "(png|jpe{0,1}g|gif)$"
      elif [ -f "${1}" ]; then
        infiles+=("${1}")
      else
        echo "Warning: '${1}' is not a file or directory" >&2
      fi
      ;;
  esac
  shift
done

if [ ${#infiles[@]} -eq 0 ]; then
  print_usage "[(-o --outdir) OUTDIR] [(-p --prefix) PREFIX] [(-f --force)] [--webp] <infile> [...infiles]"
  exit 1
fi
if [ -n "${error}" ]; then
  exit 1
fi

cmd=("convert" "-sampling-factor" "4:2:0" "-strip" "-quality" "85" "-colorspace" "sRGB")
if [ -n "${webp}" ]; then
  prefix="${prefix}.webp"
else
  prefix="${prefix}.jpg"
  cmd+=("-interlace" "JPEG")
fi

if [ -n "${outdir}" ]; then
  if [ -e "${outdir}" ]; then
    if [ ! -d "${outdir}" ]; then
      echo "Error: '${outdir}' already exists and it's not a directory" >&2
      exit 1
    fi
  else
    log_exec mkdir -p "${outdir}"  
  fi
else
  outdir="$(get_dirname "${infiles[0]}")"
fi

readonly SRC_INDEX="${#cmd[@]}"
readonly DEST_INDEX="$((SRC_INDEX + 1))"
parallel::init
if [ -n "${force}" ]; then
  for file in "${infiles[@]}"; do
    cmd[$SRC_INDEX]="${file}"
    cmd[$DEST_INDEX]="${outdir}/$(get_basename "${file}" y)${prefix}"
    parallel::run cmd
  done
else
  for file in "${infiles[@]}"; do
    cmd[$SRC_INDEX]="${file}"
    cmd[$DEST_INDEX]="${outdir}/$(get_basename "${file}" y)${prefix}"
    if overwrite "${cmd[$DEST_INDEX]}"; then
      parallel::run cmd
    fi
  done
fi
parallel::wait
