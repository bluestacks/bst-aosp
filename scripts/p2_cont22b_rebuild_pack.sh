#!/bin/bash
# Rebuild services after HintManager restore, then pack — ONLY if services build OK.
# Mirror g1_build_stable env (OPENGL=true stable) to avoid libringbuffer soong failure.
set +u
LOG=~/p2_cont22b_hintmgr.log
exec > >(tee -a "$LOG") 2>&1
echo "A16DBG:P2:cont22b HintManager rebuild v2 start $(date -Is)"

cd ~/aosp16 || exit 1
export BUILD_EMULATOR_OPENGL=true
export BUILD_EMULATOR_OPENGL_DRIVER=true
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=~/app-player HD_SOURCE_TOP=~/app-player/hd
export ALLOW_MISSING_DEPENDENCIES=true BST_BUILD_WITH_DEXPREOPT=true USE_OPENGL_RENDERER=true
source build/envsetup.sh >/dev/null 2>&1
lunch bst_x86_64-trunk_staging-eng >/dev/null 2>&1
echo "A16DBG:P2: OPENGL=${BUILD_EMULATOR_OPENGL} DRIVER=${BUILD_EMULATOR_OPENGL_DRIVER}"

# verify patch still present
rg -n 'cont22 — R248 temp_debt lifted|startService\(HintManagerService' \
  frameworks/base/services/java/com/android/server/SystemServer.java | head -5

m services -j24
services_rc=$?
echo "services_rc=$services_rc"
if [ "$services_rc" -ne 0 ]; then
  echo "A16DBG:P2:cont22b ABORT pack (services failed)"
  exit "$services_rc"
fi

bash ~/bst-aosp/scripts/p2_cont22_pack.sh
echo "A16DBG:P2:cont22b DONE $(date -Is)"
