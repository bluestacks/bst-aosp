#!/bin/bash
# Atomic: kernel modules symvers + bstmods + initrd + fastboot (after CONFIG change).
set -euo pipefail
KDIR=~/aosp16/kernel-a16
BOOT=~/app-player/hd/guest/BootImage
HD=~/app-player/hd/Source
export HD_SOURCE_TOP=~/app-player/hd/

cd "$KDIR"
echo "=== kernel bzImage + modules (refresh Module.symvers) ==="
make -j"$(nproc)" bzImage modules 2>&1 | tail -15
ls -la arch/x86/boot/bzImage Module.symvers

build_ko() {
    local dir="$1"
    echo "=== $dir ==="
    make -C "$dir" clean KDIR="$KDIR" HD_SOURCE_TOP="$HD_SOURCE_TOP" 2>/dev/null || true
    make -C "$dir" KDIR="$KDIR" HD_SOURCE_TOP="$HD_SOURCE_TOP"
}

make -C "$KDIR" M=drivers/media/v4l2-core modules 2>&1 | tail -3
for d in "$HD/vmsg/guest/driver" "$HD/inp/guest/driver" "$HD/aud/guest/driver" \
           "$HD/cam/guest/driver" "$HD/hst/guest/driver"; do
    build_ko "$d"
done

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
cd "$BOOT"
make initrd.img KDIR="$KDIR" 2>&1 | tail -6
make build_fastboot KDIR="$KDIR" 2>&1 | tail -6
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi initrd.img arch/x86/boot/bzImage 2>/dev/null || md5sum fastboot/fastboot.vdi initrd.img "$KDIR/arch/x86/boot/bzImage"
modinfo initrd/boot/bstmods/bstvmsg.ko | grep vermagic
echo ATOMIC_KERNEL_BSTMODS_DONE
