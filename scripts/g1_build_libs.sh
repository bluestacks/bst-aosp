#!/bin/bash
# G1: build hd guest native libs + goldfish graphics (replicates buildscripts/Makefile
# `libs` target: hostcall_gcall_libs + goldfish_opengl). Run AFTER m droid succeeds.
# Fills the gap between the ad-hoc overlay pipeline and the authoritative buildscripts flow.
set -euo pipefail
AOSP=~/aosp16
OUT_DIR_NAME=out_nxt_Baklava64
LOG=~/g1_build_libs.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:G1: build-libs (hostcall_gcall + goldfish) start $(date -Is)"

cd "$AOSP"
set +u
export OEM=nxt IMAGE=Baklava64 OUT_DIR="$OUT_DIR_NAME" IS_64_BUILD=1
export APP_PLAYER_DIR=~/app-player HD_SOURCE_TOP=~/app-player/hd
export ALLOW_MISSING_DEPENDENCIES=true BST_BUILD_WITH_DEXPREOPT=true USE_OPENGL_RENDERER=true
export BUILD_EMULATOR_OPENGL=true BUILD_EMULATOR_OPENGL_DRIVER=true
source build/envsetup.sh
lunch bst_x86_64-trunk_staging-eng
set -u

J="-j$(nproc)"
echo "A16DBG:G1: libs — hostcall_gcall_libs (10 hd guest modules via mmm)"

# 1-4) hd guest native libs (xpl, vmsg, hcall, gcall)
for mod in xpl vmsg/guest hcall/guest gcall/guest; do
  echo "A16DBG:G1: mmm ../hd/Source/$mod"
  mmm ../hd/Source/$mod $J || { echo "WARN: mmm ../hd/Source/$mod FAILED (rc=$?)" >&2; }
done

# 5) BstCommandProcessor JNI
echo "A16DBG:G1: mmm packages/apps/BstCommandProcessor/jni"
mmm packages/apps/BstCommandProcessor/jni $J || {
  echo "WARN: mmm BstCommandProcessor/jni FAILED — may be absent in a16" >&2; }

# 6) BST server native (frameworks/base services JNI for BlueStacks)
echo "A16DBG:G1: mmm frameworks/base/services/java/com/bluestacks/server/native"
mmm frameworks/base/services/java/com/bluestacks/server/native $J || {
  echo "WARN: mmm bluestacks/server/native FAILED" >&2; }

# 7-8) bstconf / bstchkdata (hd tools)
for mod in tools/bstconf tools/bstchkdata; do
  echo "A16DBG:G1: mmm ../hd/Source/$mod"
  mmm ../hd/Source/$mod $J || { echo "WARN: mmm ../hd/Source/$mod FAILED" >&2; }
done

# 9) BST sensors (external/bluestacks/sensors)
if [ -d external/bluestacks/sensors ]; then
  echo "A16DBG:G1: mm external/bluestacks/sensors BUILD_EXTERNAL_BLUESTACKS_SENSORS=true"
  (cd external/bluestacks/sensors && mm $J BUILD_EXTERNAL_BLUESTACKS_SENSORS=true) || {
    echo "WARN: mm BST sensors FAILED" >&2; }
else
  echo "A16DBG:G1: sensors dir absent — skip"
fi

# 10) toybox
echo "A16DBG:G1: mma toybox"
mma toybox $J || { echo "WARN: mma toybox FAILED" >&2; }

echo "A16DBG:G1: libs — goldfish_opengl (graphics chain)"
bash ~/bst-aosp/scripts/g1_rebuild_graphics.sh

echo "A16DBG:G1: build-libs DONE $(date -Is)"
echo "=== all modules built (check log for FAILED warnings) ==="
