#!/bin/bash
# Round 26: fix baklava64 system bind mount + prior apex/linker fixes (initrd only)
set -euo pipefail
bash ~/patch-initsh-baklava-bind-system.sh
bash ~/patch-initsh-baklava-apex.sh 2>/dev/null || true
cp ~/stage2-good-vhd.sh ~/app-player/hd/guest/BootImage/stage2.sh
BOOT=~/app-player/hd/guest/BootImage
cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -5
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -5
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
grep -n "bind /boot/android/android/system" init.sh
echo ROUND26_DONE
