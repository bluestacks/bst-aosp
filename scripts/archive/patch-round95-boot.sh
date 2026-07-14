#!/bin/bash
# Round 95: henry-7AY cat-copy art javalib to apex shim (+ initrd fallback)
set -e
BOOT=~/app-player/hd/guest/BootImage
ART_BOOT=~/aosp16/out_nxt_Baklava64/host/linux-x86/apex/art_boot_images/javalib/x86_64
ART_PROF=~/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/system/etc/boot-image.prof
ART_PAYLOAD="$BOOT/art-payload.img"

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
cp ~/bs_bootlog.sh "$BOOT/bs_bootlog.sh"
sed -i 's/\r$//' "$BOOT/stage2.sh" "$BOOT/bs_bootlog.sh"
chmod 755 "$BOOT/bs_bootlog.sh"

mkdir -p "$BOOT/dalvik-cache/x86_64" "$BOOT/profiles" "$BOOT/art-javalib"
rm -f "$BOOT/dalvik-cache/x86_64"/*
cp -a "$ART_BOOT"/. "$BOOT/dalvik-cache/x86_64/"
cp -a "$ART_PROF" "$BOOT/profiles/boot-image.prof"

# Pack BCP jars into initrd for 7AY fallback
mkdir -p /tmp/art-jav-ro
sudo umount /tmp/art-jav-ro 2>/dev/null || true
if sudo mount -o loop,ro "$ART_PAYLOAD" /tmp/art-jav-ro; then
  cp -a /tmp/art-jav-ro/javalib/*.jar "$BOOT/art-javalib/"
  sudo umount /tmp/art-jav-ro
fi
ls -la "$BOOT/art-javalib/core-oj.jar"

MK="$BOOT/Makefile"
if ! grep -q 'initrd/boot/profiles' "$MK"; then
  sed -i '/initrd\/boot\/dalvik-cache\/x86_64/a\\tmkdir -p initrd/boot/profiles\n\t@test -f profiles/boot-image.prof \&\& cp profiles/boot-image.prof initrd/boot/profiles/ || (echo "missing profiles/boot-image.prof" \&\& exit 1)' "$MK"
fi
if ! grep -q 'initrd/boot/art-javalib' "$MK"; then
  sed -i '/initrd\/boot\/profiles/a\\tmkdir -p initrd/boot/art-javalib\n\t@test -f art-javalib/core-oj.jar \&\& cp art-javalib/*.jar initrd/boot/art-javalib/ || (echo "missing art-javalib" \&\& exit 1)' "$MK"
fi

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -5
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND95_DONE
