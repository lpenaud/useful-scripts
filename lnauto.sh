#!/bin/sh

for file in $(ls)
do
    if [ -d $file ]
    then
        echo "Createn symbolic between $PWD/$file and $HOME/$file"
        ln -s $PWD/$file $HOME/$file
    fi
done
