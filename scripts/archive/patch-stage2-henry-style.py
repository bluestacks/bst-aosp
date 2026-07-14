#!/usr/bin/env python3
"""Revert stage2: per-file bind for corrupt binaries only (henry uses exec /init + good Root.vhd)."""
from pathlib import Path

p = Path.home() / "app-player/hd/guest/BootImage/stage2.sh"
t = p.read_text()

# Remove whole-directory overlay block; use per-file bind after init copy
import re
t = re.sub(
    r"# BRINGUP:.*?\n(?:.*?\n)*?if \[ -f /boot/etc/cgroups\.json \]; then\n"
    r"    /boot/bin/busybox cp /boot/etc/cgroups\.json /etc/cgroups\.json\n"
    r"fi\n",
    "",
    t,
    count=1,
)

block = """# BRINGUP: VHD ext4 corruption — bind-mount only broken binaries (henry: use fresh Root.vhd)
/boot/bin/busybox mkdir -p /tmp /etc
/boot/bin/busybox mount -t tmpfs tmpfs /tmp -o size=64m 2>/dev/null
/boot/bin/busybox cp /boot/init-patched /tmp/init
/boot/bin/busybox chmod 755 /tmp/init
if [ -f /boot/etc/cgroups.json ]; then
    /boot/bin/busybox cp /boot/etc/cgroups.json /etc/cgroups.json
fi
for b in ueventd apexd; do
    if [ -f /boot/bin/$b ]; then
        /boot/bin/busybox cp /boot/bin/$b /tmp/$b
        /boot/bin/busybox chmod 755 /tmp/$b
        /boot/bin/busybox mount --bind /tmp/$b /system/bin/$b 2>/dev/null && \\
            echo "<0>A16DBG: bind /system/bin/$b" > /dev/kmsg
    fi
done
"""

needle = "# BRINGUP: skip umount; patched init uses MS_REMOUNT for proc/sys"
if needle in t and "bind-mount only broken" not in t:
    t = t.replace(needle, block + needle)
    p.write_text(t)
    print("stage2 per-file bind OK")
else:
    print("stage2 already updated or needle missing")
