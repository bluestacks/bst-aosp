#!/bin/bash
# Round 67: pack statsd libs in initrd for odsign linker (no loop at odsign time)
set -e
AOSP=~/aosp16
BOOT=~/app-player/hd/guest/BootImage
PRODUCT_OUT=$AOSP/out_nxt_Baklava64/target/product/generic_x86_64

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
cp ~/init.sh.remote "$BOOT/init.sh" 2>/dev/null || true
sed -i 's/\r$//' "$BOOT/stage2.sh" "$BOOT/init.sh"

mkdir -p "$BOOT/initrd/boot/statsd-libs"
for lib in libstatspull.so libstatssocket.so; do
    cp "$PRODUCT_OUT/apex/com.android.os.statsd/lib64/$lib" "$BOOT/initrd/boot/statsd-libs/"
done
ls -la "$BOOT/initrd/boot/statsd-libs/"

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -4
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND67_DONE
