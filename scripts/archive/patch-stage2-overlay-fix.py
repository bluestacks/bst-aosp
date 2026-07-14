#!/usr/bin/env python3
from pathlib import Path

p = Path.home() / "app-player/hd/guest/BootImage/stage2.sh"
t = p.read_text()

t = t.replace("/tmp/system_bin", "/mnt/system_bin")
# Copy init BEFORE overlay to avoid /tmp pressure
old = """# BRINGUP: tmpfs overlay /system/bin (VHD ext4 inode corruption)
if [ -f /boot/bin/ueventd ]; then
    /boot/bin/busybox mkdir -p /mnt/system_bin"""
new = """# BRINGUP: copy init first, then overlay /system/bin (VHD ext4 corruption)
/boot/bin/busybox cp /boot/init-patched /tmp/init
/boot/bin/busybox chmod 755 /tmp/init
if [ -f /boot/bin/ueventd ]; then
    /boot/bin/busybox mkdir -p /mnt/system_bin"""
t = t.replace(old, new)

# Remove duplicate cp/chmod before exec
t = t.replace(
    "# BRINGUP: skip umount; patched init uses MS_REMOUNT for proc/sys\n"
    "/boot/bin/busybox cp /boot/init-patched /tmp/init\n"
    "/boot/bin/busybox chmod 755 /tmp/init\n",
    "# BRINGUP: skip umount; patched init uses MS_REMOUNT for proc/sys\n",
)

p.write_text(t)
print("stage2.sh fixed mount path + init copy order")
