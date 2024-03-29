#!/bin/bash
# Backup nextcloud
#

source "$(dirname "${BASH_SOURCE}")/../helpers/base.sh"
base::import "helpers/argsparse.sh"
base::import "server/nextcloud.sh"
base::import "helpers/functions"

function usage () {
  print_usage "[-c CONFIG] [-o BACKUP] [-b OCC]"
  exit 1
}

function get_string () {
  sudo -u http grep "${1}" "${CONFIG}" | cut -d "'" -f 4
}

function mysql_dump () {
  local cnf="${DIRNAME}/.my.cnf"
  echo "[mysqldump]" > "${cnf}"
  echo "user=${1}" >> "${cnf}"
  echo "password=${2}" >> "${cnf}"
  local cmd=("mysqldump" "--defaults-file=${cnf}" "--single-transaction" "${3}" ">" "${4}")
  mysqldump --defaults-file="${cnf}" --single-transaction "${3}" ">" "${4}"
  rm "'${cnf}'"
}

function db_dump () {
  local dbtype="$(get_string dbtype)"
  assert_equals "mysql" "${dbtype}" "Dump from ${dbtype} is not implemented yet."
  local dbuser="$(get_string dbuser)"
  local dbpassword="$(get_string dbpassword)"
  local dbname="$(get_string dbname)"
  local dbbackup="${BACKUP}/${dbtype}/$(date "+%d-%m-%Y").sql"
  mkdir -p "$(dirname "${dbbackup}")"
  mysql_dump "${dbuser}" "${dbpassword}" "${dbname}" "${dbbackup}"
}

function rsync_backup () {
  local src="$(get_string "${1}")"
  assert_not_null "${src}" "'${1}' cannot be null"
  rsync -avx "${src}" "${BACKUP}/${2}"
}

codes=()
while [ $# -ne 0 ]; do
  case "${1}" in
    -c)
      if is_flag "${2}"; then
        codes+=(1)
      else
        CONFIG="${2}"
        shift
      fi
      ;;
    -o)
      if is_flag "${2}"; then
        codes+=(1)
      else
        BACKUP="${2}"
        shift
      fi
      ;;
    -b)
      if is_flag "${2}"; then
        codes+=(1)
      else
        OCC="${2}"
        shift
      fi
      ;;
    *)
      echo "Unknow option '${1}'" >&2
      ;;
  esac
  shift
done

CONFIG="$(argsparse::infile "${CONFIG}")"
codes+=($?)
if [ -z "${BACKUP}" ]; then
  codes+=(1)
fi
OCC="$(argsparse::infile "${OCC}")"
codes+=($?)

if has_error $codes; then
  usage
fi

theme="$(get_string theme)"
if [ -n "${theme}" ]; then
  assert_not_null "${THEME}"
fi
mkdir -p "${BACKUP}"
sudo -u http php "${OCC}" maintenance:mode --on
db_dump &
rsync_backup datadirectory data &
wait
sudo -u http php "${OCC}" maintenance:mode --on
