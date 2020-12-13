#!/bin/bash

declare -r DIRNAME="${0%\/*}"
declare -i i=1
while [ $# -ne 0 ]; do
  "${DIRNAME}/set-tags.sh" -s TRACKNUMBER "${i}" "${1}"
  (( i++ ))
  shift
done
