#!/bin/bash
# R247: expanded bs_bootlog (installd/init) → initrd/fastboot only
set -eo pipefail
BOOT=~/app-player/hd/guest/BootImage
KDIR=~/aosp16/kernel-a16
LOG=~/r247-rebuild-fastboot.log
exec > >(tee "$LOG") 2>&1
echo "=== R247 fastboot $(date) ==="
cp -f ~/bst-aosp/scripts/bs_bootlog.sh "$BOOT/bs_bootlog.sh"
sed -i 's/\r$//' "$BOOT/bs_bootlog.sh"
chmod 755 "$BOOT/bs_bootlog.sh"
cd "$BOOT"
make initrd.img KDIR="$KDIR" 2>&1 | tail -5
make build_fastboot KDIR="$KDIR" 2>&1 | tail -5
FB=fastboot/fastboot.vdi
VBoxManage internalcommands sethduuid "$FB" 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum "$FB"
cp -a "$FB" ~/releases/Baklava64/bst-v5.22.210_Baklava64-local/fastboot.vdi
echo R247_FASTBOOT_DONE
