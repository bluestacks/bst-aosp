#!/bin/bash
# R231: Henry goldfish mmm (GLES A16 + hwc) + copy libs + Root repack.
set -euo pipefail
OD=~/releases/Baklava64
PKG=bst-v5.22.210_Baklava64-local
OUT=$OD/$PKG
AOSP=~/aosp16
GGL=~/ggl/goldfish-opengl-pie
LOG=~/r231-rebuild.log
exec > >(tee "$LOG") 2>&1
echo "=== R231 goldfish GLES+Root $(date) ==="

python3 ~/patch-goldfish-emuhwc2-vsync-sp.py
python3 ~/patch-goldfish-glutils-a16-params.py
python3 ~/patch-goldfish-gl2encoder-getinternalformat-a16.py

cd "$AOSP"
set +u
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 ALLOW_MISSING_DEPENDENCIES=true
export HD_SOURCE_TOP=~/app-player/hd
source build/envsetup.sh
lunch android_x86_64-trunk_staging-eng
set -u

mmm ../ggl/goldfish-opengl-pie/shared/OpenglCodecCommon \
     ../ggl/goldfish-opengl-pie/system/GLESv2_enc \
     ../ggl/goldfish-opengl-pie/system/hwc2 \
     BUILD_EMULATOR_OPENGL=true BUILD_EMULATOR_OPENGL_DRIVER=true -j"$(nproc)"

PROD="$AOSP/out_nxt_Baklava64/target/product/x86_64"
GLES="$PROD/system/vendor/lib64/libGLESv2_enc.so"
HWC="$PROD/vendor/lib64/hw/hwcomposer.android_x86_64.so"
[ -f "$GLES" ] || GLES="$PROD/system/vendor/lib64/egl/libGLESv2_enc.so"
[ -f "$HWC" ] || HWC="$PROD/system/vendor/lib64/hw/hwcomposer.android_x86_64.so"
[ -f "$GLES" ] || { echo "missing libGLESv2_enc.so" >&2; exit 1; }
[ -f "$HWC" ] || { echo "missing hwcomposer" >&2; exit 1; }

mkdir -p "$OD/system/vendor/lib64" "$OD/system/vendor/lib64/hw"
cp -a "$GLES" "$OD/system/vendor/lib64/libGLESv2_enc.so"
cp -a "$HWC" "$OD/system/vendor/lib64/hw/hwcomposer.default.so"
md5sum "$GLES" "$HWC" "$OD/system/vendor/lib64/libGLESv2_enc.so" "$OD/system/vendor/lib64/hw/hwcomposer.default.so"

export IMAGE=Baklava64 PKG=$PKG
bash ~/r228-pack-root.sh
echo R231_REBUILD_DONE
