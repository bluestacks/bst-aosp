#!/bin/bash
# Build required HD guest native libs after the main build has produced graphics.
# Fills the gap between the ad-hoc overlay pipeline and the authoritative buildscripts flow.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/android16_env.sh"
bst_android16_preflight
bst_android16_graphics_preflight
[ "${1:-}" != "--check" ] || {
  [ -d "$BST_HD_SOURCE_TOP/Source" ] || { echo "missing $BST_HD_SOURCE_TOP/Source"; exit 1; }
  echo "A16DBG:ANDROID16: build-libs CHECK OK; no build started"
  exit 0
}
AOSP="$BST_ANDROID16_ROOT"
OUT_DIR_NAME="$BST_OUT_DIR_NAME"
LOG=~/g1_build_libs.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:G1: build-libs (hostcall_gcall) start $(date -Is)"

cd "$AOSP"
set +u
export OEM=nxt IMAGE=Baklava64 OUT_DIR="$OUT_DIR_NAME" IS_64_BUILD=1
export APP_PLAYER_DIR="$BST_APP_PLAYER_ROOT" HD_SOURCE_TOP="$BST_HD_SOURCE_TOP"
export ALLOW_MISSING_DEPENDENCIES=true BST_BUILD_WITH_DEXPREOPT=true USE_OPENGL_RENDERER=true
export BUILD_EMULATOR_OPENGL=true BUILD_EMULATOR_OPENGL_DRIVER=true
export BST_BUILD_EXTERNAL_GOLDFISH=true
source build/envsetup.sh
lunch "$BST_LUNCH_TARGET"
set -u

J="-j${BST_BUILD_JOBS:-8}"
echo "A16DBG:G1: libs — hostcall_gcall_libs (10 hd guest modules via mmm)"
failed=0

# 1-4) hd guest native libs (xpl, vmsg, hcall, gcall)
for mod in xpl vmsg/guest hcall/guest gcall/guest; do
  echo "A16DBG:G1: mmm ../hd/Source/$mod"
  mmm "../hd/Source/$mod" "$J" || {
    echo "ERROR: mmm ../hd/Source/$mod FAILED" >&2
    failed=1
  }
done

# 5) BstCommandProcessor JNI
echo "A16DBG:G1: mmm packages/apps/BstCommandProcessor/jni"
mmm packages/apps/BstCommandProcessor/jni "$J" || {
  echo "ERROR: mmm BstCommandProcessor/jni FAILED" >&2
  failed=1
}

# 6) BST server native (frameworks/base services JNI for BlueStacks)
echo "A16DBG:G1: mmm frameworks/base/services/java/com/bluestacks/server/native"
mmm frameworks/base/services/java/com/bluestacks/server/native "$J" || {
  echo "ERROR: mmm bluestacks/server/native FAILED" >&2
  failed=1
}

# 7-8) bstconf / bstchkdata (hd tools)
for mod in tools/bstconf tools/bstchkdata; do
  echo "A16DBG:G1: mmm ../hd/Source/$mod"
  mmm "../hd/Source/$mod" "$J" || {
    echo "ERROR: mmm ../hd/Source/$mod FAILED" >&2
    failed=1
  }
done

# 9) toybox. Build it before sensors so the final sensors-specific Make
# variable does not need to be toggled back by another Make invocation.
echo "A16DBG:G1: mma toybox"
mma toybox "$J" || {
  echo "ERROR: mma toybox FAILED" >&2
  failed=1
}

# 10) BST sensors (external/bluestacks/sensors)
if [ -d external/bluestacks/sensors ]; then
  echo "A16DBG:G1: mm external/bluestacks/sensors BUILD_EXTERNAL_BLUESTACKS_SENSORS=true"
  (cd external/bluestacks/sensors && mm "$J" BUILD_EXTERNAL_BLUESTACKS_SENSORS=true) || {
    echo "ERROR: mm BST sensors FAILED" >&2
    failed=1
  }
else
  echo "A16DBG:G1: sensors dir absent — skip"
fi

[ "$failed" -eq 0 ] || {
  echo "A16DBG:G1: one or more required native modules failed" >&2
  exit 1
}

PRODUCT_OUT="$AOSP/$OUT_DIR_NAME/target/product/x86_64"
required_artifacts=(
  system/lib64/libhostcall_jni.so
  system/lib64/libgcall_jni.so
  system/lib/libhostcall_jni.so
  system/lib/libgcall_jni.so
  system/out_bstconf/bstconf
  system/out_bstchkdata/bstchkdata
)
if [ -d external/bluestacks/sensors ]; then
  required_artifacts+=(
    system/lib64/hw/sensors.default.so
    system/lib/hw/sensors.default.so
  )
fi
echo "A16DBG:G1: required artifact readback"
for artifact in "${required_artifacts[@]}"; do
  [ -f "$PRODUCT_OUT/$artifact" ] || {
    echo "ERROR: required target artifact is missing: $PRODUCT_OUT/$artifact" >&2
    exit 1
  }
  sha256sum "$PRODUCT_OUT/$artifact"
done

echo "A16DBG:G1: build-libs DONE $(date -Is)"
echo "=== all required HD guest modules built and read back from target OUT ==="
