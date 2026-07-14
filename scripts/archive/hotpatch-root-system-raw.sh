#!/bin/bash
# Hot-replace android/system.img in Root.fs with raw (non-sparse) ext4 image.
set -euo pipefail
STAGE="${ANDROIDOUTPUTLOC:-$HOME/releases}/Baklava64"
FS="$STAGE/Root.fs"
RAW="${1:-$STAGE/system.raw.img}"
OUT="$STAGE/bst-v5.22.210_Baklava64-local"
MP=/mnt/bstroot-hot

[ -f "$RAW" ] || { echo "missing $RAW" >&2; exit 1; }
[ -f "$FS" ] || { echo "missing $FS" >&2; exit 1; }

sudo umount "$MP" 2>/dev/null || true
sudo qemu-nbd -d /dev/nbd0 2>/dev/null || true
sleep 1
sudo modprobe nbd max_part=8
sudo qemu-nbd -f raw -c /dev/nbd0 "$FS"
sleep 3
sudo mkdir -p "$MP"
sudo mount /dev/nbd0 "$MP"
echo "BEFORE:"; ls -la "$MP/android/"
sudo cp -a "$RAW" "$MP/android/system.img"
sudo rm -f "$MP/android/system.sfs" "$MP/android/system" 2>/dev/null || true
sync
echo "AFTER:"; ls -la "$MP/android/"; file "$MP/android/system.img"
sudo umount "$MP"
sudo qemu-nbd -d /dev/nbd0

# Refresh VDI/VHD from updated Root.fs
BS=~/app-player/buildscripts
cd "$BS"
bash -x ./create_vdi.sh -t root -v "$OUT/Root.vdi" -f "$FS"
sed -i "/Root./d" ~/.config/VirtualBox/VirtualBox.xml 2>/dev/null || true
mv "$OUT/Root.vhd" "$OUT/Root.vhd.bak-pre-raw-$(date +%H%M)" 2>/dev/null || true
VBoxManage clonehd "$OUT/Root.vdi" "$OUT/Root.vhd" --format VHD --variant Standard
VBoxManage internalcommands sethduuid "$OUT/Root.vhd" 54e9ad31-a169-4d5b-a0e0-705d62e96e71
ls -la "$OUT/Root.vdi" "$OUT/Root.vhd"
echo HOTPATCH_ROOT_SYSTEM_RAW_DONE
