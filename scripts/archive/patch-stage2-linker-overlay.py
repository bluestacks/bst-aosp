#!/usr/bin/env python3
from pathlib import Path

p = Path.home() / "app-player/hd/guest/BootImage/stage2.sh"
t = p.read_text()

old = """    for b in ueventd apexd; do
        [ -f /boot/bin/$b ] && /boot/bin/busybox cp /boot/bin/$b /mnt/system_bin/$b
    done
    /boot/bin/busybox chmod 755 /mnt/system_bin/*"""
new = """    /boot/bin/busybox mkdir -p /mnt/system_bin/bootstrap
    /boot/bin/busybox cp /system/bin/bootstrap/linker64 /mnt/system_bin/bootstrap/ 2>/dev/null
    for b in ueventd apexd; do
        [ -f /boot/bin/$b ] && /boot/bin/busybox cp /boot/bin/$b /mnt/system_bin/$b
    done
    /boot/bin/busybox chmod -R 755 /mnt/system_bin"""
t = t.replace(old, new)
p.write_text(t)
print("stage2.sh linker64 in overlay OK")
