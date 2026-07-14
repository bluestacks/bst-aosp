#!/bin/bash
# Round 82: apex bind for libart dlopen + skip henry a13 boot.art
set -e
BOOT=~/app-player/hd/guest/BootImage

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
sed -i 's/\r$//' "$BOOT/stage2.sh"

# Re-apply ld.config patch (idempotent)
cp ~/patch-ldconfig-bs-bringup.py "$BOOT/"
python3 "$BOOT/patch-ldconfig-bs-bringup.py" 2>&1 | tail -3

cd "$BOOT"
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND82_DONE
