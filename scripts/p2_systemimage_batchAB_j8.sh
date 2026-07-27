#!/bin/bash
# Restart systemimage at lower parallelism (machine load ~70)
set -uo pipefail
LOG=~/p2_systemimage_batchAB_j8.log
# stop previous if still running
pkill -f "p2_systemimage_batchAB.sh" 2>/dev/null || true
# do not pkill all soong — only our OUT_DIR build if possible
if pgrep -f "out_nxt_Baklava64.*systemimage" >/dev/null; then
  pkill -f "out_nxt_Baklava64/soong_ui --build-mode.*systemimage" 2>/dev/null || true
  sleep 3
fi
exec > >(tee "$LOG") 2>&1
set +u
cd ~/aosp16
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=~/app-player HD_SOURCE_TOP=~/app-player/hd ALLOW_MISSING_DEPENDENCIES=true
source build/envsetup.sh
lunch bst_x86_64-trunk_staging-eng
echo "A16DBG:P2:systemimage BatchA/B -j8 start $(date -Is)"
m systemimage -j8
rc=$?
echo "A16DBG:P2:systemimage BatchA/B -j8 rc=$rc $(date -Is)"
exit $rc
