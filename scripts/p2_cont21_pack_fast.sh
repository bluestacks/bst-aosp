#!/bin/bash
# Fast finish cont21 pack: cleanup hung r228, remount without sync, recreate VDI/VHD.
set -euo pipefail
LOG=~/p2_cont21_pack_fast.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:pack_fast start $(date -Is)"

OD=~/releases/Baklava64
PKG=bst-v5.22.210_Baklava64-local
OUT=$OD/$PKG
BS=~/app-player/buildscripts
UUID=54e9ad31-a169-4d5b-a0e0-705d62e96e71

# 1) kill hung pack tree
pkill -f 'p2_full_pack_after_droid' 2>/dev/null || true
pkill -f 'r228-pack-root' 2>/dev/null || true
pkill -f 'p2_await_c21' 2>/dev/null || true
sleep 2
# kill stuck tar/gzip under sudo if still around
sudo pkill -f 'tar -zxpf /tmp/srcmnt.tar.gz' 2>/dev/null || true
sudo pkill -f 'tar -zcpf /tmp/srcmnt.tar.gz' 2>/dev/null || true
sleep 2

# 2) cleanup mounts / nbd
sudo umount -l "$OUT/fs-to-vdi-dst" 2>/dev/null || true
sudo umount -l "$OUT/fs-to-vdi-src" 2>/dev/null || true
sudo umount -l "$OD/rootFS" 2>/dev/null || true
sudo umount -l /mnt/bstroot 2>/dev/null || true
sudo qemu-nbd -d /dev/nbd4 2>/dev/null || true
sudo qemu-nbd -d /dev/nbd0 2>/dev/null || true
sudo qemu-nbd -d /dev/nbd5 2>/dev/null || true
sleep 1

# 3) ensure system.sfs exists (already built this morning)
ls -la "$OD/system.sfs"
md5sum "$OD/system.sfs"

# 4) refresh Root.fs android/system.sfs (same as r228 mid-section)
sudo umount -l "$OD/rootFS" 2>/dev/null || true
rm -rf "$OD/rootFS"
mkdir -p "$OD/rootFS"
sudo mount -o loop "$OD/Root.fs" "$OD/rootFS"
sudo chown -R "$(id -u):$(id -g)" "$OD/rootFS"
mkdir -p "$OD/rootFS/android"
[ -f "$OD/ramdisk.img" ] && cp -a "$OD/ramdisk.img" "$OD/rootFS/android/"
cp -a "$OD/system.sfs" "$OD/rootFS/android/"
[ -d "$OD/dataFS" ] && cp -a "$OD/dataFS" "$OD/rootFS/" || true
sync
ls -la "$OD/rootFS/android/"
sudo umount "$OD/rootFS"

# 5) patch create_vdi mounts: drop dirsync,sync for speed (restore after)
CV=$BS/create_vdi.sh
cp -a "$CV" "$CV.bak.cont21"
sed -i 's/dirsync,sync,loop,ro/loop,ro/g; s/dirsync,sync,rw/rw/g' "$CV"
echo "patched create_vdi mounts (no sync)"
rg -n 'mount -o' "$CV" | head -10

# 6) create_vdi + clone to VHD
export IMAGE=Baklava64 PKG=$PKG
cd "$BS"
bash -x ./create_vdi.sh -t root -v "$OUT/Root.vdi" -f "$OD/Root.fs"
# restore create_vdi
mv "$CV.bak.cont21" "$CV"
echo "restored create_vdi.sh"

sed -i "/Root./d" ~/.config/VirtualBox/VirtualBox.xml 2>/dev/null || true
ts=$(date +%H%M%S)
mv "$OUT/Root.vhd" "$OUT/Root.vhd.bak-$ts" 2>/dev/null || true
VBoxManage clonehd "$OUT/Root.vdi" "$OUT/Root.vhd" --format VHD --variant Standard
VBoxManage internalcommands sethduuid "$OUT/Root.vhd" "$UUID"
md5sum "$OUT/Root.vhd" "$OD/system.sfs"
echo R228_ROOT_PACK_DONE
echo "A16DBG:P2:pack_fast DONE $(date -Is)"
