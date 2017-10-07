#!/bin/bash

#  install-software.sh
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

cd $HOME

removeSoft=`cat remove-software.txt`
installSoft=`cat install-software.txt`
logFile="$HOME/Documents/log.out"

echo "Would you like a log file ?"
read -p "[y/N]" keepLog

for soft in $removeSoft
do
	echo "Removing $soft..."
	sudo apt-get remove $soft -y >> $logFile
done

echo "Executing autoremove..."
sudo apt-get autoremove -y >> $logFile

echo "Adding firefox-aurora repository..."
sudo add-apt-repository ppa:ubuntu-mozilla-daily/firefox-aurora -y >> $logFile

echo "Updating all repositories..."
sudo apt-get update >> $logFile

echo "Upgrading all software..."
sudo apt-get upgrade -y >> $logFile

cd $HOME/Téléchargements

for soft in $installSoft
do
	echo "Installing $soft..."
		case $soft in
			"gitKraken")
				wget -O $HOME/Téléchargements/$soft.deb https://release.gitkraken.com/linux/gitkraken-amd64.deb >> $logFile
				sudo apt-get install ./$soft.deb -y >> $logFile
				;;
			"vscode")
				wget -O $HOME/Téléchargements/$soft.deb https://go.microsoft.com/fwlink/?LinkID=760868 >> $logFile
				sudo apt-get install ./$soft.deb -y >> $logFile
				;;
			*)
				sudo apt-get install $soft -y >> $logFile
				;;
		esac
done


if [ $keepLog = 'y' ] || [ $keepLog = 'Y' ]
then
	echo "Path of log file : $logFile"
else
	rm $logFile
fi

