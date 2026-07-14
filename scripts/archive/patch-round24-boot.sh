#!/bin/bash
# Round 24: stage2 loop-device fix + bootstrap linker64 (initrd only, no Root rebuild)
set -euo pipefail
BOOT=~/app-player/hd/guest/BootImage
cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -5
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -5
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
ls -la fastboot/fastboot.vdi
echo ROUND24_DONE
