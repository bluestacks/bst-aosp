#!/bin/bash
# G1/G3 standard graphics path (M1 r229 lineage):
#   lunch android_x86_64 → mmm goldfish-opengl-pie (+ hwc2) → stage into releases/Baklava64/system
# No backup-VHD extraction. Verify by readback of installed artifacts under product out.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/android16_env.sh"
bst_android16_preflight
bst_android16_graphics_preflight
AOSP="$BST_ANDROID16_ROOT"
OD="$BST_RELEASE_ROOT"
OUT_DIR_NAME="$BST_OUT_DIR_NAME"
JOBS="${BST_BUILD_JOBS:-8}"
PROD="$AOSP/$OUT_DIR_NAME/target/product/x86_64"
SYS="$OD/system"
LOG=~/g1_rebuild_graphics.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:G1: rebuild-graphics start $(date -Is)"
[ -d "$BST_GOLDFISH_OPENGL_ROOT" ] || {
  echo "missing graphics source: $BST_GOLDFISH_OPENGL_ROOT" >&2
  exit 1
}
MODE="${1:-build}"
[ "$MODE" != "--check" ] || {
  echo "A16DBG:ANDROID16: graphics CHECK OK; no patch/build/stage started"
  exit 0
}
[ "$MODE" = "build" ] || [ "$MODE" = "--stage-only" ] || {
  echo "usage: $0 [--check|--stage-only]" >&2
  exit 2
}

if [ "$MODE" = "build" ]; then
  cd "$AOSP"
  GOLDFISH_MODULE_PATH="$(bst_android16_graphics_module_path)"
  set +u
  export OEM=nxt IMAGE=Baklava64 OUT_DIR="$OUT_DIR_NAME" IS_64_BUILD=1
  export APP_PLAYER_DIR="$BST_APP_PLAYER_ROOT" HD_SOURCE_TOP="$BST_HD_SOURCE_TOP"
  export ALLOW_MISSING_DEPENDENCIES=true BST_BUILD_WITH_DEXPREOPT=true USE_OPENGL_RENDERER=true
  export BUILD_EMULATOR_OPENGL=true BUILD_EMULATOR_OPENGL_DRIVER=true
  export BST_BUILD_EXTERNAL_GOLDFISH=true
  export USE_CCACHE="${USE_CCACHE:-1}"
  source build/envsetup.sh
  lunch "$BST_LUNCH_TARGET"
  set -u

  # Force both target architectures to rebuild. Android stores the secondary
  # x86 intermediates under obj_x86; cleaning only obj silently reuses stale
  # 32-bit encoders even when the 64-bit closure is fresh.
  echo "A16DBG:G1: clean 32/64-bit goldfish installs + intermediates"
  for abi in lib lib64; do
    rm -f \
      "$PROD/system/vendor/$abi/egl/libEGL_emulation.so" \
      "$PROD/system/vendor/$abi/egl/libGLESv1_CM_emulation.so" \
      "$PROD/system/vendor/$abi/egl/libGLESv2_emulation.so" \
      "$PROD/system/vendor/$abi/libOpenglSystemCommon.so" \
      "$PROD/system/vendor/$abi/libGLESv1_enc.so" \
      "$PROD/system/vendor/$abi/libGLESv2_enc.so" \
      "$PROD/system/vendor/$abi/lib_renderControl_enc.so" \
      "$PROD/system/vendor/$abi/hw/gralloc.bst.so" \
      "$PROD/system/vendor/$abi/hw/gralloc.default.so" \
      "$PROD/system/vendor/$abi/hw/gralloc.android_x86_64.so" \
      "$PROD/system/vendor/$abi/hw/hwcomposer.default.so" \
      "$PROD/system/vendor/$abi/hw/hwcomposer.android_x86_64.so"
  done
  for obj_root in "$PROD/obj" "$PROD/obj_x86"; do
    rm -rf \
      "$obj_root/SHARED_LIBRARIES/libEGL_emulation_intermediates" \
      "$obj_root/SHARED_LIBRARIES/libGLESv1_CM_emulation_intermediates" \
      "$obj_root/SHARED_LIBRARIES/libGLESv2_emulation_intermediates" \
      "$obj_root/SHARED_LIBRARIES/libOpenglSystemCommon_intermediates" \
      "$obj_root/SHARED_LIBRARIES/gralloc.bst_intermediates" \
      "$obj_root/SHARED_LIBRARIES/gralloc.default_intermediates" \
      "$obj_root/SHARED_LIBRARIES/gralloc.android_x86_64_intermediates" \
      "$obj_root/SHARED_LIBRARIES/hwcomposer.default_intermediates" \
      "$obj_root/SHARED_LIBRARIES/hwcomposer.android_x86_64_intermediates" \
      "$obj_root/SHARED_LIBRARIES/libGLESv1_enc_intermediates" \
      "$obj_root/SHARED_LIBRARIES/libGLESv2_enc_intermediates" \
      "$obj_root/SHARED_LIBRARIES/lib_renderControl_enc_intermediates"
  done

  echo "A16DBG:G1: mmm $GOLDFISH_MODULE_PATH"
  mmm "$GOLDFISH_MODULE_PATH" -j"$JOBS"
  echo "A16DBG:G1: mmm $GOLDFISH_MODULE_PATH/system/hwc2"
  mmm "$GOLDFISH_MODULE_PATH/system/hwc2" -j"$JOBS"
