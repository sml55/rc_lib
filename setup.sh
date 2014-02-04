#!/bin/bash


#	this setup file crates symlinks from wherever itself is located to 
#	your homedirectory.
#
#	THIS WILL DESTROY ANY FILE IN ~/ WITH THE SAME NAME AS A FILE IN 
#	THE DIRECTORY setup.sh IS.
#
echo "----------------------------"
echo "i will overwrite this files:"
ls rc 
echo "please quit with ^c if you have a problem with that or proceed with enter"
echo "----------------------------"
read input

MYDIR=`pwd`
for i in `ls rc`
do
        echo "creating symlink for $i"
        cd ~/
        if [[ -h ".$i"  || -e ".$i" ]]
                then
                echo "$i exists, i am moving it to /tmp/${i}_backup"
                mv  ".$i /tmp/${i}_backup"
        fi
        ln -s $MYDIR/rc/$i ".$i"
        cd $MYDIR


done
