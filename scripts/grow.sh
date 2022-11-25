#!/bin/bash

rootdev=$(lsblk -l -o PATH,MOUNTPOINT | awk '/\/$/ { print $1 }')
if [[ "$rootdev" != "/dev/mapper"* ]]; then
	echo "No LVM, can't resize"
	exit
fi

lvinfo=$(lvdisplay -c $rootdev)
vgname=$(echo $lvinfo | cut -d: -f2)
pvol=$(pvdisplay -c --select vgname=$vgname | gawk 'match($0,/(\/dev\/sd[abc])/,a) { print a[0]; exit }')
unpart=$(sfdisk --quiet --list-free $pvol 2>&1)
if [ ! "$unpart" ]; then
	echo No unused space on $pvol for $rootdev on volume group $vgname
	exit 0
fi

echo "Claiming unused space on $pvol"


newdisk=$(echo ',,V' | sfdisk -a --force $pvol 2>/dev/null | awk '/Created a new partition/  { print $1 }' | tr -d ':')
if [ ! "$newdisk" ]; then
	echo "Didn't find a new volume created. Needs handholding, sorry"
	exit 1
fi

echo Created $newdisk
/usr/bin/partx --update $pvol

set -x
if [ ! -e "$newdisk" ]; then
	echo "$newdisk wasn't created by the kernel, something is wrong"
	exit 1
fi

echo "Adding $newdisk to $vgname"
pvcreate $newdisk
vgextend $vgname $newdisk
echo "Expanding $rootdev logical volume"
lvextend -l+100%FREE $rootdev
echo "Running resize2fs"
resize2fs $rootdev



