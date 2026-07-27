#!/bin/bash
# P2-FRAMEWORK-REST Batch A Layer1: pagefusion + framework-minus-apex
set -uo pipefail
LOG=~/p2_batchA_build.log
exec > >(tee "$LOG") 2>&1
set +u
cd ~/aosp16
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=~/app-player HD_SOURCE_TOP=~/app-player/hd
export ALLOW_MISSING_DEPENDENCIES=true
source build/envsetup.sh
lunch bst_x86_64-trunk_staging-eng
echo "A16DBG:P2:batchA_build start $(date -Is)"
m pagefusion framework-minus-apex -j24
rc=$?
echo "A16DBG:P2:batchA_build rc=$rc $(date -Is)"
exit $rc
