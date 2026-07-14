#!/bin/bash
# Round 66: statsd APEX libstatspull for odsign linker
set -e
BOOT=~/app-player/hd/guest/BootImage
cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh" 2>/dev/null || \
    cp "$(dirname "$0")/stage2-good-vhd.sh" "$BOOT/stage2.sh"
if [ -f ~/init.sh.remote ]; then
    cp ~/init.sh.remote "$BOOT/init.sh"
elif [ -f "$(dirname "$0")/init.sh.remote" ]; then
    cp "$(dirname "$0")/init.sh.remote" "$BOOT/init.sh"
fi
sed -i 's/\r$//' "$BOOT/stage2.sh" "$BOOT/init.sh"
cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -4
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND66_DONE
