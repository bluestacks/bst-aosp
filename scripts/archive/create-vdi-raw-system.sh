#!/bin/bash
set -euo pipefail
OUT=~/releases/Baklava64/bst-v5.22.210_Baklava64-local
FS=~/releases/Baklava64/Root.fs
BS=~/app-player/buildscripts

sudo qemu-nbd -d /dev/nbd0 2>/dev/null || true
sudo qemu-nbd -d /dev/nbd1 2>/dev/null || true
sleep 2
sed -i "/Root./d" ~/.config/VirtualBox/VirtualBox.xml 2>/dev/null || true

cp -a ~/app-player/hd/guest/FileSystem/Baklava64/Root_Blank.vdi "$OUT/Root.vdi"
ls -la "$OUT/Root.vdi"
sudo qemu-nbd -c /dev/nbd0 "$OUT/Root.vdi"
lsblk /dev/nbd0
sudo qemu-nbd -d /dev/nbd0

cd "$BS"
bash -x ./create_vdi.sh -t root -v "$OUT/Root.vdi" -f "$FS"

sed -i "/Root./d" ~/.config/VirtualBox/VirtualBox.xml 2>/dev/null || true
mv "$OUT/Root.vhd" "$OUT/Root.vhd.bak-pre-raw2-$(date +%H%M)" 2>/dev/null || true
VBoxManage clonehd "$OUT/Root.vdi" "$OUT/Root.vhd" --format VHD --variant Standard
VBoxManage internalcommands sethduuid "$OUT/Root.vhd" 54e9ad31-a169-4d5b-a0e0-705d62e96e71
ls -la "$OUT/Root.vdi" "$OUT/Root.vhd"
echo CREATE_VDI_RAW_DONE
