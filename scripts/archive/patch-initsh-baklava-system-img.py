#!/usr/bin/env python3
"""init.sh: baklava64 mounts android/system.img (ext4) — kernel has no CONFIG_SQUASHFS."""
from pathlib import Path

p = Path.home() / "app-player/hd/guest/BootImage/init.sh"
t = p.read_text()

baklava_block = """
if [ "$bstandroid" == "baklava64" ] && [ -f /boot/android/android/system.img ]; then
\tlog_echo "Mounting baklava system.img"
\tmkdir -p system
\tmount -o loop,ro /boot/android/android/system.img system
\tdie_if_error "Cannot mount baklava system.img"
\techo "<0>A16DBG: system.img mounted; init_bytes=$(wc -c < /system/bin/init 2>&1)" > /dev/kmsg
elif [ -e /boot/android/android/system.sfs ]; then"""

if "baklava system.img" in t:
    print("init.sh system.img path already present")
else:
    old = "if [ -e /boot/android/android/system.sfs ]; then"
    if old not in t:
        raise SystemExit("system.sfs anchor not found")
    t = t.replace(old, baklava_block, 1)
    p.write_text(t)
    print("init.sh: baklava64 system.img mount before system.sfs")
