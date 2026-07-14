#!/usr/bin/env python3
"""Clean stage2.sh: single per-file bind block, no /system/bin overlay."""
from pathlib import Path

p = Path.home() / "app-player/hd/guest/BootImage/stage2.sh"
t = p.read_text()

start = t.find("# BRINGUP: ensure /tmp has space")
end = t.find("# BRINGUP: skip umount")
if start < 0 or end < 0:
    print("markers not found")
    raise SystemExit(1)

new_block = """# BRINGUP: copy patched init + bind-mount corrupted /system/bin files only
/boot/bin/busybox mkdir -p /tmp /etc
/boot/bin/busybox mount -t tmpfs tmpfs /tmp -o size=64m 2>/dev/null
/boot/bin/busybox cp /boot/init-patched /tmp/init
/boot/bin/busybox chmod 755 /tmp/init
if [ -f /boot/etc/cgroups.json ]; then
    /boot/bin/busybox cp /boot/etc/cgroups.json /etc/cgroups.json
fi
for b in ueventd apexd aconfigd-system servicemanager hwservicemanager vdc vold keystore2; do
    if [ -f /boot/bin/$b ]; then
        /boot/bin/busybox cp /boot/bin/$b /tmp/$b
        /boot/bin/busybox chmod 755 /tmp/$b
        /boot/bin/busybox mount --bind /tmp/$b /system/bin/$b 2>/dev/null && \\
            echo "<0>A16DBG: bind /system/bin/$b" > /dev/kmsg
    fi
done
"""

t = t[:start] + new_block + t[end:]
p.write_text(t)
print("stage2.sh cleaned")
