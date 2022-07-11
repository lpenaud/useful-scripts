#!/bin/bash

declare -r FILENAME="$(realpath "${BASH_SOURCE[0]}")"
declare -r DIRNAME="$(dirname "${FILENAME}")"
cp --verbose "${DIRNAME}/.gitconfig" "${HOME}/.gitconfig"

cat >> ~/.bashrc <<EOF
if [ -f "${DIRNAME}/bash-git-prompt/gitprompt.sh" ]; then
    GIT_PROMPT_ONLY_IN_REPO=1
    source "${DIRNAME}/bash-git-prompt/gitprompt.sh"
fi
EOF
