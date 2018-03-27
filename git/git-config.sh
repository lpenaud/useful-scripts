#!/bin/sh

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`
cp --verbose $SCRIPTPATH/.gitconfig $HOME/
