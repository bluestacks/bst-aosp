#!/bin/bash
# R246: stage2 metadata tmpfs + expanded bs_bootlog → initrd/fastboot
set -eo pipefail
BOOT=~/app-player/hd/guest/BootImage
KDIR=~/aosp16/kernel-a16
LOG=~/r246-rebuild-fastboot.log
exec > >(tee "$LOG") 2>&1
echo "=== R246 rebuild $(date) ==="

bash ~/bst-aosp/scripts/r246-patch-stage2-metadata.sh "$BOOT/stage2.sh"
cp -f ~/bst-aosp/scripts/bs_bootlog.sh "$BOOT/bs_bootlog.sh"
sed -i 's/\r$//' "$BOOT/stage2.sh" "$BOOT/bs_bootlog.sh"
chmod 755 "$BOOT/stage2.sh" "$BOOT/bs_bootlog.sh"

cd "$BOOT"
if [ ! -d "$KDIR" ]; then
  echo "ERROR: KDIR missing: $KDIR" >&2
  exit 1
fi

make initrd.img KDIR="$KDIR" 2>&1 | tail -5
echo INITRD_OK
ls -la initrd.img
zgrep -a 'R246 metadata' initrd.img 2>/dev/null | head -3 || zcat initrd.img 2>/dev/null | cpio -t 2>/dev/null | grep stage2

make build_fastboot KDIR="$KDIR" 2>&1 | tail -5
echo FASTBOOT_OK
FB=fastboot/fastboot.vdi
[ -f "$FB" ] || FB=fastboot.vdi
VBoxManage internalcommands sethduuid "$FB" 91b80c95-aa7d-459d-93e4-c479f5babbb7
ls -la "$FB"
md5sum "$FB"

OUT=~/releases/Baklava64/bst-v5.22.210_Baklava64-local
mkdir -p "$OUT"
cp -a "$FB" "$OUT/fastboot.vdi"
md5sum "$OUT/fastboot.vdi"
echo R246_REBUILD_DONE
