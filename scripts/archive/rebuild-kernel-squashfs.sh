#!/bin/bash
set -euo pipefail
KDIR=~/aosp16/kernel-a16
BOOT=~/app-player/hd/guest/BootImage
cd "$KDIR"
sed -i 's/CONFIG_SQUASHFS=m/CONFIG_SQUASHFS=y/' .config
sed -i 's/CONFIG_WERROR=y/# CONFIG_WERROR is not set/' .config
grep -q '^CONFIG_SQUASHFS=y' .config || echo CONFIG_SQUASHFS=y >> .config
make olddefconfig
echo "Building bzImage with CONFIG_SQUASHFS=y WERROR=off..."
make -j"$(nproc)" bzImage 2>&1 | tail -20
ls -la arch/x86/boot/bzImage
cd "$BOOT"
make build_fastboot KDIR="$KDIR" 2>&1 | tail -8
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
echo BZIMAGE_SQUASHFS_DONE
