#!/bin/bash
# cont.21c: revert enabled.c (breaks apex/netbpfload); keep DisplayRotation; restage+pack
set -euo pipefail
LOG=~/p2_cont21c.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:cont21c start $(date -Is)"

# 1) revert enabled.c to stock a16
git -C ~/aosp16/external/selinux checkout HEAD -- libselinux/src/enabled.c
echo "reverted enabled.c"
head -25 ~/aosp16/external/selinux/libselinux/src/enabled.c

# 2) confirm DisplayRotation BST markers still present
rg -n "BST_DEBUG_ORIENTATION|sensorRotation = lastRotation|FIXED_TO_USER_ROTATION_DISABLED" \
  ~/aosp16/frameworks/base/services/core/java/com/android/server/wm/DisplayRotation.java | head -10

# 3) rebuild libselinux + anything depending (m droid is safest but slow; try libselinux first then full pack from OUT)
cd ~/aosp16
set +u
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=~/app-player HD_SOURCE_TOP=~/app-player/hd
export ALLOW_MISSING_DEPENDENCIES=true BST_BUILD_WITH_DEXPREOPT=true USE_OPENGL_RENDERER=true
source build/envsetup.sh >/dev/null 2>&1
lunch bst_x86_64-trunk_staging-eng >/dev/null 2>&1
echo "A16DBG:P2:cont21c m libselinux $(date -Is)"
m libselinux -j24
rc=$?
echo "libselinux rc=$rc"
# also rebuild libc if needed - libselinux is used by many; install into system
# Full m droid to be safe for install path
echo "A16DBG:P2:cont21c m droid $(date -Is)"
m droid -j24
rc=$?
echo "A16DBG:P2:cont21c m droid rc=$rc $(date -Is)"
if [ "$rc" -eq 0 ]; then
  mmm ../ggl/goldfish-opengl-pie BUILD_EMULATOR_OPENGL=true BUILD_EMULATOR_OPENGL_DRIVER=true -j24 || rc=$?
fi
echo "A16DBG:P2:cont21c DONE rc=$rc $(date -Is)"
exit $rc
