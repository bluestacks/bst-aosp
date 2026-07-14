#!/bin/bash
# Round 86: 7AL bs_bootlog path + 7AM logd wrapper + 7AI tombstone/logcat linker
set -e
BOOT=~/app-player/hd/guest/BootImage
ART_BOOT=~/aosp16/out_nxt_Baklava64/host/linux-x86/apex/art_boot_images/javalib/x86_64

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
cp ~/bs_bootlog.sh "$BOOT/bs_bootlog.sh"
sed -i 's/\r$//' "$BOOT/stage2.sh" "$BOOT/bs_bootlog.sh"
chmod 755 "$BOOT/bs_bootlog.sh"

mkdir -p "$BOOT/dalvik-cache/x86_64"
rm -f "$BOOT/dalvik-cache/x86_64"/*
cp -a "$ART_BOOT"/. "$BOOT/dalvik-cache/x86_64/"
ls -la "$BOOT/dalvik-cache/x86_64/boot.art"
echo "boot.art bytes=$(wc -c < "$BOOT/dalvik-cache/x86_64/boot.art")"

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -6
zcat initrd.img | cpio -t 2>/dev/null | grep -E 'bs_bootlog|boot.art'
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND86_DONE
