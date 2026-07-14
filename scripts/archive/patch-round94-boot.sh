#!/bin/bash
# Round 94: henry-7AX art-payload javalib (core-oj.jar) on apex shim
set -e
BOOT=~/app-player/hd/guest/BootImage
ART_BOOT=~/aosp16/out_nxt_Baklava64/host/linux-x86/apex/art_boot_images/javalib/x86_64
ART_PROF=~/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/system/etc/boot-image.prof

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
cp ~/bs_bootlog.sh "$BOOT/bs_bootlog.sh"
sed -i 's/\r$//' "$BOOT/stage2.sh" "$BOOT/bs_bootlog.sh"
chmod 755 "$BOOT/bs_bootlog.sh"

mkdir -p "$BOOT/dalvik-cache/x86_64" "$BOOT/profiles"
rm -f "$BOOT/dalvik-cache/x86_64"/*
cp -a "$ART_BOOT"/. "$BOOT/dalvik-cache/x86_64/"
cp -a "$ART_PROF" "$BOOT/profiles/boot-image.prof"

MK="$BOOT/Makefile"
if ! grep -q 'initrd/boot/profiles' "$MK"; then
  sed -i '/initrd\/boot\/dalvik-cache\/x86_64/a\\tmkdir -p initrd/boot/profiles\n\t@test -f profiles/boot-image.prof \&\& cp profiles/boot-image.prof initrd/boot/profiles/ || (echo "missing profiles/boot-image.prof" \&\& exit 1)' "$MK"
fi

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND94_DONE
