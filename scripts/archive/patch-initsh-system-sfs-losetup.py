#!/usr/bin/env python3
"""init.sh: system.sfs path — mkdir system + losetup for inner system.img."""
from pathlib import Path

p = Path.home() / "app-player/hd/guest/BootImage/init.sh"
t = p.read_text()

old = """elif [ -e /boot/android/android/system.sfs ]; then

	mkdir /sfs

	log_echo "Mounting system.sfs"

	mount -o loop /boot/android/android/system.sfs /sfs
	die_if_error "Cannot mount system.sfs"

	log_echo "Mounting system.img"

	mount -o loop /sfs/system.img system
	die_if_error "Cannot mount system.img from SquashFS\""""

new = """elif [ -e /boot/android/android/system.sfs ]; then

	mkdir /sfs
	mkdir -p system

	log_echo "Mounting system.sfs"

	mount -o loop /boot/android/android/system.sfs /sfs
	die_if_error "Cannot mount system.sfs"
	echo "<0>A16DBG: system.sfs mounted" > /dev/kmsg

	log_echo "Mounting system.img"

	find_free_loop_sfs()
	{
		n=0
		while [ $n -lt 48 ]; do
			if [ ! -d /sys/block/loop$n/loop ]; then
				echo /dev/loop$n
				return 0
			fi
			n=`expr $n + 1`
		done
		return 1
	}
	sfsloop=`find_free_loop_sfs`
	/boot/bin/busybox losetup $sfsloop /sfs/system.img
	if [ $? -ne 0 ]; then die_if_error "Cannot losetup system.img from sfs"; fi
	mount -t ext4 -o ro $sfsloop system
	die_if_error "Cannot mount system.img from SquashFS"
	echo "<0>A16DBG: system mounted from sfs; init_bytes=$(wc -c < /system/bin/init 2>&1)" > /dev/kmsg"""

if "find_free_loop_sfs" in t:
    print("init.sh system.sfs losetup already patched")
elif old not in t:
    raise SystemExit("system.sfs block not found")
else:
    t = t.replace(old, new, 1)
    p.write_text(t)
    print("init.sh: system.sfs mkdir + losetup inner system.img")
