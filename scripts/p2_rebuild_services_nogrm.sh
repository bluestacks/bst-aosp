#!/bin/bash
# Force rebuild services after GRM revert
set -uo pipefail
LOG=~/p2_revert_grm_build2.log
exec > >(tee "$LOG") 2>&1
set +u
cd ~/aosp16
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=~/app-player HD_SOURCE_TOP=~/app-player/hd ALLOW_MISSING_DEPENDENCIES=true
source build/envsetup.sh
lunch bst_x86_64-trunk_staging-eng
touch frameworks/base/services/core/java/com/android/server/wm/ActivityStarter.java
touch frameworks/base/services/core/java/com/android/server/wm/WindowManagerService.java
echo "A16DBG:P2:rebuild services after GRM revert $(date -Is)"
m services -j24
echo "A16DBG:P2:rebuild services rc=$? $(date -Is)"
# refresh surgical diff without GRM
mkdir -p ~/bst-aosp/patches/android-16/patches/p2-framework-rest
git -C frameworks/base diff -- services/core/java/com/android/server/wm/WindowManagerService.java \
  services/core/java/com/android/server/wm/ActivityStarter.java \
  > ~/bst-aosp/patches/android-16/patches/p2-framework-rest/aosp16__frameworks_base__P2-batchB-surgical.diff || true
wc -l ~/bst-aosp/patches/android-16/patches/p2-framework-rest/aosp16__frameworks_base__P2-batchB-surgical.diff
