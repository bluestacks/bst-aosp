#!/bin/bash
set -euo pipefail
LOG=~/p2_cont21b.log
exec > >(tee "$LOG") 2>&1
cd ~/aosp16/frameworks/base

# Revert files that call missing a16 APIs
git checkout HEAD -- \
  services/core/java/com/android/server/wm/ActivityClientController.java \
  services/core/java/com/android/server/wm/DisplayWindowSettings.java \
  services/core/java/com/android/server/power/ShutdownThread.java \
  services/core/java/com/android/server/am/BatteryStatsService.java
echo "reverted risky tiny applies; keep debug configs + DisplayRotation"

# show DisplayRotation key markers
rg -n "BST_DEBUG_ORIENTATION|FIXED_TO_USER_ROTATION_DISABLED|sensorRotation = lastRotation|BST: only treat" \
  services/core/java/com/android/server/wm/DisplayRotation.java | head -20

# clear conflict state if any
git add services/core/java/com/android/server/wm/DisplayRotation.java 2>/dev/null || true

cd ~/aosp16
set +u
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=~/app-player HD_SOURCE_TOP=~/app-player/hd
export ALLOW_MISSING_DEPENDENCIES=true BST_BUILD_WITH_DEXPREOPT=true USE_OPENGL_RENDERER=true
source build/envsetup.sh >/dev/null 2>&1
lunch bst_x86_64-trunk_staging-eng >/dev/null 2>&1
echo "A16DBG:P2:cont21b m services $(date -Is)"
m services -j24
rc=$?
echo "A16DBG:P2:cont21b services rc=$rc $(date -Is)"
exit $rc
