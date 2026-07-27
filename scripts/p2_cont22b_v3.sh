#!/bin/bash
# cont22b v3: exclusive soong lock, stable env, force services rebuild, then pack.
set +u
LOG=~/p2_cont22b_v3.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:cont22b v3 start $(date -Is)"

# Ensure no other soong on this OUT
if pgrep -u markxu -f 'soong_ui.*out_nxt_Baklava64' >/dev/null; then
  echo "ABORT: soong_ui still running on out_nxt_Baklava64"
  pgrep -u markxu -af 'soong_ui.*out_nxt_Baklava64'
  exit 2
fi

cd ~/aosp16 || exit 1
export BUILD_EMULATOR_OPENGL=true
export BUILD_EMULATOR_OPENGL_DRIVER=true
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=~/app-player HD_SOURCE_TOP=~/app-player/hd
export ALLOW_MISSING_DEPENDENCIES=true BST_BUILD_WITH_DEXPREOPT=true USE_OPENGL_RENDERER=true
source build/envsetup.sh >/dev/null 2>&1
lunch bst_x86_64-trunk_staging-eng >/dev/null 2>&1
echo "OPENGL=${BUILD_EMULATOR_OPENGL} ALLOW_MISSING=${ALLOW_MISSING_DEPENDENCIES}"

# force ninja to see SystemServer change
touch frameworks/base/services/java/com/android/server/SystemServer.java
rg -n 'cont22 — R248|startService\(HintManagerService' \
  frameworks/base/services/java/com/android/server/SystemServer.java | head -5

m services -j24
services_rc=$?
echo "services_rc=$services_rc"
if [ "$services_rc" -ne 0 ]; then
  echo "ABORT pack"
  exit "$services_rc"
fi

# readback: HintManager string should be in services (optional)
jar=~/aosp16/out_nxt_Baklava64/target/product/qvirt/system/framework/services.jar
if [ -f "$jar" ]; then
  echo "services.jar mtime=$(stat -c %y "$jar")"
fi

bash ~/bst-aosp/scripts/p2_cont22_pack.sh
echo "A16DBG:P2:cont22b v3 DONE $(date -Is)"
md5sum ~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd
