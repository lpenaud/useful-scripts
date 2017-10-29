#!/bin/sh

checkRight=true

if [ $# -ge 2 ]; then

    if [ ! -r $1 ]; then
        echo "You must have the right to read on the folder to backup"
        checkRight=false
    fi

    if [ ! -w $2 ]; then
        echo "You must have the right to write to the folder where the backups will be created"
        checkRight=false
    fi

    if [ $checkRight = 'true' ]; then
        tarFile=$2/archive.`date "+%d.%m.%Y.%Hh%M"`.tar.gz
        listedIncremental=$2/save.list
        backupsFile=$2/backups.7z
        tar z --create --file=$tarFile --listed-incremental=$listedIncremental $1
    fi

else
    echo "This script requires at least 2 arguments"
    echo "$0 <folder to backup> <folder to write the backups>"
fi
