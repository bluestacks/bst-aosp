#!/bin/bash
# Round 159: tzdata ICU @ zygote (henry-7CG) + initrd tzdata-etc fallback
set -e
BOOT=~/app-player/hd/guest/BootImage
TZ_APEX=~/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/system/apex/com.android.tzdata.apex
cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
sed -i 's/\r$//' "$BOOT/stage2.sh"
mkdir -p "$BOOT/tzdata-etc/tz"
MP=/tmp/tzdata-extract
sudo umount "$MP" 2>/dev/null || true
mkdir -p "$MP"
LP=$(sudo losetup -o 4096 -f --show "$TZ_APEX")
sudo mount -t erofs -o ro "$LP" "$MP"
cp -a "$MP/etc/tz/"* "$BOOT/tzdata-etc/tz/"
sudo umount "$MP"
sudo losetup -d "$LP" 2>/dev/null
ls -la "$BOOT/tzdata-etc/tz/versioned/9/icu/"
MK="$BOOT/Makefile"
if ! grep -q 'initrd/boot/tzdata-etc' "$MK"; then
  sed -i '/initrd\/boot\/i18n-javalib/a\\tmkdir -p initrd/boot/tzdata-etc\n\t@test -d tzdata-etc/tz \&\& cp -a tzdata-etc/tz initrd/boot/tzdata-etc/ || echo "henry-7CG skip initrd tzdata-etc"' "$MK"
fi
cd "$BOOT"
echo "7CG=$(grep -c 'henry-7CG' stage2.sh || true)"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -1
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND159_DONE
