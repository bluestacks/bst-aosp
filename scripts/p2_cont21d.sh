#!/bin/bash
# cont.21d: kill stuck cont21c; g1_build (enabled.c reverted, DisplayRotation kept); pack_fast
set -euo pipefail
LOG=~/p2_cont21d.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:cont21d start $(date -Is)"

# ensure enabled.c is stock
head -22 ~/aosp16/external/selinux/libselinux/src/enabled.c | tail -12
rg -n 'BST_DEBUG_ORIENTATION|sensorRotation = lastRotation' \
  ~/aosp16/frameworks/base/services/core/java/com/android/server/wm/DisplayRotation.java | head -5

# kill stuck cont21c / m / ckati for this lunch
pkill -f 'p2_cont21c_revert_selinux' 2>/dev/null || true
pkill -f 'bin/m libselinux' 2>/dev/null || true
# don't kill unrelated m droid from other users
sleep 2

export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=~/app-player HD_SOURCE_TOP=~/app-player/hd
export ALLOW_MISSING_DEPENDENCIES=true BST_BUILD_WITH_DEXPREOPT=true USE_OPENGL_RENDERER=true
export BUILD_EMULATOR_OPENGL=true BUILD_EMULATOR_OPENGL_DRIVER=true

bash ~/bst-aosp/scripts/g1_build.sh
rc=$?
echo "A16DBG:P2:cont21d g1_build rc=$rc $(date -Is)"
[ "$rc" -eq 0 ] || exit "$rc"

bash ~/bst-aosp/scripts/p2_cont21_pack_fast.sh
echo "A16DBG:P2:cont21d DONE $(date -Is)"
md5sum ~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd
