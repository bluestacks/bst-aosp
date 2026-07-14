#!/bin/bash
# Round 160: R159b — direct cat-copy tzdata ICU into apex mp (no bind overlay)
set -e
BOOT=~/app-player/hd/guest/BootImage
cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
sed -i 's/\r$//' "$BOOT/stage2.sh"
cd "$BOOT"
echo "7CG=$(grep -c 'henry-7CG' stage2.sh || true)"
grep -q 'tzdata-initrd-staged' stage2.sh && echo "R160-direct-copy=ok"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -1
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND160_DONE
