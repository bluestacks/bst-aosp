#!/usr/bin/env python3
from pathlib import Path

p = Path.home() / "app-player/hd/guest/BootImage/stage2.sh"
t = p.read_text()

# Replace cgroup+bind block with directory overlay approach
markers = ["# BRINGUP: cgroup + overlay", "# BRINGUP: overlay corrupted"]
start = -1
for m in markers:
    idx = t.find(m)
    if idx >= 0:
        start = idx
        break
end = t.find("# BRINGUP: skip umount")
if start < 0 or end < 0:
    print("markers not found")
    raise SystemExit(1)

new_block = """# BRINGUP: tmpfs overlay /system/bin (VHD ext4 inode corruption)
if [ -f /boot/bin/ueventd ]; then
    /boot/bin/busybox mkdir -p /tmp/system_bin
    /boot/bin/busybox mount -t tmpfs tmpfs /tmp/system_bin -o mode=755
    for b in ueventd apexd; do
        [ -f /boot/bin/$b ] && /boot/bin/busybox cp /boot/bin/$b /tmp/system_bin/$b
    done
    /boot/bin/busybox chmod 755 /tmp/system_bin/*
    /boot/bin/busybox mount --bind /tmp/system_bin /system/bin && \\
        echo "<0>A16DBG: overlay /system/bin" > /dev/kmsg
fi
if [ -f /boot/etc/cgroups.json ]; then
    /boot/bin/busybox mkdir -p /etc
    /boot/bin/busybox cp /boot/etc/cgroups.json /etc/cgroups.json
fi
"""

t = t[:start] + new_block + t[end:]
p.write_text(t)
print("stage2.sh overlay block OK")
