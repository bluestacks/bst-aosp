#!/bin/bash
# Round 99: henry-7BD real odsign + 7BF skip incomplete boot chain + 7BE oracle
# No pre-staged boot.art — odrefresh generates boot-framework.* on device (henry 7R)
set -e
BOOT=~/app-player/hd/guest/BootImage
ART_PROF=~/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/system/etc/boot-image.prof
ART_PAYLOAD="$BOOT/art-payload.img"
CACHE_INFO=~/cache-info-uffd-off.xml

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
cp ~/bs_bootlog.sh "$BOOT/bs_bootlog.sh"
cp "$CACHE_INFO" "$BOOT/cache-info-uffd-off.xml"
sed -i 's/\r$//' "$BOOT/stage2.sh" "$BOOT/bs_bootlog.sh" "$BOOT/cache-info-uffd-off.xml"
chmod 755 "$BOOT/bs_bootlog.sh"

mkdir -p "$BOOT/dalvik-cache/x86_64" "$BOOT/profiles" "$BOOT/art-javalib"
rm -f "$BOOT/dalvik-cache/x86_64"/*
cp -a "$ART_PROF" "$BOOT/profiles/boot-image.prof"

mkdir -p /tmp/art-jav-ro
sudo umount /tmp/art-jav-ro 2>/dev/null || true
if sudo mount -o loop,ro "$ART_PAYLOAD" /tmp/art-jav-ro; then
  cp -a /tmp/art-jav-ro/javalib/*.jar "$BOOT/art-javalib/"
  sudo umount /tmp/art-jav-ro
fi

MK="$BOOT/Makefile"
if ! grep -q 'initrd/boot/profiles' "$MK"; then
  sed -i '/initrd\/boot\/dalvik-cache\/x86_64/a\\tmkdir -p initrd/boot/profiles\n\t@test -f profiles/boot-image.prof \&\& cp profiles/boot-image.prof initrd/boot/profiles/ || (echo "missing profiles/boot-image.prof" \&\& exit 1)' "$MK"
fi
if ! grep -q 'initrd/boot/art-javalib' "$MK"; then
  sed -i '/initrd\/boot\/profiles/a\\tmkdir -p initrd/boot/art-javalib\n\t@test -f art-javalib/core-oj.jar \&\& cp art-javalib/*.jar initrd/boot/art-javalib/ || (echo "missing art-javalib" \&\& exit 1)' "$MK"
fi
if ! grep -q 'initrd/boot/cache-info-uffd-off.xml' "$MK"; then
  sed -i '/initrd\/boot\/art-javalib/a\\t@test -f cache-info-uffd-off.xml \&\& cp cache-info-uffd-off.xml initrd/boot/ || (echo "missing cache-info-uffd-off.xml" \&\& exit 1)' "$MK"
fi
# Round 99: boot.art optional — odsign/odrefresh generates on device
sed -i 's/@test -f dalvik-cache\/x86_64\/boot.art && cp -a dalvik-cache\/x86_64\/. initrd\/boot\/dalvik-cache\/x86_64\/ || (echo "missing dalvik-cache\/x86_64\/boot.art" \&\& exit 1)/@test -f dalvik-cache\/x86_64\/boot.art \&\& cp -a dalvik-cache\/x86_64\/. initrd\/boot\/dalvik-cache\/x86_64\/ || echo "henry-7BF skip initrd boot.art (odsign path)"/' "$MK"

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND99_DONE
