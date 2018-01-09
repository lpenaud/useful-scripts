#!/bin/bash

#  dev.sh
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

function help {
    echo "This script must be run as root"
    echo "'start' services"
    echo "'stop' services"
}

if  [ $# -eq 1 ]
then
    if [ $1 = "start" ] || [ $1 = "stop" ]
    then
        if [ $EUID -ne 0 ]
        then
            echo "This script must be run as root"
        else
            /etc/init.d/nginx $1
            /etc/init.d/mysql $1
            /etc/init.d/php7.0-fpm $1
	    service mongod $1
        fi
    else
        help
    fi
else
    help
fi
