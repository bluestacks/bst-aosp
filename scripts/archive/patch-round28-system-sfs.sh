#!/bin/bash
# Round 28: system.sfs Root.fs + init.sh apex fix + initrd
set -euo pipefail
bash ~/pack-baklava-root-system-sfs.sh
cp ~/stage2-good-vhd.sh ~/app-player/hd/guest/BootImage/stage2.sh
cd ~/app-player/hd/guest/BootImage
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -5
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -5
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
echo ROUND28_DONE
