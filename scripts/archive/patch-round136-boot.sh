#!/bin/bash
# Round 136: odsign LD_LIBRARY_PATH bionic/system before art lib64
set -e
BOOT=~/app-player/hd/guest/BootImage
cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
sed -i 's/\r$//' "$BOOT/stage2.sh"
cd "$BOOT"
echo "7BR=$(grep -c 'henry-7BR odsign LD_LIBRARY_PATH=bionic' stage2.sh || true)"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -1
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND136_DONE
