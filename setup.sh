#!/bin/bash


#	this setup file crates symlinks from wherever itself is located to 
#	your homedirectory.
#
#	THIS WILL DESTROY ANY FILE IN ~/ WITH THE SAME NAME AS A FILE IN 
#	THE DIRECTORY setup.sh IS.
#
echo "----------------------------"
echo "i will overwrite this files:"
ls config 
echo "please quit with ^c if you have a problem with that or proceed with enter"
echo "use your .profile for machine specific configurations"
echo "----------------------------"
read input

MYDIR=`pwd`
for i in `ls config`
do
        echo "creating symlink for $i"
        cd ~/.config/
        if [[ -h "$i"  || -e "$i" ]]
                then
                echo "$i exists, removing....."
                rm  "$i"
        fi
        ln -s $MYDIR/config/$i "$i"
        cd $MYDIR


done

echo "----------------------------"
echo "i will overwrite this files:"
ls rc
echo "please quit with ^c if you have a problem with that or proceed with enter"
echo "use your .profile for machine specific configurations since i will not overwrite it"
echo "----------------------------"
read input

MYDIR=`pwd`
for i in `ls rc`
do
        echo "creating symlink for $i"
        cd ~/
        if [[ -h ".$i"  || -e ".$i" ]]
                then
                echo "$i exists, removing....."
                rm  ".$i"
        fi
        ln -s $MYDIR/rc/$i ".$i"
        cd $MYDIR


done
echo "----------------------------"
echo "i will overwrite this files:"
ls tools 
echo "please quit with ^c if you have a problem with that or proceed with enter"
echo "use your .profile for machine specific configurations"
echo "----------------------------"
read input


MYDIR=`pwd`
for i in `ls tools`
do
        echo "creating symlink for $i"
        cd ~/
        if [[ -h ".$i"  || -e ".$i" ]]
                then
                echo "$i exists, removing....."
                rm  ".$i"
        fi
        ln -s $MYDIR/tools/$i "./bin/$i"
        cd $MYDIR


done
