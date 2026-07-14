#!/bin/bash
set -e
python3 ~/patch-selinux-setenforce.py
python3 ~/patch-service-filecontext.py
python3 ~/patch-stage2-bind-bin.py

OUT=~/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/system/bin
BOOT=~/app-player/hd/guest/BootImage
mkdir -p "$BOOT/bin"
for b in ueventd apexd linker64; do
    cp "$OUT/$b" "$BOOT/bin/" && echo "copied $b"
done
ls -la "$BOOT/bin/"

cd ~/aosp16
source build/envsetup.sh
lunch aosp_x86_64-trunk_staging-eng >/dev/null 2>&1
export OUT_DIR=out_nxt_Baklava64
prebuilts/build-tools/linux_musl-x86/bin/ninja -f out_nxt_Baklava64/combined-aosp_x86_64.ninja init 2>&1 | tail -3

cp out_nxt_Baklava64/target/product/generic_x86_64/system/bin/init "$BOOT/init-patched"

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -1
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -1
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
echo DONE
