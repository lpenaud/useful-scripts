
if [ -z "${USEFUL_SCRIPTS_DIR}" ]; then
    declare -r USEFUL_SCRIPTS_DIR="$(realpath -L "$(dirname "${BASH_SOURCE}")/..")"
fi

#######################################
# Import file from the directory of current main script.
# Globals:
#   DIRNAME
# Arguments:
#   Relative path to file
# Outputs:
#   Write error message if the file doesn't exit to stderr.
# Returns:
#   1 if the file doesn't exit.
#######################################
function base::import () {
  local file="${USEFUL_SCRIPTS_DIR}/${1}"
  if [ ! -f "${file}" ]; then
    echo "Error: Cannot import '${file}'" >&2
    exit 1
  fi
  source "${file}"
}
