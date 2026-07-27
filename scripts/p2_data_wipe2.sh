#!/bin/bash
set -eo pipefail
MP=/mnt/data-p2-wipe
NBD=/dev/nbd8
DATA=~/Data.vhdx.p2wipe
LOG=~/p2_data_wipe2.log
exec > >(tee "$LOG") 2>&1
sudo umount "$MP" 2>/dev/null || true
sudo qemu-nbd -d "$NBD" 2>/dev/null || true
sudo modprobe nbd max_part=16
sudo qemu-nbd -f vpc -c "$NBD" "$DATA" || sudo qemu-nbd -c "$NBD" "$DATA"
sleep 2
sudo mkdir -p "$MP"
sudo mount ${NBD}p1 "$MP" || sudo mount "$NBD" "$MP"
echo MOUNTED
sudo ls "$MP" | head
for d in \
  "$MP/misc/keystore" "$MP/data/misc/keystore" \
  "$MP/misc/keychain" "$MP/data/misc/keychain" \
  "$MP/misc/odsign" "$MP/data/misc/odsign" \
  "$MP/dalvik-cache" "$MP/data/dalvik-cache"
do
  if sudo test -e "$d"; then echo REMOVE "$d"; sudo rm -rf "$d"; fi
done
while IFS= read -r d; do
  echo REMOVE "$d"; sudo rm -rf "$d"
done < <(sudo find "$MP" -type d -name 'dalvik-cache' 2>/dev/null)
sync
sudo umount "$MP"
sudo qemu-nbd -d "$NBD"
echo WIPE_DONE
