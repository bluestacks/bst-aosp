#!/bin/bash
# R228: Henry create_rootfs + create_vdi — update Root.fs android/system.sfs only.
set -euo pipefail
OD=~/releases/Baklava64
PKG=bst-v5.22.210_Baklava64-local
OUT=$OD/$PKG
BS=~/app-player/buildscripts
UUID=54e9ad31-a169-4d5b-a0e0-705d62e96e71
LOG=~/r228-pack-root.log
exec > >(tee "$LOG") 2>&1
echo "=== R228 Henry pack Root $(date) ==="

bash ~/prune-vendor-gralloc-hw.sh "$OD"

sudo umount -l "$OD/rootFS" 2>/dev/null || true
sudo umount -l /mnt/bstroot 2>/dev/null || true
sudo qemu-nbd -d /dev/nbd0 2>/dev/null || true
sudo qemu-nbd -d /dev/nbd4 2>/dev/null || true
sudo qemu-nbd -d /dev/nbd5 2>/dev/null || true

bash -x "$BS/make-baklava-system-sfs.sh" "$OD"
md5sum "$OD/system.sfs"

if ! sudo mount -o loop "$OD/Root.fs" /mnt/bstroot 2>/dev/null; then
  echo "recreate Root.fs (corrupt or missing)"
  dd if=/dev/zero of="$OD/Root.fs" bs=1024 count=6291456 status=none
  mkfs.ext4 -m 1 -L root -F "$OD/Root.fs"
fi
sudo umount /mnt/bstroot 2>/dev/null || true

sudo umount -l "$OD/rootFS" 2>/dev/null || true
rm -rf "$OD/rootFS"
mkdir -p "$OD/rootFS"
sudo mount -o loop "$OD/Root.fs" "$OD/rootFS"
sudo chown -R "$(id -u):$(id -g)" "$OD/rootFS"
mkdir -p "$OD/rootFS/android"
[ -f "$OD/ramdisk.img" ] && cp -a "$OD/ramdisk.img" "$OD/rootFS/android/"
cp -a "$OD/system.sfs" "$OD/rootFS/android/"
[ -d "$OD/dataFS" ] && cp -a "$OD/dataFS" "$OD/rootFS/"
sync
ls -la "$OD/rootFS/android/"
sudo umount "$OD/rootFS"

export IMAGE=Baklava64 PKG=$PKG
cd "$BS"
bash -x ./create_vdi.sh -t root -v "$OUT/Root.vdi" -f "$OD/Root.fs"
sed -i "/Root./d" ~/.config/VirtualBox/VirtualBox.xml 2>/dev/null || true
mv "$OUT/Root.vhd" "$OUT/Root.vhd.bak-$(date +%H%M%S)" 2>/dev/null || true
VBoxManage clonehd "$OUT/Root.vdi" "$OUT/Root.vhd" --format VHD --variant Standard
VBoxManage internalcommands sethduuid "$OUT/Root.vhd" "$UUID"

md5sum "$OUT/Root.vhd" "$OD/system.sfs"
grep -c bs_bootlog "$OD/system/etc/init/hw/init.rc"
echo R228_ROOT_PACK_DONE
