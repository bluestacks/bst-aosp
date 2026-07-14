#!/bin/bash
# Hot-replace android/system.img in Root.vhd with raw ext4 (skip slow create_vdi).
set -euo pipefail
STAGE="${ANDROIDOUTPUTLOC:-$HOME/releases}/Baklava64"
OUT="$STAGE/bst-v5.22.210_Baklava64-local"
VHD="$OUT/Root.vhd"
RAW="${1:-$STAGE/system.raw.img}"
MP=/mnt/bstroot-hot

[ -f "$RAW" ] || { echo "missing $RAW" >&2; exit 1; }
[ -f "$VHD" ] || { echo "missing $VHD" >&2; exit 1; }

sudo umount "$MP" 2>/dev/null || true
sudo qemu-nbd -d /dev/nbd0 2>/dev/null || true
sleep 1
sudo modprobe nbd max_part=8
sudo qemu-nbd -c /dev/nbd0 "$VHD"
sleep 2
sudo mkdir -p "$MP"
sudo mount /dev/nbd0p1 "$MP"
echo "BEFORE:"; ls -la "$MP/android/"; file "$MP/android/system.img"
sudo cp -a "$RAW" "$MP/android/system.img"
sudo rm -f "$MP/android/system.sfs" 2>/dev/null || true
sync
echo "AFTER:"; ls -la "$MP/android/"; file "$MP/android/system.img"
sudo umount "$MP"
sudo qemu-nbd -d /dev/nbd0
ls -la "$VHD"
echo HOTPATCH_VHD_RAW_DONE
