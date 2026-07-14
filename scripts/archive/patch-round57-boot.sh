#!/bin/bash
# Round 57: henry 7P/7Q early build.prop + keystore2 enable + odsign kmsg wrapper
set -e
BOOT=~/app-player/hd/guest/BootImage
cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh" 2>/dev/null || \
    cp "$(dirname "$0")/stage2-good-vhd.sh" "$BOOT/stage2.sh"
cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -4
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND57_DONE
