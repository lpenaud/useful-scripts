#!/bin/bash

declare -r DIRNAME="${0%\/*}"
. "${DIRNAME}/../../helpers/parallel"

# track
function main () {
  local line
  local -a tags
  local -u tag
  while read -e line; do
    if [[ "${line}" =~ ^[[:space:]]*comment\[[0-9]+\]:[[:space:]]*(.+)=(.+)$ ]]; then
      tag="${BASH_REMATCH[1]}"
      tags+=("--remove-tag=${tag}" "--set-tag=${tag}=${BASH_REMATCH[2]}")
    fi
  done < <(metaflac --list --block-type=VORBIS_COMMENT "${1}")
  metaflac ${tags[@]}
}

declare -a cmd=("main")
parallel::init
while [ $# -ne 0 ]; do
  cmd[1]="${1}"
  parallel::run cmd
  shift
done
wait
