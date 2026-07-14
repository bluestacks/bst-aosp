#!/bin/bash
# Rebuild hd guest .ko modules against current kernel-a16, then initrd + fastboot.
set -euo pipefail
KDIR=~/aosp16/kernel-a16
BOOT=~/app-player/hd/guest/BootImage
HD=~/app-player/hd/Source
export HD_SOURCE_TOP=~/app-player/hd/

build_ko() {
    local dir="$1"
    echo "=== building $dir ==="
    make -C "$dir" clean KDIR="$KDIR" HD_SOURCE_TOP="$HD_SOURCE_TOP" 2>/dev/null || true
    make -C "$dir" KDIR="$KDIR" HD_SOURCE_TOP="$HD_SOURCE_TOP"
    ls -la "$dir"/*.ko
}

# videobuf-core from in-tree kernel
echo "=== videobuf-core ==="
make -C "$KDIR" M=drivers/media/v4l2-core modules 2>&1 | tail -5

for d in \
    "$HD/vmsg/guest/driver" \
    "$HD/inp/guest/driver" \
    "$HD/aud/guest/driver" \
    "$HD/cam/guest/driver" \
    "$HD/hst/guest/driver"; do
    build_ko "$d"
done

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh" 2>/dev/null || cp ~/app-player/hd/guest/BootImage/stage2-good-vhd.sh "$BOOT/stage2.sh" 2>/dev/null || true
[ -f ~/stage2-good-vhd.sh ] && cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh" || true

cd "$BOOT"
make initrd.img KDIR="$KDIR" 2>&1 | tail -10
make build_fastboot KDIR="$KDIR" 2>&1 | tail -8
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
ls -la fastboot/fastboot.vdi
modinfo initrd/boot/bstmods/bstvmsg.ko | grep vermagic
echo BSTMODS_INITRD_DONE
