#!/bin/bash
# Keep BUILD_EMULATOR_OPENGL stable (=true) for entire session to avoid
# kati "modified (true => )" full regen. Oscillation happens when it flips.
cd ~/aosp16
set +u
export BUILD_EMULATOR_OPENGL=true
export BUILD_EMULATOR_OPENGL_DRIVER=true
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=~/app-player HD_SOURCE_TOP=~/app-player/hd
export ALLOW_MISSING_DEPENDENCIES=true BST_BUILD_WITH_DEXPREOPT=true USE_OPENGL_RENDERER=true
source build/envsetup.sh >/dev/null 2>&1
lunch bst_x86_64-trunk_staging-eng >/dev/null 2>&1
echo "A16DBG:G1: build start (m droid, OPENGL=true stable) $(date -Is)"
echo "A16DBG:G1: OPENGL=${BUILD_EMULATOR_OPENGL} DRIVER=${BUILD_EMULATOR_OPENGL_DRIVER}"
m droid -j24
rc=$?
if [ "$rc" -eq 0 ]; then
  echo "A16DBG:G1: mmm goldfish-opengl-pie (graphics chain)"
  mmm ../ggl/goldfish-opengl-pie BUILD_EMULATOR_OPENGL=true BUILD_EMULATOR_OPENGL_DRIVER=true -j24 || rc=$?
fi
echo "A16DBG:G1: DONE rc=$rc $(date -Is)"
IMG=out_nxt_Baklava64/target/product/qvirt/system.img
ls -la "$IMG" 2>&1 | head -1
echo "A16DBG:G1: system.img md5 $(md5sum "$IMG" 2>/dev/null)"
exit $rc
