#!/bin/bash
# Enable CONFIG_SQUASHFS in kernel-a16 and rebuild fastboot for henry system.sfs path.
set -euo pipefail
KDIR=~/aosp16/kernel-a16
CFG="$KDIR/.config"
BOOT=~/app-player/hd/guest/BootImage

cd "$KDIR"
if grep -q '^CONFIG_SQUASHFS=y' "$CFG" 2>/dev/null; then
    echo "CONFIG_SQUASHFS already enabled"
else
    sed -i 's/# CONFIG_SQUASHFS is not set/CONFIG_SQUASHFS=y/' "$CFG"
    # Pull in common squashfs deps if missing
    for opt in CONFIG_SQUASHFS_XATTR CONFIG_SQUASHFS_ZLIB CONFIG_SQUASHFS_DECOMP_SINGLE; do
        grep -q "^$opt=y" "$CFG" || echo "$opt=y" >> "$CFG"
    done
    make olddefconfig
    grep SQUASHFS "$CFG" | head -5
fi

echo "Building kernel..."
make -j"$(nproc)" bzImage 2>&1 | tail -15
ls -la arch/x86/boot/bzImage

cd "$BOOT"
make build_fastboot KDIR="$KDIR" 2>&1 | tail -8
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
ls -la fastboot/fastboot.vdi
echo KERNEL_SQUASHFS_DONE
