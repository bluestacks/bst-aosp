#!/bin/bash
# G1/G3 standard graphics path (M1 r229 lineage):
#   lunch bst_x86_64 → mmm goldfish-opengl-pie (+ hwc2) → stage into releases/Baklava64/system
# No backup-VHD extraction. Verify by readback of installed artifacts under product out.
set -euo pipefail
AOSP=~/aosp16
OD=~/releases/Baklava64
OUT_DIR_NAME=out_nxt_Baklava64
PROD="$AOSP/$OUT_DIR_NAME/target/product/qvirt"
SYS="$OD/system"
LOG=~/g1_rebuild_graphics.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:G1: rebuild-graphics start $(date -Is)"

# A16 guest fixes required before mmm
for p in \
  ~/bst-aosp/scripts/patch-goldfish-emuhwc2-vsync-sp.py \
  ~/bst-aosp/scripts/patch-goldfish-hwc2-bst-product.py \
  ~/patch-goldfish-emuhwc2-vsync-sp.py; do
  [ -f "$p" ] && python3 "$p"
done

cd "$AOSP"
set +u
export OEM=nxt IMAGE=Baklava64 OUT_DIR="$OUT_DIR_NAME" IS_64_BUILD=1
export APP_PLAYER_DIR=~/app-player HD_SOURCE_TOP=~/app-player/hd
export ALLOW_MISSING_DEPENDENCIES=true BST_BUILD_WITH_DEXPREOPT=true USE_OPENGL_RENDERER=true
export BUILD_EMULATOR_OPENGL=true BUILD_EMULATOR_OPENGL_DRIVER=true
source build/envsetup.sh
lunch bst_x86_64-trunk_staging-eng
set -u

# Force real rebuild (mmm "no work" leaves stale/missing installs after product switch)
echo "A16DBG:G1: clean goldfish install + intermediates under qvirt"
rm -rf \
  "$PROD/system/vendor/lib64/egl" \
  "$PROD/obj/SHARED_LIBRARIES/libEGL_emulation_intermediates" \
  "$PROD/obj/SHARED_LIBRARIES/libGLESv1_CM_emulation_intermediates" \
  "$PROD/obj/SHARED_LIBRARIES/libGLESv2_emulation_intermediates" \
  "$PROD/obj/SHARED_LIBRARIES/libOpenglSystemCommon_intermediates" \
  "$PROD/obj/SHARED_LIBRARIES/gralloc.bst_intermediates" \
  "$PROD/obj/SHARED_LIBRARIES/gralloc.default_intermediates" \
  "$PROD/obj/SHARED_LIBRARIES/gralloc.android_x86_64_intermediates" \
  "$PROD/obj/SHARED_LIBRARIES/hwcomposer.default_intermediates" \
  "$PROD/obj/SHARED_LIBRARIES/hwcomposer.android_x86_64_intermediates" \
  "$PROD/obj/SHARED_LIBRARIES/libGLESv1_enc_intermediates" \
  "$PROD/obj/SHARED_LIBRARIES/libGLESv2_enc_intermediates" \
  "$PROD/obj/SHARED_LIBRARIES/lib_renderControl_enc_intermediates"

echo "A16DBG:G1: mmm goldfish-opengl-pie"
mmm ../ggl/goldfish-opengl-pie -j"$(nproc)"
echo "A16DBG:G1: mmm goldfish hwc2"
mmm ../ggl/goldfish-opengl-pie/system/hwc2 -j"$(nproc)"

VENDOR_LIB64="$PROD/system/vendor/lib64"
[ -d "$VENDOR_LIB64" ] || VENDOR_LIB64="$PROD/vendor/lib64"
echo "A16DBG:G1: product vendor lib64=$VENDOR_LIB64"

require_file() {
  local f="$1"
  [ -f "$f" ] || { echo "A16DBG:G1: MISSING installed artifact: $f" >&2; return 1; }
  ls -la "$f"
  md5sum "$f"
}

echo "A16DBG:G1: readback installed goldfish artifacts"
require_file "$VENDOR_LIB64/egl/libEGL_emulation.so"
require_file "$VENDOR_LIB64/egl/libGLESv1_CM_emulation.so"
require_file "$VENDOR_LIB64/egl/libGLESv2_emulation.so"
require_file "$VENDOR_LIB64/hw/gralloc.bst.so"
# Prefer product-named hwc (M1); fall back to default
HWC_SRC="$VENDOR_LIB64/hw/hwcomposer.android_x86_64.so"
[ -f "$HWC_SRC" ] || HWC_SRC="$VENDOR_LIB64/hw/hwcomposer.default.so"
require_file "$HWC_SRC"

mkdir -p "$SYS/vendor/lib64/egl" "$SYS/vendor/lib64/hw"
cp -a "$VENDOR_LIB64/egl/libEGL_emulation.so" "$SYS/vendor/lib64/egl/"
cp -a "$VENDOR_LIB64/egl/libGLESv1_CM_emulation.so" "$SYS/vendor/lib64/egl/"
cp -a "$VENDOR_LIB64/egl/libGLESv2_emulation.so" "$SYS/vendor/lib64/egl/"
cp -a "$VENDOR_LIB64/hw/gralloc.bst.so" "$SYS/vendor/lib64/hw/gralloc.bst.so"
rm -f "$SYS/vendor/lib64/hw/gralloc.default.so"
# Guest loads hwcomposer.default.so unless ro.hardware.hwcomposer is set
cp -a "$HWC_SRC" "$SYS/vendor/lib64/hw/hwcomposer.default.so"

# Optional companion libs (present after full goldfish mmm)
for f in libOpenglSystemCommon.so; do
  if [ -f "$VENDOR_LIB64/$f" ]; then
    cp -a "$VENDOR_LIB64/$f" "$SYS/vendor/lib64/$f"
  fi
done

BP="$SYS/build.prop"
[ -f "$BP" ] || BP="$SYS/system/build.prop"
for kv in "ro.hardware.gralloc=bst" "ro.hardware.egl=emulation"; do
  grep -qF "$kv" "$BP" 2>/dev/null || echo "$kv" >> "$BP"
done

echo "A16DBG:G1: staged graphics readback"
ls -la "$SYS/vendor/lib64/egl/" "$SYS/vendor/lib64/hw/gralloc.bst.so" "$SYS/vendor/lib64/hw/hwcomposer.default.so"
md5sum \
  "$SYS/vendor/lib64/egl/"*.so \
  "$SYS/vendor/lib64/hw/gralloc.bst.so" \
  "$SYS/vendor/lib64/hw/hwcomposer.default.so"
grep -E 'ro.hardware.(gralloc|egl)' "$BP" || true
echo "A16DBG:G1: rebuild-graphics DONE $(date -Is)"
