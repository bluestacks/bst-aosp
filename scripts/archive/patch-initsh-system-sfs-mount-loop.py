#!/usr/bin/env python3
"""init.sh: inner system.img via mount -o loop (kernel path, not busybox losetup)."""
from pathlib import Path

p = Path.home() / "app-player/hd/guest/BootImage/init.sh"
t = p.read_text()

old = """\tlog_echo "Mounting system.img"

\tsfsloop=`/boot/bin/busybox losetup -f`
\tif [ -z "$sfsloop" ]; then die_if_error "Cannot find free loop for system.img"; fi
\t/boot/bin/busybox losetup $sfsloop /sfs/system.img
\tif [ $? -ne 0 ]; then die_if_error "Cannot losetup system.img from sfs"; fi
\tmount -t ext4 -o ro $sfsloop system
\tdie_if_error "Cannot mount system.img from SquashFS"
\techo "<0>A16DBG: system mounted from sfs; init_bytes=$(wc -c < /system/bin/init 2>&1)" > /dev/kmsg"""

new = """\tlog_echo "Mounting system.img"

\tmount -o loop,ro /sfs/system.img system
\tdie_if_error "Cannot mount system.img from SquashFS"
\techo "<0>A16DBG: system mounted from sfs; init_bytes=$(wc -c < /system/bin/init 2>&1)" > /dev/kmsg"""

if "mount -o loop,ro /sfs/system.img system" in t:
    print("init.sh mount -o loop inner already patched")
elif old not in t:
    raise SystemExit("losetup inner block not found")
else:
    p.write_text(t.replace(old, new, 1))
    print("init.sh: mount -o loop inner system.img from squashfs")
