#!/bin/sh

#  save-data.sh
#  
#  Copyright 2017 Loïc Penaud <loic.penaud@lilo.fr>
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#  
#

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
