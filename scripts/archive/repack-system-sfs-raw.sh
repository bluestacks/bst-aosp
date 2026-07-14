#!/bin/bash
# Rebuild system.sfs with raw (non-sparse) system.img inside, repack Root.fs + VDI/VHD.
set -euo pipefail
STAGE="${ANDROIDOUTPUTLOC:-$HOME/releases}/Baklava64"
OUT="$STAGE/bst-v5.22.210_Baklava64-local"
FS="$STAGE/Root.fs"
BS=~/app-player/buildscripts
SIMG="${SIMG:-$HOME/aosp16/out_nxt_Baklava64/host/linux-x86/bin/simg2img}"

[ -f "$STAGE/system.img" ] || { echo "missing sparse system.img" >&2; exit 1; }
[ -x "$SIMG" ] || SIMG="$HOME/aosp16/out_nxt_Baklava64/host/linux-x86/bin/simg2img"

if [ ! -f "$STAGE/system.raw.img" ] || [ "$STAGE/system.img" -nt "$STAGE/system.raw.img" ]; then
    echo "simg2img -> system.raw.img"
    "$SIMG" "$STAGE/system.img" "$STAGE/system.raw.img"
fi
ls -la "$STAGE/system.raw.img"
file "$STAGE/system.raw.img"

echo "mksquashfs raw system.img -> system.sfs (inner name must be system.img)"
rm -f "$STAGE/system.sfs"
SFS_STAGE=$(mktemp -d)
trap 'rm -rf "$SFS_STAGE"' EXIT
cp -a "$STAGE/system.raw.img" "$SFS_STAGE/system.img"
mksquashfs "$SFS_STAGE" "$STAGE/system.sfs" -noappend -comp gzip
ls -la "$STAGE/system.sfs"

MP=/mnt/bstroot-hot
sudo umount "$MP" 2>/dev/null || true
sudo qemu-nbd -d /dev/nbd0 2>/dev/null || true
sleep 1
sudo modprobe nbd max_part=8
sudo qemu-nbd -f raw -c /dev/nbd0 "$FS"
sleep 3
sudo mkdir -p "$MP"
sudo mount /dev/nbd0 "$MP"
sudo rm -f "$MP/android/system.img" "$MP/android/system.sfs"
sudo cp -a "$STAGE/system.sfs" "$MP/android/system.sfs"
sync
ls -la "$MP/android/"
sudo umount "$MP"
sudo qemu-nbd -d /dev/nbd0

sed -i "/Root./d" ~/.config/VirtualBox/VirtualBox.xml 2>/dev/null || true
cp -a ~/app-player/hd/guest/FileSystem/Baklava64/Root_Blank.vdi "$OUT/Root.vdi"
cd "$BS"
bash -x ./create_vdi.sh -t root -v "$OUT/Root.vdi" -f "$FS"
mv "$OUT/Root.vhd" "$OUT/Root.vhd.bak-pre-rawsfs-$(date +%H%M)" 2>/dev/null || true
VBoxManage clonehd "$OUT/Root.vdi" "$OUT/Root.vhd" --format VHD --variant Standard
VBoxManage internalcommands sethduuid "$OUT/Root.vhd" 54e9ad31-a169-4d5b-a0e0-705d62e96e71
ls -la "$OUT/Root.vdi" "$OUT/Root.vhd"
echo RAW_SFS_REPACK_DONE
