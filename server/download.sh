#!/bin/bash

declare -a urls files
declare -i n timeout=1
declare url

function add_url () {
  if [[ "${1}" =~ ^https? ]]; then
    urls+=("${1}")
    return 0
  fi
  echo "Ignore '${1}'" >&2
  return 1
}

function vpn_download () {
  (( n++ ))
  sudo protonvpn c -r
  plowdown -t "${timeout}" "${1}"
  # If the timeout reached
  if [ $? -eq 5 ] && [ $n -lt 3 ]; then
    # Retry with other connexion
    vpn_download "${1}"
  fi
}

while [ $# -ne 0 ]; do
  n=1
  case "${1}"
    -t | --timeout)
      timeout="${2}"
      (( n++ ))
      ;;
    *)
      if [ -f "${1}" ]; then
        while read -e url; do
          add_url "${url}"
        done < "${1}"
      else
        add_url "${1}" 
      fi
      ;;
  esac
  shift $n
done

if [ "${#urls[@]}" -eq 0 ]; then
  echo "ERROR: No url provided" >&2
  echo "Usage: ${0} [URL...] [FILE...]" >&2
  exit 1
fi

for url in "${urls[@]}"; do
  n=0
  vpn_download "${url}"
done
