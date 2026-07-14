#!/bin/bash
# Round 32: keep ext4 /data + loop nodes + app_process/surfaceflinger bind
set -eo pipefail
BOOT=~/app-player/hd/guest/BootImage
cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -2
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -2
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND32_DONE
