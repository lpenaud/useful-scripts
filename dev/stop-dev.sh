#!/bin/bash

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
        fi
    else
        help
    fi
else
    help
fi
