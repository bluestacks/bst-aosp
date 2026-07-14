#!/bin/bash
# Round 83: 7AE art-libs full apex + statspull colocate; ld.config statsd paths; 7AD probe
set -e
AOSP=~/aosp16
BOOT=~/app-player/hd/guest/BootImage
ART_SRC="$AOSP/out_nxt_Baklava64/target/product/generic_x86_64/obj/PACKAGING/check_vintf_all_intermediates/apex/com.android.art/lib64"
STATSD_SRC="$AOSP/out_nxt_Baklava64/target/product/generic_x86_64/apex/com.android.os.statsd/lib64"

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
sed -i 's/\r$//' "$BOOT/stage2.sh"

cp ~/patch-ldconfig-bs-bringup.py "$BOOT/"
python3 "$BOOT/patch-ldconfig-bs-bringup.py" 2>&1 | tail -4

# 7AE: pack ALL apex art lib64 (bind mount replaces entire dir — need self-contained set)
mkdir -p "$BOOT/art-libs"
rm -f "$BOOT/art-libs"/*.so
for f in "$ART_SRC"/*.so; do
    cp "$f" "$BOOT/art-libs/$(basename "$f")"
done
for f in libstatspull.so libstatssocket.so; do
    [ -f "$STATSD_SRC/$f" ] && cp "$STATSD_SRC/$f" "$BOOT/art-libs/$f"
done
ls -la "$BOOT/art-libs/libart.so" "$BOOT/art-libs/libstatspull.so"
echo "art-libs count=$(ls "$BOOT/art-libs"/*.so | wc -l)"

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -5
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND83_DONE
