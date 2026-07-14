#!/usr/bin/env python3
"""Clean stage2 + tmpfs /data /cache /metadata + default ro.zygote."""
from pathlib import Path

p = Path.home() / "app-player/hd/guest/BootImage/stage2.sh"
t = p.read_text()

start = t.find("# BRINGUP:")
end = t.find("# BRINGUP: skip umount")
if start < 0:
    start = t.find("# BRINGUP: ensure /tmp")
if start < 0 or end < 0:
    print("markers not found"); raise SystemExit(1)

new_block = """# BRINGUP: patched init + bind corrupt binaries only (no full /system/bin overlay)
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
# Writable /data /cache /metadata when partition mount fails
for mp in /data /cache /metadata; do
    /boot/bin/busybox mkdir -p $mp
    /boot/bin/busybox touch $mp/.w 2>/dev/null || \\
        /boot/bin/busybox mount -t tmpfs tmpfs $mp -o size=256m
done
echo "ro.zygote=zygote64" >> /boot/default.prop 2>/dev/null || true
"""

t = t[:start] + new_block + t[end:]
p.write_text(t)
print("stage2 cleaned with tmpfs data")
