#!/usr/bin/env python3
"""Insert BS bringup bind-mount for corrupted /system/bin binaries into stage2.sh."""
from pathlib import Path

p = Path.home() / "app-player/hd/guest/BootImage/stage2.sh"
t = p.read_text()

block = """
# BRINGUP: overlay corrupted /system/bin binaries from /boot/bin
for b in ueventd apexd linker64; do
    if [ -f /boot/bin/$b ]; then
        /boot/bin/busybox cp /boot/bin/$b /tmp/$b
        /boot/bin/busybox chmod 755 /tmp/$b
        mount --bind /tmp/$b /system/bin/$b 2>/dev/null && \\
            echo "<0>A16DBG: bind /system/bin/$b" > /dev/kmsg
    fi
done
"""

needle = "# BRINGUP: skip umount; patched init uses MS_REMOUNT for proc/sys"
if "bind /system/bin" not in t and needle in t:
    t = t.replace(needle, block + needle)
    p.write_text(t)
    print("stage2.sh bind-mount block added")
else:
    print("stage2.sh already patched or needle missing")
