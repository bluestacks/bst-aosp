#!/bin/bash
# Repack Root.fs android/ with system.sfs only — no full make Root.vdi (avoids dataFS churn)
set -euo pipefail
export ANDROIDOUTPUTLOC="${ANDROIDOUTPUTLOC:-$HOME/releases}"
export IMAGE="${IMAGE:-Baklava64}"
export PKG="${PKG:-bst-v5.22.210_Baklava64-local}"
OUT="$ANDROIDOUTPUTLOC/$IMAGE/$PKG"
FS="$ANDROIDOUTPUTLOC/$IMAGE/Root.fs"
BS=~/app-player/buildscripts

cp ~/make-baklava-system-sfs.sh "$BS/make-baklava-system-sfs.sh"
chmod +x "$BS/make-baklava-system-sfs.sh"
python3 ~/patch-initsh-baklava-system-sfs.py

STAGE="$ANDROIDOUTPUTLOC/$IMAGE"
[ -d "$STAGE/system" ] || { echo "missing $STAGE/system" >&2; exit 1; }

# Ensure henry adbd in staged system before imaging
ADBD=~/app-player/tools/tiramisu/adbd_rooted_tiramisu
[ -f "$ADBD" ] && cp -a "$ADBD" "$STAGE/system/bin/adbd"

# Skip squashfs if system.img already built and unchanged
if [ ! -f "$STAGE/system.img" ] || [ "$STAGE/system" -nt "$STAGE/system.img" ]; then
    bash -x "$BS/make-baklava-system-sfs.sh" "$STAGE"
fi
# make-baklava-system-sfs also creates system.sfs; we only need system.img for guest

[ -f "$FS" ] || { echo "missing $FS" >&2; exit 1; }
MP=/mnt/bstroot-repack
sudo umount "$MP" 2>/dev/null || true
sudo umount /mnt/bstroot 2>/dev/null || true
sudo qemu-nbd -d /dev/nbd0 2>/dev/null || true
sudo mkdir -p "$MP"
sudo mount -o loop "$FS" "$MP"
sudo rm -rf "$MP/android/system"
sudo cp -a "$STAGE/system.img" "$MP/android/system.img"
# system.sfs needs CONFIG_SQUASHFS (off in bst kernel); ship ext4 system.img only
sudo rm -f "$MP/android/system.sfs" 2>/dev/null || true
ls -la "$MP/android/"
sync
sudo umount "$MP"
cd "$BS"
bash -x ./create_vdi.sh -t root -v "$OUT/Root.vdi" -f "$FS"
sed -i "/Root./d" ~/.config/VirtualBox/VirtualBox.xml 2>/dev/null || true
mv "$OUT/Root.vhd" "$OUT/Root.vhd.bak-pre-sfs-$(date +%H%M)" 2>/dev/null || true
VBoxManage clonehd "$OUT/Root.vdi" "$OUT/Root.vhd" --format VHD --variant Standard
VBoxManage internalcommands sethduuid "$OUT/Root.vhd" 54e9ad31-a169-4d5b-a0e0-705d62e96e71
ls -la "$OUT/Root.vdi" "$OUT/Root.vhd" "$MP/android/system.sfs" 2>/dev/null || ls -la "$STAGE/system.sfs"
echo REPACK_ROOT_SYSTEM_SFS_DONE
