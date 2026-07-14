#!/bin/bash
# R241: Henry — build audio@7.1-impl + BST audio.primary.bst (treble.mk product fix)
set -euo pipefail
AOSP=~/aosp16
LOG=~/r241-rebuild-audio.log
exec > >(tee "$LOG") 2>&1
echo "=== R241 audio HIDL rebuild $(date) ==="

export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64
export ALLOW_MISSING_DEPENDENCIES=true HD_SOURCE_TOP=$HOME/app-player/hd

cd "$AOSP"
set +u
source build/envsetup.sh
lunch android_x86_64-trunk_staging-eng
set -u

# Verify treble.mk has 7.1-impl in product graph
rg -q 'android.hardware.audio@7.1-impl' device/generic/common/treble.mk

# BST legacy primary HAL (Henry hardware/bst/audio)
mmm hardware/bst/audio

# Generic HIDL passthrough → loads audio.primary.bst via libhardware
m android.hardware.audio@7.1-impl \
  android.hardware.audio@7.0-impl \
  android.hardware.audio.effect@7.0-impl \
  android.hardware.audio.service

OUT_SYS="$AOSP/out_nxt_Baklava64/target/product/x86_64/system"
for f in \
  "$OUT_SYS/vendor/lib64/hw/android.hardware.audio@7.1-impl.so" \
  "$OUT_SYS/vendor/lib64/hw/android.hardware.audio@7.0-impl.so" \
  "$OUT_SYS/vendor/lib64/hw/android.hardware.audio.effect@7.0-impl.so" \
  "$OUT_SYS/vendor/bin/hw/android.hardware.audio.service" \
  "$OUT_SYS/lib64/hw/audio.primary.bst.so"; do
  [ -f "$f" ] || { echo "missing artifact: $f" >&2; exit 1; }
  ls -la "$f"
  md5sum "$f"
done

echo R241_REBUILD_DONE
