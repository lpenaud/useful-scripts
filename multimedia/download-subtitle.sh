#!/bin/bash
# Download subtitles
# Usally from www.sous-titres.eu

declare -r HELPERS_DIR="${0%\/*}/../helpers"
. "${HELPERS_DIR}/functions"
. "${HELPERS_DIR}/style"

declare -a subtitles urls
declare line

function main () {
  local -r tempzip="$(mktemp)"
  local -a subtitles
  local line subtitle

  # Download a ZIP archive
  wget --quiet -O "${tempzip}" "${1}"

  # Get all subtitles in the ZIP archive
  while read -e line; do
    if [[ "${line}" =~ [0-9]+:[0-9]+[[:space:]]*(.+)$ ]]; then
      subtitles+=("${BASH_REMATCH[1]}")
    fi
  done < <(unzip -l "${tempzip}")

  # User have to select one subtitle
  PS3="Please enter your choice: "
  select subtitle in "${subtitles[@]}"; do
    if [[ ! "${REPLY}" =~ ^[0-9]+$ ]] || [ "${REPLY}" -gt "${#subtitles[@]}" ] || [ "${REPLY}" -lt 0 ]; then
      echo "'${REPLY}' is not a valid choice" >&2
    else
      break
    fi
  done

  # Extract the subtitle selected
  # Convert the CP1252 encoding to UTF-8 for better convenience
  unzip -p "${tempzip}" "${subtitle}" | iconv -o "${subtitle}" -f CP1252 -t UTF-8

  # Remove the ZIP archive downloaded at the begining
  rm "${tempzip}"
}

function usage () {
  print_usage "[(-f --file) FILE] [...URLS]" \
    "URL [...URLS]"
}

while [ $# -ne 0 ]; do
  case "${1}" in
    -f | --file)
      if [ "${2}" = '-' ]; then
        while read -e line; do
          urls+=("${line}")
        done <&0
      elif [ -f "${2}" ]; then
        while read -e line; do
          urls+=("${line}")
        done < <(cat "${2}")
      else
        style::error "The file '${2}' doesn't exist"
        usage
        exit 1
      fi
      shift
      ;;
    *)
      urls+=("${1}")
      ;;
  esac
  shift
done

if [ "${#urls[@]}" -eq 0 ]; then
  style::error "You must provided urls"
  usage
  exit 1
fi

for line in "${urls[@]}"; do
  main "${line}"
done

