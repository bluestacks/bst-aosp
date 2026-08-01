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

J="-j$(nproc)"
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
  echo "WARN: mmm BstCommandProcessor/jni FAILED — may be absent in a16" >&2; }

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

# 9) BST sensors (external/bluestacks/sensors)
if [ -d external/bluestacks/sensors ]; then
  echo "A16DBG:G1: mm external/bluestacks/sensors BUILD_EXTERNAL_BLUESTACKS_SENSORS=true"
  (cd external/bluestacks/sensors && mm "$J" BUILD_EXTERNAL_BLUESTACKS_SENSORS=true) || {
    echo "WARN: mm BST sensors FAILED" >&2; }
else
  echo "A16DBG:G1: sensors dir absent — skip"
fi

# 10) toybox
echo "A16DBG:G1: mma toybox"
mma toybox "$J" || {
  echo "ERROR: mma toybox FAILED" >&2
  failed=1
}

[ "$failed" -eq 0 ] || {
  echo "A16DBG:G1: one or more required native modules failed" >&2
  exit 1
}

echo "A16DBG:G1: build-libs DONE $(date -Is)"
echo "=== required modules built; optional-module warnings are recorded above ==="
