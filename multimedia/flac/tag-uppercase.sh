#!/bin/bash

declare -r DIRNAME="${0%\/*}"
. "${DIRNAME}/../../helpers/parallel"

# track
function main () {
  local -a remove_tags set_tags
  local -u tag
  local line
  while read -e line; do
    if [[ "${line}" =~ ^[[:space:]]*comment\[[0-9]+\]:[[:space:]]*(.+)=(.+)$ ]]; then
      tag="${BASH_REMATCH[1]}"
      remove_tags+=("--remove-tag=${tag}")
      set_tags+=("--set-tag=${tag}=${BASH_REMATCH[2]}")
    fi
  done < <(metaflac --list --block-type=VORBIS_COMMENT "${1}")
  metaflac "${remove_tags[@]}" "${set_tags[@]}" "${1}"
}

declare -a cmd=("main")
parallel::init
while [ $# -ne 0 ]; do
  cmd[1]="${1}"
  parallel::run cmd
  shift
done
wait
