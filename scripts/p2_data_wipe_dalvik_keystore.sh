#!/bin/bash
# Wipe keystore + dalvik-cache from Data.vhdx (boot image mismatch recovery)
set -eo pipefail
DATA="${1:-$HOME/Data.vhdx.p2wipe}"
MP=/mnt/data-p2-wipe
NBD=/dev/nbd8
LOG=~/p2_data_wipe.log
exec > >(tee "$LOG") 2>&1
echo "=== P2 data wipe $(date -Is) ==="
ls -la "$DATA"
sudo umount "$MP" 2>/dev/null || true
sudo qemu-nbd -d "$NBD" 2>/dev/null || true
sudo modprobe nbd max_part=16
if ! sudo qemu-nbd -f vpc -c "$NBD" "$DATA" 2>/dev/null; then
  sudo qemu-nbd -c "$NBD" "$DATA"
fi
sleep 2
sudo mkdir -p "$MP"
if ! sudo mount "${NBD}p1" "$MP" 2>/dev/null; then
  sudo mount "$NBD" "$MP"
fi
echo "mounted top:"
ls -la "$MP" | head -25
for d in \
  "$MP/misc/keystore" "$MP/data/misc/keystore" \
  "$MP/misc/keychain" "$MP/data/misc/keychain" \
  "$MP/misc/odsign" "$MP/data/misc/odsign" \
  "$MP/dalvik-cache" "$MP/data/dalvik-cache" \
  "$MP/misc/apexdata/com.android.art/dalvik-cache" \
  "$MP/data/misc/apexdata/com.android.art/dalvik-cache"
do
  if [ -e "$d" ]; then
    echo "REMOVE $d"
    sudo rm -rf "$d"
  fi
done
# catch remaining
sudo find "$MP" -type d -name 'dalvik-cache' 2>/dev/null | while read -r d; do
  echo "REMOVE find $d"; sudo rm -rf "$d"
done
sync
sudo umount "$MP"
sudo qemu-nbd -d "$NBD"
echo WIPE_DONE
ls -la "$DATA"
