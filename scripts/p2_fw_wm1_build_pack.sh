#!/bin/bash
# Build+pack after FW-WM-1 surgical port
set +u
LOG=~/p2_fw_wm1_build.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:FW-WM-1 build start $(date -Is)"
cd ~/aosp16 || exit 1
export BUILD_EMULATOR_OPENGL=true
export BUILD_EMULATOR_OPENGL_DRIVER=true
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=~/app-player HD_SOURCE_TOP=~/app-player/hd
export ALLOW_MISSING_DEPENDENCIES=true BST_BUILD_WITH_DEXPREOPT=true USE_OPENGL_RENDERER=true
source build/envsetup.sh >/dev/null 2>&1
lunch bst_x86_64-trunk_staging-eng >/dev/null 2>&1
echo "OPENGL=${BUILD_EMULATOR_OPENGL} ALLOW_MISSING=${ALLOW_MISSING_DEPENDENCIES}"
m services -j24
rc=$?
echo "services_rc=$rc"
if [ "$rc" -ne 0 ]; then
  echo ABORT
  exit "$rc"
fi
bash ~/bst-aosp/scripts/p2_cont22_pack.sh
echo "A16DBG:P2:FW-WM-1 DONE $(date -Is)"
md5sum ~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd
