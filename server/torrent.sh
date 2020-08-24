#!/bin/bash
# Activate protonvpn and transmisssion torrent client
#

declare -r FILENAME="$(realpath -P "${0}")"
declare -r DIRNAME="${__FILENAME%\/*}"
. "${DIRNAME}/../helpers/functions"

function usage () {
  print_usage "start" "stop username:password" "edit"
  exit 1
}

function start () {
  sudo protonvpn c --p2p
  transmission-daemon
}

function stop () {
  assert_not_null "${1}" "Usage: ${0} stop username:password"
  transmission-remote --auth "${1}" --exit
  sudo protonvpn d
}

function edit () {
  local cmd=("$(get_editor)" "${HOME}/.config/transmission-daemon/settings.json")
  "${cmd[@]}"
}

case "${1}" in
  start)
    start
    ;;
  stop)
    stop "${2}"
    ;;
  edit)
    edit
    ;;
  *)
    usage
    ;;
esac
