#!/bin/bash
# Round 151: odrefresh bin/ wrapper (odsign logwrapper libc fix) + logcat oracle
set -e
BOOT=~/app-player/hd/guest/BootImage
cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
sed -i 's/\r$//' "$BOOT/stage2.sh"
cd "$BOOT"
echo "7CA=$(grep -c 'henry-7CA odrefresh' stage2.sh || true)"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -1
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND151_DONE
