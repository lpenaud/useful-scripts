#!/bin/bash


declare -a tags tracks
declare tag
while [ $# -ne 0 ]; do
  case "${1}" in
    -s | --set)
      tag="${2}"
      tags+=("--remove-tag=${tag}")
      shift
      ;;
    -a | --append)
      tag="${2}"
      shift
      ;;
    *)
      if [ -f "${1}" ]; then
        tracks+=("${1}")
      else
        tags+=("--set-tag=${tag}=${1}")
      fi
      ;;
  esac
  shift
done

metaflac "${tags[@]}" "${tracks[@]}"

