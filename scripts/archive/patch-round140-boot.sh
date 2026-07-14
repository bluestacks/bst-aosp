#!/bin/bash
# Round 140: ld.config com_android_art += runtime bionic (dex2oat64 libc.so)
set -e
BOOT=~/app-player/hd/guest/BootImage
cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
cp ~/patch-ldconfig-r140-bionic.py "$BOOT/"
sed -i 's/\r$//' "$BOOT/stage2.sh" "$BOOT/patch-ldconfig-r140-bionic.py"
python3 "$BOOT/patch-ldconfig-r140-bionic.py"
grep -c 'runtime/${LIB}/bionic' "$BOOT/linkerconfig/ld.config.txt"
grep 'henry-7AA ld.config' "$BOOT/stage2.sh"
cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -1
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND140_DONE
