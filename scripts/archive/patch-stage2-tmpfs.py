#!/usr/bin/env python3
from pathlib import Path

p = Path.home() / "app-player/hd/guest/BootImage/stage2.sh"
t = p.read_text()

old = """# BRINGUP: copy init first, then overlay /system/bin (VHD ext4 corruption)
/boot/bin/busybox cp /boot/init-patched /tmp/init
/boot/bin/busybox chmod 755 /tmp/init"""
new = """# BRINGUP: ensure /tmp has space, copy init, overlay /system/bin
/boot/bin/busybox mkdir -p /tmp
/boot/bin/busybox mount -t tmpfs tmpfs /tmp -o size=64m 2>/dev/null
/boot/bin/busybox cp /boot/init-patched /tmp/init || /boot/bin/busybox cp /boot/init-patched /mnt/init
/boot/bin/busybox chmod 755 /tmp/init 2>/dev/null; /boot/bin/busybox chmod 755 /mnt/init 2>/dev/null
[ -f /tmp/init ] || /boot/bin/busybox ln -sf /mnt/init /tmp/init"""
t = t.replace(old, new)
p.write_text(t)
print("stage2.sh tmpfs /tmp OK")
