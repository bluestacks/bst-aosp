#!/bin/bash
set -euo pipefail
OD=~/releases/Baklava64
PKG=bst-v5.22.210_Baklava64-local
OUT=$OD/$PKG
BS=~/app-player/buildscripts
UUID=54e9ad31-a169-4d5b-a0e0-705d62e96e71
LOG=~/henry-r208-rootfs.log
exec > >(tee "$LOG") 2>&1
echo "=== R208 manual Henry create_rootfs + make_vdi $(date) ==="

sudo umount -l "$OD/rootFS" 2>/dev/null || true
sudo umount -l /mnt/bstroot 2>/dev/null || true
sudo qemu-nbd -d /dev/nbd5 2>/dev/null || true

cp ~/aosp16/out_nxt_Baklava64/target/product/x86_64/system/bin/init "$OD/system/bin/init"
md5sum "$OD/system/bin/init"

bash -x "$BS/make-baklava-system-sfs.sh" "$OD"
md5sum "$OD/system.sfs"

if ! sudo mount -o loop "$OD/Root.fs" /mnt/bstroot 2>/dev/null; then
  echo "recreate Root.fs"
  dd if=/dev/zero of="$OD/Root.fs" bs=1024 count=6291456 status=progress
  mkfs.ext4 -m 1 -L root -F "$OD/Root.fs"
fi
sudo umount /mnt/bstroot 2>/dev/null || true

sudo umount -l "$OD/rootFS" 2>/dev/null || true
rm -rf "$OD/rootFS"
mkdir -p "$OD/rootFS"
sudo mount -o loop "$OD/Root.fs" "$OD/rootFS"
sudo chown -R "$(id -u):$(id -g)" "$OD/rootFS"
mkdir -p "$OD/rootFS/android"
cp -a "$OD/ramdisk.img" "$OD/rootFS/android/"
cp -a "$OD/system.sfs" "$OD/rootFS/android/"
cp -a "$OD/dataFS" "$OD/rootFS/"
sync
ls -la "$OD/rootFS/android/"
ls -la "$OD/rootFS/dataFS/" | head
sudo umount "$OD/rootFS"

export IMAGE=Baklava64 PKG=$PKG
cd "$BS"
bash -x ./create_vdi.sh -t root -v "$OUT/Root.vdi" -f "$OD/Root.fs"
sed -i "/Root./d" ~/.config/VirtualBox/VirtualBox.xml 2>/dev/null || true
VBoxManage clonehd "$OUT/Root.vdi" "$OUT/Root.vhd" --format VHD --variant Standard
VBoxManage internalcommands sethduuid "$OUT/Root.vhd" "$UUID"

ls -la "$OUT/Root.vhd"
md5sum "$OUT/Root.vhd"
VBoxManage showhdinfo "$OUT/Root.vhd" | head -6

sudo modprobe nbd max_part=8
sudo qemu-nbd -c /dev/nbd5 "$OUT/Root.vdi"
sleep 2
sudo mkdir -p /mnt/bstroot/sfs-test /mnt/bstroot/sysimg
sudo mount /dev/nbd5p1 /mnt/bstroot
sudo mount -o loop /mnt/bstroot/android/system.sfs /mnt/bstroot/sfs-test
sudo mount -o loop /mnt/bstroot/sfs-test/system.img /mnt/bstroot/sysimg
md5sum /mnt/bstroot/sysimg/bin/init
strings /mnt/bstroot/sysimg/bin/init | grep -E "tmp/init|system/bin/init" | head -5
sudo umount /mnt/bstroot/sysimg /mnt/bstroot/sfs-test /mnt/bstroot
sudo qemu-nbd -d /dev/nbd5
echo R208_ROOT_PACK_DONE
