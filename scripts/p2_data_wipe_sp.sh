#!/bin/bash
# Full credential wipe: keystore + locksettings + spblob (fixes SP protector key missing)
set -eo pipefail
MP=/mnt/data-p2-wipe
NBD=/dev/nbd8
DATA=~/Data.vhdx.p2wipe
LOG=~/p2_data_wipe_sp.log
exec > >(tee "$LOG") 2>&1
echo "=== SP wipe $(date -Is) ==="
sudo umount "$MP" 2>/dev/null || true
sudo qemu-nbd -d "$NBD" 2>/dev/null || true
sudo modprobe nbd max_part=16
sudo qemu-nbd -c "$NBD" "$DATA" || sudo qemu-nbd -f vpc -c "$NBD" "$DATA"
sleep 2
sudo mkdir -p "$MP"
sudo mount ${NBD}p1 "$MP" || sudo mount "$NBD" "$MP"
echo MOUNTED
sudo ls "$MP" | head
# credential / lock surfaces
for d in \
  "$MP/misc/keystore" "$MP/misc/keychain" "$MP/misc/odsign" \
  "$MP/dalvik-cache" \
  "$MP/system/locksettings.db" "$MP/system/locksettings.db-shm" "$MP/system/locksettings.db-wal" \
  "$MP/system/locksettings.db-journal" \
  "$MP/system/gatekeeper.password.key" "$MP/system/gatekeeper.pattern.key" \
  "$MP/system/users"
do
  :
done
# remove locksettings db files
sudo rm -fv "$MP"/system/locksettings.db* 2>/dev/null || true
sudo rm -fv "$MP"/system/gatekeeper.* 2>/dev/null || true
# spblob under users
if sudo test -d "$MP/system/users"; then
  sudo find "$MP/system/users" -type d -name 'spblob' 2>/dev/null | while read -r d; do
    echo REMOVE "$d"; sudo rm -rf "$d"
  done
  sudo find "$MP/system/users" -name '*synthetic*' 2>/dev/null | while read -r f; do
    echo REMOVE "$f"; sudo rm -rf "$f"
  done
fi
# keystore again
for d in "$MP/misc/keystore" "$MP/misc/keychain" "$MP/misc/odsign" "$MP/dalvik-cache"; do
  if sudo test -e "$d"; then echo REMOVE "$d"; sudo rm -rf "$d"; fi
done
sudo find "$MP" -type d -name 'dalvik-cache' 2>/dev/null | while read -r d; do echo REMOVE "$d"; sudo rm -rf "$d"; done
sync
sudo umount "$MP"
sudo qemu-nbd -d "$NBD"
echo SP_WIPE_DONE
