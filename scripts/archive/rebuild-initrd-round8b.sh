#!/bin/bash
set -e
BOOT=~/app-player/hd/guest/BootImage
OUT=~/aosp16/out_nxt_Baklava64/target/product/generic_x86_64
MAKEFILE="$BOOT/Makefile"

# One-time Makefile patch: pack ueventd/apexd/cgroups.json into initrd
if ! grep -q 'init-patched initrd/boot/bin/ueventd' "$MAKEFILE"; then
    sed -i '/cp init-patched initrd\/boot\/init-patched/a\
\tcp '"$OUT"'/system/bin/ueventd initrd/boot/bin/ueventd\
\tcp '"$OUT"'/system/bin/apexd initrd/boot/bin/apexd\
\tmkdir -p initrd/boot/etc\
\tcp '"$OUT"'/system/etc/cgroups.json initrd/boot/etc/cgroups.json' "$MAKEFILE"
    echo "Makefile patched"
fi

# Patch stage2 cgroup + bind block
python3 - <<'PY'
from pathlib import Path
p = Path.home() / "app-player/hd/guest/BootImage/stage2.sh"
t = p.read_text()
old = """# BRINGUP: overlay corrupted /system/bin binaries from /boot/bin
for b in ueventd apexd linker64; do
    if [ -f /boot/bin/$b ]; then
        /boot/bin/busybox cp /boot/bin/$b /tmp/$b
        /boot/bin/busybox chmod 755 /tmp/$b
        mount --bind /tmp/$b /system/bin/$b 2>/dev/null && \\
            echo "<0>A16DBG: bind /system/bin/$b" > /dev/kmsg
    fi
done"""
new = """# BRINGUP: cgroup + overlay corrupted /system/bin from /boot/bin
mkdir -p /sys/fs/cgroup /etc
if ! /boot/bin/busybox mountpoint -q /sys/fs/cgroup 2>/dev/null; then
    /boot/bin/busybox mount -t cgroup2 none /sys/fs/cgroup 2>/dev/null || \\
        /boot/bin/busybox mount -t tmpfs tmpfs /sys/fs/cgroup
fi
if [ -f /boot/etc/cgroups.json ]; then
    /boot/bin/busybox cp /boot/etc/cgroups.json /etc/cgroups.json
fi
/boot/bin/busybox mount -o remount,rw /system 2>/dev/null
for b in ueventd apexd; do
    if [ -f /boot/bin/$b ]; then
        /boot/bin/busybox cp /boot/bin/$b /tmp/$b
        /boot/bin/busybox chmod 755 /tmp/$b
        /boot/bin/busybox mount --bind /tmp/$b /system/bin/$b 2>/dev/null && \\
            echo "<0>A16DBG: bind /system/bin/$b" > /dev/kmsg
    fi
done"""
if old in t:
    t = t.replace(old, new)
    p.write_text(t)
    print("stage2.sh updated")
elif "cgroup2" in t:
    print("stage2.sh already has cgroup block")
else:
    print("WARNING: stage2 block not found")
PY

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -1
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
echo DONE
