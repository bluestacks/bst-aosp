#!/bin/bash
# R239: stage audio HAL (7.0-impl + 7.1 alias) + audio.service → system.sfs → Root.vhd
set -euo pipefail
OD=~/releases/Baklava64
PKG=bst-v5.22.210_Baklava64-local
OUT=~/aosp16/out_nxt_Baklava64/target/product/x86_64/system
LOG=~/r239-pack-audio.log
exec > >(tee "$LOG") 2>&1
echo "=== R239 audio HAL pack $(date) ==="

VENDOR_HW="$OUT/vendor/lib64/hw"
VENDOR_BIN="$OUT/vendor/bin/hw"
for f in \
  "$VENDOR_HW/android.hardware.audio@7.0-impl.so" \
  "$VENDOR_HW/android.hardware.audio.effect@7.0-impl.so" \
  "$VENDOR_BIN/android.hardware.audio.service"; do
  [ -f "$f" ] || { echo "missing build artifact: $f" >&2; exit 1; }
done

mkdir -p "$OD/system/vendor/lib64/hw" "$OD/system/vendor/bin/hw"
cp -a "$VENDOR_HW/android.hardware.audio@7.0-impl.so" "$OD/system/vendor/lib64/hw/"
cp -a "$VENDOR_HW/android.hardware.audio.effect@7.0-impl.so" "$OD/system/vendor/lib64/hw/"
cp -a "$VENDOR_BIN/android.hardware.audio.service" "$OD/system/vendor/bin/hw/"
# Passthrough lookup tries 7.1 first; alias 7.0 impl until ranchu 7.1 is in product graph.
cp -a "$OD/system/vendor/lib64/hw/android.hardware.audio@7.0-impl.so" \
  "$OD/system/vendor/lib64/hw/android.hardware.audio@7.1-impl.so"
ls -la "$OD/system/vendor/lib64/hw/android.hardware.audio@"* "$OD/system/vendor/bin/hw/android.hardware.audio.service"
md5sum "$OD/system/vendor/lib64/hw/android.hardware.audio@"*.so

bash ~/app-player/buildscripts/make-baklava-system-sfs.sh "$OD"
md5sum "$OD/system.sfs"

export IMAGE=Baklava64 PKG=$PKG
bash ~/r228-pack-root.sh
echo R239_PACK_DONE
