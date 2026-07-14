#!/bin/bash
# Hot-replace android/ with system.sfs only (henry path, needs CONFIG_SQUASHFS).
set -euo pipefail
STAGE="${ANDROIDOUTPUTLOC:-$HOME/releases}/Baklava64"
FS="$STAGE/Root.fs"
SFS="$STAGE/system.sfs"
OUT="$STAGE/bst-v5.22.210_Baklava64-local"
MP=/mnt/bstroot-hot
BS=~/app-player/buildscripts

[ -f "$SFS" ] || { echo "missing $SFS" >&2; exit 1; }
[ -f "$FS" ] || { echo "missing $FS" >&2; exit 1; }

sudo umount "$MP" 2>/dev/null || true
sudo qemu-nbd -d /dev/nbd0 2>/dev/null || true
sleep 1
sudo modprobe nbd max_part=8
sudo qemu-nbd -f raw -c /dev/nbd0 "$FS"
sleep 3
sudo mkdir -p "$MP"
sudo mount /dev/nbd0 "$MP"
echo BEFORE:; ls -la "$MP/android/"
sudo rm -f "$MP/android/system.img" "$MP/android/system.sfs" 2>/dev/null || true
sudo cp -a "$SFS" "$MP/android/system.sfs"
sudo rm -rf "$MP/android/system" 2>/dev/null || true
sync
echo AFTER:; ls -la "$MP/android/"
sudo umount "$MP"
sudo qemu-nbd -d /dev/nbd0

sed -i "/Root./d" ~/.config/VirtualBox/VirtualBox.xml 2>/dev/null || true
cp -a ~/app-player/hd/guest/FileSystem/Baklava64/Root_Blank.vdi "$OUT/Root.vdi"
cd "$BS"
bash -x ./create_vdi.sh -t root -v "$OUT/Root.vdi" -f "$FS"
mv "$OUT/Root.vhd" "$OUT/Root.vhd.bak-pre-sfs-$(date +%H%M)" 2>/dev/null || true
VBoxManage clonehd "$OUT/Root.vdi" "$OUT/Root.vhd" --format VHD --variant Standard
VBoxManage internalcommands sethduuid "$OUT/Root.vhd" 54e9ad31-a169-4d5b-a0e0-705d62e96e71
ls -la "$OUT/Root.vdi" "$OUT/Root.vhd"
echo REPACK_SFS_DONE