else
  echo "A16DBG:G1: stage-only; reusing graphics from verified build output"
  bst_verify_identity_file \
    "$BST_BUILD_IDENTITY_FILE" \
    "$AOSP/$OUT_DIR_NAME/target/product/x86_64/system.img"
fi

VENDOR_ROOT="$PROD/system/vendor"
[ -d "$VENDOR_ROOT/lib64" ] || VENDOR_ROOT="$PROD/vendor"
echo "A16DBG:G1: product vendor root=$VENDOR_ROOT"

require_file() {
  local f="$1"
  [ -f "$f" ] || { echo "A16DBG:G1: MISSING installed artifact: $f" >&2; return 1; }
  ls -la "$f"
  md5sum "$f"
}

echo "A16DBG:G1: readback and stage the complete goldfish runtime closure"
for abi in lib lib64; do
  mkdir -p "$SYS/vendor/$abi/egl" "$SYS/vendor/$abi/hw"
  for rel in \
    egl/libEGL_emulation.so \
    egl/libGLESv1_CM_emulation.so \
    egl/libGLESv2_emulation.so \
    libOpenglSystemCommon.so \
    libGLESv1_enc.so \
    libGLESv2_enc.so \
    lib_renderControl_enc.so \
    hw/gralloc.bst.so; do
    require_file "$VENDOR_ROOT/$abi/$rel"
    cp -a "$VENDOR_ROOT/$abi/$rel" "$SYS/vendor/$abi/$rel"
  done

  # Guest loads hwcomposer.default.so unless ro.hardware.hwcomposer is set.
  HWC_SRC="$VENDOR_ROOT/$abi/hw/hwcomposer.android_x86_64.so"
  [ -f "$HWC_SRC" ] || HWC_SRC="$VENDOR_ROOT/$abi/hw/hwcomposer.default.so"
  require_file "$HWC_SRC"
  cp -a "$HWC_SRC" "$SYS/vendor/$abi/hw/hwcomposer.default.so"
  rm -f "$SYS/vendor/$abi/hw/gralloc.default.so"
done

BP="$SYS/build.prop"
[ -f "$BP" ] || BP="$SYS/system/build.prop"
for kv in "ro.hardware.gralloc=bst" "ro.hardware.egl=emulation"; do
  grep -qF "$kv" "$BP" 2>/dev/null || echo "$kv" >> "$BP"
done

echo "A16DBG:G1: staged graphics closure readback"
for abi in lib lib64; do
  sha256sum \
    "$SYS/vendor/$abi/egl/"*.so \
    "$SYS/vendor/$abi/libOpenglSystemCommon.so" \
    "$SYS/vendor/$abi/libGLESv1_enc.so" \
    "$SYS/vendor/$abi/libGLESv2_enc.so" \
    "$SYS/vendor/$abi/lib_renderControl_enc.so" \
    "$SYS/vendor/$abi/hw/gralloc.bst.so" \
    "$SYS/vendor/$abi/hw/hwcomposer.default.so"
done
grep -E 'ro.hardware.(gralloc|egl)' "$BP" || true
if [ "$MODE" = "build" ]; then
  bst_write_identity_file \
    "$BST_BUILD_IDENTITY_FILE" \
    "$AOSP/$OUT_DIR_NAME/target/product/x86_64/system.img"
fi
echo "A16DBG:G1: graphics stage DONE mode=$MODE $(date -Is)"
