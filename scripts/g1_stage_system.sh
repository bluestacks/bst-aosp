#!/bin/bash
# G1: stage the OUT system/ dir -> releases/Baklava64/system (Layer2 prep).
# KEY (per buildscripts/Makefile copy_android_files_to_outputdir): stage the OUT
# `target/product/qvirt/system/` DIRECTORY directly — it carries vendor/, system_ext/,
# product/ as SUBDIRS (the fold). Mounting system.img LOSES those subdirs (system.img is
# system-only), which is why the earlier m-systemimage/m-droid stage missed vendor content.
set -euo pipefail
AOSP=~/aosp16
OD=~/releases/Baklava64
SYS_OUT="$AOSP/out_nxt_Baklava64/target/product/qvirt/system"
IMG="$AOSP/out_nxt_Baklava64/target/product/qvirt/system.img"
LOG=~/g1_stage_system.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:G1: stage-system (OUT dir fold) start $(date -Is)"

# Prefer the OUT system/ dir (has vendor/system_ext/product subdirs = fold).
if [ -d "$SYS_OUT" ] && [ -f "$SYS_OUT/build.prop" ]; then
  SRC="$SYS_OUT"
  echo "staging from OUT dir $SRC (fold: vendor/system_ext/product subdirs included)"
else
  # Fallback: mount system.img (system-only, loses subdirs — last resort)
  [ -f "$IMG" ] || { echo "missing $IMG and $SYS_OUT"; exit 1; }
  MNT=$(mktemp -d)
  trap "sudo umount '$MNT' 2>/dev/null || true; rmdir '$MNT' 2>/dev/null || true" EXIT
  sudo mount -o loop,ro "$IMG" "$MNT"
  SRC="$MNT"; [ -f "$MNT/system/build.prop" ] && SRC="$MNT/system"
  echo "WARN: fallback to system.img mount $SRC (no fold)"
fi

mkdir -p "$OD/system"
sudo rsync -a --delete --numeric-ids "$SRC"/ "$OD/system/"
sudo chown -R "$(id -u):$(id -g)" "$OD/system"

echo "A16DBG:G1: staged system bytes=$(du -sb "$OD/system" | awk '{print $1}')"
echo "=== fold readback (subdirs present) ==="
for sub in vendor system_ext product; do
  n=$(find "$OD/system/$sub" -type f 2>/dev/null | wc -l)
  echo "  $sub: $n files"
done
ls -la "$OD/system/build.prop" "$OD/system/etc/init/hw/init.rc" 2>/dev/null | head -5
grep -E 'ro.product.device|ro.product.name' "$OD/system/build.prop" || true
echo "A16DBG:G1: stage-system DONE"
