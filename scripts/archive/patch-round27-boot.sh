#!/bin/bash
set -euo pipefail
bash ~/patch-initsh-baklava-bind-system.sh
cp ~/stage2-good-vhd.sh ~/app-player/hd/guest/BootImage/stage2.sh
cd ~/app-player/hd/guest/BootImage
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
echo ROUND27_DONE
