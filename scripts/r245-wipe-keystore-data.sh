#!/bin/bash
# R245: wipe keystore DB from Data.vhdx (ext4) so boot-level key can be regenerated.
# Usage: r245-wipe-keystore-data.sh /path/to/Data.vhdx
set -eo pipefail
DATA="${1:?Data.vhdx path}"
MP=/mnt/data-r245-wipe
NBD=/dev/nbd8
LOG=~/r245-wipe-keystore.log
exec > >(tee "$LOG") 2>&1
echo "=== R245 wipe keystore $(date) ==="
ls -la "$DATA"
sudo umount "$MP" 2>/dev/null || true
sudo qemu-nbd -d "$NBD" 2>/dev/null || true
sudo modprobe nbd max_part=16
# try vpc then auto
if ! sudo qemu-nbd -f vpc -c "$NBD" "$DATA" 2>/dev/null; then
  sudo qemu-nbd -c "$NBD" "$DATA"
fi
sleep 2
sudo mkdir -p "$MP"
if ! sudo mount "${NBD}p1" "$MP" 2>/dev/null; then
  sudo mount "$NBD" "$MP"
fi
echo "mounted; top:"
ls -la "$MP" | head -20
echo "--- before ---"
sudo find "$MP" -path '*keystore*' 2>/dev/null | head -50
# Android userdata layout may be /misc/keystore or /data/misc/keystore depending on mount root
for d in \
  "$MP/misc/keystore" \
  "$MP/data/misc/keystore" \
  "$MP/misc/keychain" \
  "$MP/data/misc/keychain" \
  "$MP/misc/odsign" \
  "$MP/data/misc/odsign"
do
  if [ -e "$d" ]; then
    echo "REMOVE $d"
    sudo rm -rf "$d"
  fi
done
# also sqlite blobs under /misc
sudo find "$MP" -iname '*keystore*' 2>/dev/null | while read -r f; do
  echo "RM $f"
  sudo rm -rf "$f"
done
echo "--- after ---"
sudo find "$MP" -path '*keystore*' 2>/dev/null | head -20 || echo 'none'
sync
sudo umount "$MP"
sudo qemu-nbd -d "$NBD"
echo WIPE_DONE
