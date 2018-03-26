#!/bin/bash

#  software.sh
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

function eco {
	clear
	echo $1
}

if [ $EUID -ne 0 ]
then
	echo "This script must be run as root"
	exit
fi

removeSoft=`cat remove-software.txt`
installSoft=`cat install-software.txt`
installNpm=`cat install-npm.txt`

eco "Which nodejs version do you want to install ?"
echo "Release calendar : https://github.com/nodejs/Release#release-schedule1"
echo "Example v8"
read -p "v" nodejsVersion

for soft in $removeSoft
do
	eco "Removing $soft..."
	apt-get remove $soft -y
done

eco "Installing curl..."
apt-get install curl -y

eco "Adding firefox-aurora repository..."
add-apt-repository ppa:ubuntu-mozilla-daily/firefox-aurora -y

eco "Adding nextcloud repository..."
add-apt-repository ppa:nextcloud-devs/client -y

eco "Adding nginx stable repository..."
add-apt-repository ppa:nginx/stable -y

eco "Adding Node.js v.$nodejsVersion.x repository..."
curl -sL https://deb.nodesource.com/setup_$nodejsVersion.x | -E bash -

eco "Updating all repositories..."
apt-get update

eco "Upgrading all software..."
apt-get upgrade -y

cd $HOME/Téléchargements

for soft in $installSoft
do
	eco "Installing $soft..."
		case $soft in
			"vscode"|"atom"|"slack"|"skype")
				snap install $soft --classic
				;;
			"gitkraken"|"discord")
				snap install $soft
<<<<<<< HEAD
=======
				;;
			"brave")
				snap install brave --beta
				;;
>>>>>>> 8b73f9e... Update software.sh
			*)
				apt-get install $soft -y
				;;
		esac
done

eco "Executing autoremove..."
apt-get autoremove -y

cd $OLDPWD

mysql_secure_installation
