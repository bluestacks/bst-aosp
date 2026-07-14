#!/bin/bash
# Round 25: init.sh runtime apex pre-mount + stage2 linker64 bind (initrd only)
set -euo pipefail
bash ~/patch-initsh-baklava-apex.sh
cp ~/stage2-good-vhd.sh ~/app-player/hd/guest/BootImage/stage2.sh
BOOT=~/app-player/hd/guest/BootImage
cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -5
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -5
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
ls -la fastboot/fastboot.vdi
echo ROUND25_DONE
