#!/usr/bin/env python3
"""init.sh: baklava64 system.img via losetup (busybox mount -o loop fails >2GB files)."""
from pathlib import Path

p = Path.home() / "app-player/hd/guest/BootImage/init.sh"
t = p.read_text()

old = """if [ "$bstandroid" == "baklava64" ] && [ -f /boot/android/android/system.img ]; then
\tlog_echo "Mounting baklava system.img"
\tmkdir -p system
\tmount -o loop,ro /boot/android/android/system.img system
\tdie_if_error "Cannot mount baklava system.img"
\techo "<0>A16DBG: system.img mounted; init_bytes=$(wc -c < /system/bin/init 2>&1)" > /dev/kmsg"""

new = """if [ "$bstandroid" == "baklava64" ] && [ -f /boot/android/android/system.img ]; then
\tlog_echo "Mounting baklava system.img"
\tmkdir -p system
\tfind_free_loop_sys()
\t{
\t\tn=0
\t\twhile [ $n -lt 48 ]; do
\t\t\tif [ ! -d /sys/block/loop$n/loop ]; then
\t\t\t\techo /dev/loop$n
\t\t\t\treturn 0
\t\t\tfi
\t\t\tn=`expr $n + 1`
\t\tdone
\t\treturn 1
\t}
\tsysloop=`find_free_loop_sys`
\t/boot/bin/busybox losetup $sysloop /boot/android/android/system.img
\tif [ $? -ne 0 ]; then die_if_error "Cannot losetup baklava system.img"; fi
\tmount -t ext4 -o ro $sysloop system
\tdie_if_error "Cannot mount baklava system.img"
\techo "<0>A16DBG: system.img mounted on $sysloop; init_bytes=$(wc -c < /system/bin/init 2>&1)" > /dev/kmsg"""

if "find_free_loop_sys" in t:
    print("init.sh losetup system.img already patched")
elif old not in t:
    raise SystemExit("baklava system.img block not found — manual merge needed")
else:
    t = t.replace(old, new, 1)
    p.write_text(t)
    print("init.sh: baklava64 system.img via losetup+ext4 mount")
