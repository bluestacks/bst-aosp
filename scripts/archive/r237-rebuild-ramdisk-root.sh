#!/bin/bash
# R237: skiavkthreaded RenderEngine → make ramdisk → Root repack (Henry path).
set -euo pipefail
OD=~/releases/Baklava64
PKG=bst-v5.22.210_Baklava64-local
AOSP=~/aosp16
LOG=~/r237-rebuild.log
exec > >(tee "$LOG") 2>&1
echo "=== R237 skiavk ramdisk+Root $(date) ==="

python3 ~/patch-device-init-x86-renderengine-skiavk-a16.py
grep -A3 'renderengine' ~/aosp16/device/generic/common/init.x86.rc

cd "$AOSP"
set +u
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 ALLOW_MISSING_DEPENDENCIES=true
export HD_SOURCE_TOP=~/app-player/hd
source build/envsetup.sh
lunch android_x86_64-trunk_staging-eng
set -u

mmm ramdisk -j"$(nproc)" || make ramdisk -j"$(nproc)"

RAMDISK="$AOSP/out_nxt_Baklava64/target/product/x86_64/ramdisk.img"
[ -f "$RAMDISK" ] || RAMDISK="$AOSP/out_nxt_Baklava64/target/product/generic_x86_64/ramdisk.img"
[ -f "$RAMDISK" ] || { echo "missing ramdisk.img" >&2; exit 1; }

cp -a "$RAMDISK" "$OD/ramdisk.img"
md5sum "$OD/ramdisk.img" "$RAMDISK"

TMP=$(mktemp -d)
gzip -dc "$RAMDISK" | (cd "$TMP" && cpio -idm 2>/dev/null)
grep -E 'renderengine|hwui' "$TMP/init.baklava.rc"
rm -rf "$TMP"

export IMAGE=Baklava64 PKG=$PKG
bash ~/r228-pack-root.sh
echo R237_REBUILD_DONE
