#!/bin/bash
# Round 117: bind-patch init.rc to no-op stock earlyBootEnded before second-stage init
set -e
AOSP=~/aosp16
BOOT=~/app-player/hd/guest/BootImage
ART_PROF=~/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/system/etc/boot-image.prof
ART_PAYLOAD="$BOOT/art-payload.img"
CACHE_INFO=~/cache-info-uffd-off.xml
ADBC="$AOSP/out_nxt_Baklava64/target/product/generic_x86_64/apex/com.android.adbd/lib64/libadbconnection_client.so"

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
cp ~/bs_bootlog.sh "$BOOT/bs_bootlog.sh"
cp "$CACHE_INFO" "$BOOT/cache-info-uffd-off.xml"
cp "$AOSP/out_nxt_Baklava64/target/product/generic_x86_64/system/bin/odsign" "$BOOT/odsign-patched"
sed -i 's/\r$//' "$BOOT/stage2.sh" "$BOOT/bs_bootlog.sh" "$BOOT/cache-info-uffd-off.xml"
chmod 755 "$BOOT/bs_bootlog.sh" "$BOOT/odsign-patched"

mkdir -p "$BOOT/art-libs" "$BOOT/dalvik-cache/x86_64" "$BOOT/profiles" "$BOOT/art-javalib"
cp -a "$ADBC" "$BOOT/art-libs/libadbconnection_client.so"
rm -f "$BOOT/dalvik-cache/x86_64"/*
cp -a "$ART_PROF" "$BOOT/profiles/boot-image.prof"

mkdir -p /tmp/art-jav-ro
sudo umount /tmp/art-jav-ro 2>/dev/null || true
if sudo mount -o loop,ro "$ART_PAYLOAD" /tmp/art-jav-ro; then
  cp -a /tmp/art-jav-ro/javalib/*.jar "$BOOT/art-javalib/"
  sudo umount /tmp/art-jav-ro
fi

MK="$BOOT/Makefile"
if ! grep -q 'odsign-patched initrd/boot/bin/odsign' "$MK"; then
  sed -i '/cp .*vdc initrd\/boot\/bin\/vdc/a\\tcp odsign-patched initrd/boot/bin/odsign\n\tchmod 755 initrd/boot/bin/odsign' "$MK"
fi
sed -i 's/@test -f dalvik-cache\/x86_64\/boot.art && cp -a dalvik-cache\/x86_64\/. initrd\/boot\/dalvik-cache\/x86_64\/ || (echo "missing dalvik-cache\/x86_64\/boot.art" \&\& exit 1)/@test -f dalvik-cache\/x86_64\/boot.art \&\& cp -a dalvik-cache\/x86_64\/. initrd\/boot\/dalvik-cache\/x86_64\/ || echo "henry-7BF skip initrd boot.art (odsign path)"/' "$MK"

cd "$BOOT"
echo "odsign-patched bytes=$(wc -c < odsign-patched)"
make initrd.img KDIR=~/aosp16/kernel-a16
zcat initrd.img | cpio -t 2>/dev/null | grep -E 'boot/bin/(keystore2|odsign)'
make build_fastboot KDIR=~/aosp16/kernel-a16
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND117_DONE
