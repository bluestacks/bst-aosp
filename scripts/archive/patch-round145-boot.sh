#!/bin/bash
# Round 145: i18n APEX javalib remount @ odsign (core-icu4j.jar for odrefresh primary BCP)
set -e
BOOT=~/app-player/hd/guest/BootImage
I18N_APEX=~/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/system/apex/com.android.i18n.apex
cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
sed -i 's/\r$//' "$BOOT/stage2.sh"
mkdir -p "$BOOT/i18n-javalib"
MP=/tmp/i18n-jav-extract
sudo umount "$MP" 2>/dev/null || true
mkdir -p "$MP"
sudo losetup -o 4096 -f --show "$I18N_APEX" > /tmp/i18n-loop.$$
LP=$(cat /tmp/i18n-loop.$$)
sudo mount -t erofs -o ro "$LP" "$MP"
cp "$MP/javalib/core-icu4j.jar" "$BOOT/i18n-javalib/"
sudo umount "$MP"
sudo losetup -d "$LP" 2>/dev/null
rm -f /tmp/i18n-loop.$$
ls -la "$BOOT/i18n-javalib/core-icu4j.jar"
MK="$BOOT/Makefile"
if ! grep -q 'initrd/boot/i18n-javalib' "$MK"; then
  sed -i '/initrd\/boot\/i18n-libs/a\\tmkdir -p initrd/boot/i18n-javalib\n\t@test -f i18n-javalib/core-icu4j.jar \&\& cp i18n-javalib/core-icu4j.jar initrd/boot/i18n-javalib/ || echo "henry-7BW skip initrd i18n-javalib"' "$MK"
fi
cd "$BOOT"
echo "7BW=$(grep -c 'henry-7BW i18n' stage2.sh || true)"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -1
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND145_DONE
