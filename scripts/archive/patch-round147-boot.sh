#!/bin/bash
# Round 147: adservices APEX javalib @ odsign (mainline BCP framework/service-adservices.jar)
set -e
BOOT=~/app-player/hd/guest/BootImage
ADS_CAPEX=~/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/system/apex/com.android.adservices.capex
cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
sed -i 's/\r$//' "$BOOT/stage2.sh"
TMP=/tmp/ads-r147
rm -rf "$TMP"
mkdir -p "$TMP" "$BOOT/adservices-javalib"
cd "$TMP"
unzip -q "$ADS_CAPEX" original_apex
cp original_apex "$BOOT/adservices-inner.apex"
MP=/tmp/ads-jav-extract
sudo umount "$MP" 2>/dev/null || true
mkdir -p "$MP"
sudo losetup -o 4096 -f --show "$BOOT/adservices-inner.apex" > /tmp/ads-loop.$$
LP=$(cat /tmp/ads-loop.$$)
sudo mount -t erofs -o ro "$LP" "$MP"
for _j in framework-adservices.jar service-adservices.jar framework-sdksandbox.jar service-sdksandbox.jar; do
  cp "$MP/javalib/$_j" "$BOOT/adservices-javalib/"
done
sudo umount "$MP"
sudo losetup -d "$LP" 2>/dev/null
rm -f /tmp/ads-loop.$$
ls -la "$BOOT/adservices-javalib/" "$BOOT/adservices-inner.apex"
MK="$BOOT/Makefile"
if ! grep -q 'initrd/boot/adservices-javalib' "$MK"; then
  sed -i '/initrd\/boot\/i18n-javalib/a\\tmkdir -p initrd/boot/adservices-javalib initrd/boot\n\t@test -f adservices-inner.apex \&\& cp adservices-inner.apex initrd/boot/adservices-inner.apex || echo "henry-7BX skip initrd adservices-inner"\n\t@test -f adservices-javalib/framework-adservices.jar \&\& cp adservices-javalib/*.jar initrd/boot/adservices-javalib/ || echo "henry-7BX skip initrd adservices-javalib"' "$MK"
fi
cd "$BOOT"
echo "7BX=$(grep -c 'henry-7BX adservices' stage2.sh || true)"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -1
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND147_DONE
