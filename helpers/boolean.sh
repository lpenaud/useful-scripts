
declare -r -l TRUE="y" FALSE="n"

function boolean::confirm () {
  local -r prompt="[${TRUE}/${FALSE^^}] "
  local -l bool
  read -p "${prompt}" bool
  until [ "${bool}" = "${TRUE}" ] || [ "${bool}" = "${FALSE}" ] || [ -z "${bool}" ]; do
    printf "Invalid response: '%s'\n%s" \
      "${bool}" \
      "${prompt}" >&2
    read bool
  done
  if [ "${bool}" = "${TRUE}" ]; then
    return 0
  fi
  return 1
}

function boolean::affirmation () {
  local bool
  read -p "[${TRUE^^}/${FALSE}] " bool
  if [ "${bool}" = "${FALSE}" ]; then
    return 1
  fi
  return 0
}
