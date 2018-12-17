#!/bin/sh

FILE="$(realpath $0)"
DIR="$(dirname _FILE)"

tmpfolder="/tmp/lpenaud-software"
aur_root="https://aur.archlinux.org"

sudo pacman -Syu - < lists/pkglist.txt

"${DIR}/../../git/git-config.sh"

mkdir tmpfolder

for pkg in $(cat lists/aurpkglist.txt)
do
    origin="$aur_root/$pkg.git"
    dst="$tmpfolder/$pkg"

    git clone $origin $dst
    cd $dst
    makepkg -si

    cd $OLDPWD
    rm -rf $dst
done

rmdir $tmpfolder

