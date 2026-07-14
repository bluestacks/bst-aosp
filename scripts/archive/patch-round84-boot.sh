#!/bin/bash
# Round 84: 7AF netd stub (stop onrestart→zygote SIGKILL) + keep R83 art-libs
set -e
BOOT=~/app-player/hd/guest/BootImage

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
sed -i 's/\r$//' "$BOOT/stage2.sh"

cd "$BOOT"
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND84_DONE
