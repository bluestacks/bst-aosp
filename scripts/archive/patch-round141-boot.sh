#!/bin/bash
# Round 141: system namespace search.paths += runtime bionic (dex2oat64 libc.so)
set -e
BOOT=~/app-player/hd/guest/BootImage
cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
cp ~/patch-ldconfig-r141-system-bionic.py "$BOOT/"
sed -i 's/\r$//' "$BOOT/stage2.sh" "$BOOT/patch-ldconfig-r141-system-bionic.py"
python3 "$BOOT/patch-ldconfig-r141-system-bionic.py"
grep -c 'system.search.paths += /apex/com.android.runtime' "$BOOT/linkerconfig/ld.config.txt"
cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -1
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND141_DONE
