#!/bin/bash
# Hot-replace android/system.sfs in Root.vhd (skip slow create_vdi).
set -euo pipefail
STAGE="${ANDROIDOUTPUTLOC:-$HOME/releases}/Baklava64"
OUT="$STAGE/bst-v5.22.210_Baklava64-local"
VHD="$OUT/Root.vhd"
SFS="${1:-$STAGE/system.sfs}"
MP=/mnt/bstroot-hot

[ -f "$SFS" ] || { echo "missing $SFS" >&2; exit 1; }
[ -f "$VHD" ] || { echo "missing $VHD" >&2; exit 1; }

sudo umount "$MP" 2>/dev/null || true
sudo qemu-nbd -d /dev/nbd0 2>/dev/null || true
sleep 1
sudo modprobe nbd max_part=8
sudo qemu-nbd -f vpc -c /dev/nbd0 "$VHD"
sleep 2
sudo mkdir -p "$MP"
sudo mount /dev/nbd0p1 "$MP"
echo "BEFORE:"; ls -la "$MP/android/"
sudo rm -f "$MP/android/system.img" 2>/dev/null || true
sudo cp -a "$SFS" "$MP/android/system.sfs"
sync
echo "AFTER:"; ls -la "$MP/android/"
sudo umount "$MP"
sudo qemu-nbd -d /dev/nbd0
VBoxManage internalcommands sethduuid "$VHD" 54e9ad31-a169-4d5b-a0e0-705d62e96e71
ls -la "$VHD"
echo HOTPATCH_VHD_SFS_DONE
