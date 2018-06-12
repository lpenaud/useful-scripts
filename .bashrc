#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

GREEN="\[$(tput setaf 2)\]"
RESET="\[$(tput sgr0)\]"
BLUE="\[$(tput setaf 6)\]"
alias ls='ls --color=auto'
PS1="[${GREEN}\u@\h ${BLUE}\w${RESET}]\$ "
