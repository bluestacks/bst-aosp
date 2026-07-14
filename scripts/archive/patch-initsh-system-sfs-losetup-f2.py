#!/usr/bin/env python3
"""init.sh: two-step busybox losetup -f then associate FILE."""
from pathlib import Path

p = Path.home() / "app-player/hd/guest/BootImage/init.sh"
t = p.read_text()

old = """\tsfsloop=`/boot/bin/busybox losetup -f /sfs/system.img`
\tif [ $? -ne 0 ] || [ -z "$sfsloop" ]; then die_if_error "Cannot losetup system.img from sfs"; fi"""

new = """\tsfsloop=`/boot/bin/busybox losetup -f`
\tif [ -z "$sfsloop" ]; then die_if_error "Cannot find free loop for system.img"; fi
\t/boot/bin/busybox losetup $sfsloop /sfs/system.img
\tif [ $? -ne 0 ]; then die_if_error "Cannot losetup system.img from sfs"; fi"""

if "losetup -f`" in t and "losetup $sfsloop /sfs/system.img" in t and "losetup -f /sfs" not in t:
    print("init.sh two-step losetup already patched")
elif old not in t:
    raise SystemExit("losetup -f block not found")
else:
    p.write_text(t.replace(old, new, 1))
    print("init.sh: two-step losetup -f + associate")
