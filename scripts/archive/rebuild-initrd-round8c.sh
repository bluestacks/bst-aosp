#!/bin/bash
set -e
python3 ~/patch-init-bringup-tolerance.py
python3 ~/patch-stage2-bin-overlay.py

cd ~/aosp16
source build/envsetup.sh
lunch aosp_x86_64-trunk_staging-eng >/dev/null 2>&1
export OUT_DIR=out_nxt_Baklava64
prebuilts/build-tools/linux_musl-x86/bin/ninja -f out_nxt_Baklava64/combined-aosp_x86_64.ninja init 2>&1 | tail -3

BOOT=~/app-player/hd/guest/BootImage
cp out_nxt_Baklava64/target/product/generic_x86_64/system/bin/init "$BOOT/init-patched"

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -1
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -1
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
echo DONE
