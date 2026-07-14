#!/bin/bash
# R229: Henry goldfish mmm (VsyncThread sp fix) + system.sfs + Root.vhd repack.
set -euo pipefail
OD=~/releases/Baklava64
PKG=bst-v5.22.210_Baklava64-local
OUT=$OD/$PKG
BS=~/app-player/buildscripts
AOSP=~/aosp16
GGL=~/ggl/goldfish-opengl-pie
LOG=~/r229-rebuild.log
exec > >(tee "$LOG") 2>&1
echo "=== R229 goldfish+Root $(date) ==="

python3 ~/patch-goldfish-emuhwc2-vsync-sp.py

cd "$AOSP"
set +u
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 ALLOW_MISSING_DEPENDENCIES=true
export HD_SOURCE_TOP=~/app-player/hd
source build/envsetup.sh
lunch android_x86_64-trunk_staging-eng
set -u
mmm ../ggl/goldfish-opengl-pie/system/hwc2 BUILD_EMULATOR_OPENGL=true BUILD_EMULATOR_OPENGL_DRIVER=true -j"$(nproc)"

HWC="$AOSP/out_nxt_Baklava64/target/product/x86_64/system/vendor/lib64/hw/hwcomposer.android_x86_64.so"
[ -f "$HWC" ] || HWC="$AOSP/out_nxt_Baklava64/target/product/x86_64/vendor/lib64/hw/hwcomposer.android_x86_64.so"
[ -f "$HWC" ] || HWC="$AOSP/out_nxt_Baklava64/target/product/x86_64/vendor/lib64/hw/hwcomposer.default.so"
[ -f "$HWC" ] || { echo "hwcomposer module missing after mmm" >&2; exit 1; }
# Guest init loads hwcomposer.default.so (no ro.hardware.hwcomposer override).
cp -a "$HWC" "$OD/system/vendor/lib64/hw/hwcomposer.default.so"
md5sum "$HWC" "$OD/system/vendor/lib64/hw/hwcomposer.default.so"

export IMAGE=Baklava64 PKG=$PKG
bash ~/r228-pack-root.sh
echo R229_REBUILD_DONE
