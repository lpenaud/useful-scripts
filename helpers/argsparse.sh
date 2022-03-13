
base::import "helpers/boolean.sh"

#######################################
# Parse an output file and create subdirectories if any.
# Arguments:
#   Output file
#   Required suffix of the output file
#   Source file if any (in case where output file is a directory)
# Output:
#   Write the formatted path to stdout.
#######################################
function argparse::outfile () {
  local -r dirname="$(dirname "${1}")"
  local -r basename="$(basename "${1}" "${2}")"
  if [ $# -eq 2 ] && [ ! "${#1}" -eq "${#basename}" ]; then
    printf "Error: output file must be a '%s' file but found '%s'" \
      "${2}" \
      "${1}" >&2
  fi
  mkdir -p "${dirname}"
  realpath -a -s "${dirname}/${basename}"
}

#######################################
# Parse an input file, check if it can be overwritten.
# Arguments:
#   Filename, path
# Output:
#   Write the formatted path to stdout.
#   Write an error if the file is not valid to stderr.
# Returns:
#   0 if the file exists, otherwise 1.
#######################################
function argparse::infile () {
  local -r dirname="$(dirname "${1}")"
  local -r basename="$(basename "${1}" "${2}")"
  local -r infile="$(realpath -a -s "${dirname}/${basename}")"
  local bool=""
  if [ $# -eq 2 ] && [ ! "${#1}" -eq "${#basename}" ]; then
    printf "Error: input file must be a '%s' file but found '%s'" \
      "${2}" \
      "${1}" >&2
  fi
  mkdir -p "${dirname}"
  if [ -f "${infile}" ] && ! boolean::affirmation; then
    printf "Error: input file '%s' cannot be overwritten" \
      "${infile}">&2
    return 1
  fi
  return 0
}
