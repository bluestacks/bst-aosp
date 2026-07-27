#!/bin/bash
# Full systemimage including Batch A/B source (no jar hot-swap)
set -uo pipefail
LOG=~/p2_systemimage_batchAB.log
exec > >(tee "$LOG") 2>&1
set +u
cd ~/aosp16
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=~/app-player HD_SOURCE_TOP=~/app-player/hd ALLOW_MISSING_DEPENDENCIES=true
source build/envsetup.sh
lunch bst_x86_64-trunk_staging-eng
echo "A16DBG:P2:systemimage BatchA/B start $(date -Is)"
# Confirm GRM gone, other hooks present
rg -n "isAppLaunchAllowed|sendOrientationToHostAsync|setAppConfigDbParams" \
  frameworks/base/services/core/java/com/android/server/wm/ActivityStarter.java \
  frameworks/base/services/core/java/com/android/server/wm/WindowManagerService.java | head -20
m systemimage -j24
rc=$?
echo "A16DBG:P2:systemimage BatchA/B rc=$rc $(date -Is)"
if [ $rc -eq 0 ]; then
  ls -la out_nxt_Baklava64/target/product/qvirt/system.img
  md5sum out_nxt_Baklava64/target/product/qvirt/system.img
fi
exit $rc
