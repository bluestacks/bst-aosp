#!/bin/bash
# Round 81: ld.config golden patch for /data/art-libs + /data/i18n-libs (namespace search)
set -e
BOOT=~/app-player/hd/guest/BootImage

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
sed -i 's/\r$//' "$BOOT/stage2.sh"

cp ~/patch-ldconfig-bs-bringup.py "$BOOT/"
python3 "$BOOT/patch-ldconfig-bs-bringup.py"
grep -c '/data/art-libs' "$BOOT/linkerconfig/ld.config.txt"
grep -c '/data/i18n-libs' "$BOOT/linkerconfig/ld.config.txt"

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -6
zcat initrd.img | cpio -t 2>/dev/null | grep 'linkerconfig/ld.config.txt'
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND81_DONE
