#!/bin/bash


#	this setup file crates symlinks from wherever itself is located to 
#	your homedirectory.
#
#	THIS WILL DESTROY ANY FILE IN ~/ WITH THE SAME NAME AS A FILE IN 
#	THE DIRECTORY setup.sh IS.
#


MYDIR=`pwd`
for i in `ls`
do
IS_MYSELF=`echo $i | grep "setup"`
if [[ $IS_MYSELF == "" ]]
then
	echo "creating symlink for $i"
	cd ~/
	ln -s $MYDIR/$i ".$i"
	cd -
fi
done
