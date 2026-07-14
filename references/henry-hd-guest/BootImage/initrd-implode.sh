#!/bin/sh

progname=${0##*/}

panic_on_error()
{
	if [ $? -ne 0 ]; then
		echo "$@" >&2
		exit 1
	fi
}

if [ $# != 2 ]; then
	echo "Usage: ${progname} <directory> <initrd>"
	exit 1
fi

dir=$1
initrd=$2

(cd ${dir} && find . | cpio -o --format=newc) | gzip -9 -c > ${initrd}
panic_on_error "Cannot create ramdisk"
