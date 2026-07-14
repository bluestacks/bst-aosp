#!/bin/bash
set -e
IMG=~/app-player/hd/guest/BootImage/art-payload.img
LOOP=$(sudo losetup -f)
sudo losetup "$LOOP" "$IMG"
sudo mkdir -p /tmp/_artmp
sudo mount -t erofs "$LOOP" /tmp/_artmp
ls /tmp/_artmp
echo "lib64_count=$(ls /tmp/_artmp/lib64/*.so 2>/dev/null | wc -l)"
ls -l /tmp/_artmp/lib64/libnativeloader.so /tmp/_artmp/lib64/libart.so 2>&1
sudo umount /tmp/_artmp
sudo losetup -d "$LOOP"
