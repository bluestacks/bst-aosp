#!/bin/bash
set -e
python3 ~/patch-init-boot-blockers.py
BOOT=~/app-player/hd/guest/BootImage
cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
python3 ~/patch-stage2-round10.py
python3 ~/fix-makefile-initrd.py

cd ~/aosp16
source build/envsetup.sh
lunch aosp_x86_64-trunk_staging-eng >/dev/null 2>&1
export OUT_DIR=out_nxt_Baklava64
prebuilts/build-tools/linux_musl-x86/bin/ninja -f out_nxt_Baklava64/combined-aosp_x86_64.ninja init 2>&1 | tail -5

BOOT=~/app-player/hd/guest/BootImage
OUT=out_nxt_Baklava64/target/product/generic_x86_64
cp "$OUT/system/bin/init" "$BOOT/init-patched"

# Makefile patched by fix-round10-restore.py

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
ls -la fastboot/fastboot.vdi
echo DONE
