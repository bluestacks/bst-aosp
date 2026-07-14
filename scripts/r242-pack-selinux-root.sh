#!/bin/bash
# R242: pack with SELinux file_contexts (Henry-correct path)
set -euo pipefail
OD=~/releases/Baklava64
PKG=bst-v5.22.210_Baklava64-local
LOG=~/r242-pack.log
exec > >(tee "$LOG") 2>&1
echo "=== R242 SELinux file_contexts pack $(date) ==="

# Drop remount/restorecon hack from init.rc — labels come from mkuserimg now
INIT_RC="$OD/system/etc/init/hw/init.rc"
if [ -f "$INIT_RC" ] && grep -q 'BS-A16: restorecon /vendor for HAL exec domains' "$INIT_RC"; then
  # remove the 5-line block we inserted under on boot
  sed -i '/# BS-A16: restorecon \/vendor for HAL exec domains/,/mount -o remount,ro \/system/d' "$INIT_RC"
  echo "removed restorecon remount hack from init.rc"
fi

# Ensure audio artifacts still staged
test -f "$OD/system/vendor/bin/hw/android.hardware.audio.service"
test -f "$OD/system/vendor/lib64/hw/android.hardware.audio@7.1-impl.so"
test -f "$OD/system/lib64/hw/audio.primary.bst.so"

cp -a ~/make-baklava-system-sfs.sh ~/app-player/buildscripts/make-baklava-system-sfs.sh
sed -i 's/\r$//' ~/app-player/buildscripts/make-baklava-system-sfs.sh
bash ~/app-player/buildscripts/make-baklava-system-sfs.sh "$OD"
md5sum "$OD/system.sfs" "$OD/system.img"

export IMAGE=Baklava64 PKG=$PKG
bash ~/r228-pack-root.sh
echo R242_PACK_DONE
