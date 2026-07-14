#!/bin/sh
log_echo() { echo "$@" > /dev/kmsg; }
exec >/dev/kmsg 2>/dev/kmsg
umask 022
die() { log_echo "<2>ERROR: $@"; exit 1; }
warn_if_error() { if [ $? -ne 0 ]; then log_echo "<3>WARNING: $@"; fi; }
die_if_error() { if [ $? -ne 0 ]; then die "$@"; fi; }

log_echo "Mounting file systems"
mkdir -p /mnt/tmp
echo "<0>A16DBG: stage2 start" > /dev/kmsg
PATH=/boot/sbin:/boot/bin
export PATH

source /boot/bstsetup.env
source /boot/4-dpi
die_if_error() { log_echo "NON-FATAL: $@"; return 0; }

if [ ${BST_0DCT:-0} -ne 0 ]; then zerofree_data; fi
mount_data
prepare_bst_filesystems
# BRINGUP: skip swap (data unmounted)
# enable_swapspace
setup_dpi
set_propfile_permissions
setup_memory_allocator
mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null

mkdir /dev/log
for i in main events system radio; do
    if [ -f /sys/devices/virtual/misc/log_$i/dev ]; then
        nums=$(cat /sys/devices/virtual/misc/log_$i/dev | tr ":" " ")
        mknod /dev/log/$i c $nums
    fi
done

echo 1 > /proc/sys/net/ipv6/conf/eth0/disable_ipv6
ifconfig eth0 10.0.2.15 netmask 255.255.255.0 up
/boot/bin/busybox route add default gw $WINDOWSGATEWAY dev eth0
ip route add $WINDOWSGATEWAY dev eth0 table local
echo "nameserver 8.8.8.8" > /boot/resolv.conf
log_echo "Welcome to BlueStacks Android"

grep SHELL_BEFORE_INIT= /proc/cmdline > /dev/null && { env HAS_CTTY=Yes setsid /boot/bin/cttyhack /boot/bin/ash; }

log_echo "Starting Android"
mkdir -p /tmp /cache /data /apex /linkerconfig /bootstrap-apex /metadata 2>/dev/null

mkdir -p /data/misc/adb 2>/dev/null
if [ -f /boot/adbkey.pub ]; then
    /boot/bin/busybox cp /boot/adbkey.pub /data/misc/adb/adb_keys 2>/dev/null
    /boot/bin/busybox chmod 640 /data/misc/adb/adb_keys 2>/dev/null
    echo "<0>A16DBG: adb key installed" > /dev/kmsg
fi

# BRINGUP: patched init + per-file bind (no /system/bin overlay)
/boot/bin/busybox mkdir -p /tmp /etc
/boot/bin/busybox mount -t tmpfs tmpfs /tmp -o size=64m 2>/dev/null
/boot/bin/busybox cp /boot/init-patched /tmp/init
/boot/bin/busybox chmod 755 /tmp/init
if [ -f /boot/etc/cgroups.json ]; then
    /boot/bin/busybox cp /boot/etc/cgroups.json /etc/cgroups.json
fi
/boot/bin/busybox mount -o remount,rw /system 2>/dev/null || true
for b in ueventd apexd aconfigd-system servicemanager hwservicemanager vdc vold keystore2; do
    if [ -f /boot/bin/$b ]; then
        /boot/bin/busybox cp /boot/bin/$b /tmp/$b
        /boot/bin/busybox chmod 755 /tmp/$b
        /boot/bin/busybox rm -f /system/bin/$b 2>/dev/null
        if /boot/bin/busybox cp /tmp/$b /system/bin/$b 2>/dev/null; then
            echo "<0>A16DBG: replaced /system/bin/$b" > /dev/kmsg
        elif /boot/bin/busybox mount --bind /tmp/$b /system/bin/$b 2>/dev/null; then
            echo "<0>A16DBG: bind /system/bin/$b" > /dev/kmsg
        else
            echo "<0>A16DBG: FAILED /system/bin/$b" > /dev/kmsg
        fi
    fi
done
# Writable /data /cache /metadata when partition mount leaves them read-only
for mp in /data /cache /metadata; do
    /boot/bin/busybox mkdir -p $mp
    /boot/bin/busybox touch $mp/.w 2>/dev/null || \
        /boot/bin/busybox mount -t tmpfs tmpfs $mp -o size=256m
done
# ro.zygote when vendor partition missing
/boot/bin/busybox mkdir -p /vendor
echo 'ro.zygote=zygote64' > /vendor/build.prop
# loop devices for apexd-bootstrap (no udev in BS bringup)
/boot/bin/busybox mkdir -p /dev
if [ ! -e /dev/loop-control ]; then
    /boot/bin/busybox mknod /dev/loop-control c 10 237
fi
i=0
while [ $i -lt 64 ]; do
    [ -e /dev/loop$i ] || /boot/bin/busybox mknod /dev/loop$i b 7 $i
    i=$((i + 1))
done
echo "<0>A16DBG: loop devices ready" > /dev/kmsg
# BRINGUP: skip umount; patched init uses MS_REMOUNT for proc/sys
echo "<0>A16DBG: exec /tmp/init-patched" > /dev/kmsg
exec /tmp/init
echo "<0>A16DBG: exec /tmp/init FAILED rc=$?" > /dev/kmsg
