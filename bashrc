BOLD="\[$(tput bold)\]"
RED="\[$(tput setaf 1)\]"
GREEN="\[$(tput setaf 2)\]"
BLUE="\[$(tput setaf 6)\]"
RESET="\[$(tput sgr0)\]"

# Change prompt if root is the current user
if [[ ${EUID} == 0 ]] ; then
	PS1="[${BOLD}${RED}\u@\h${RESET}"
else
	PS1="[${BOLD}${GREEN}\u@\h${RESET}"
fi

PS1="${PS1} ${BLUE}\w${RESET}]\$"

unset BOLD RED GREEN RESET BLUE

# https://github.com/magicmonty/bash-git-prompt.git
if [ -e ~/.bash-git-prompt/gitprompt.sh ] ; then
	GIT_PROMPT_ONLY_IN_REPO=1
	source ~/.bash-git-prompt/gitprompt.sh
fi
