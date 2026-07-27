#!/bin/bash
# FW-CORE-APP-12: SharedPreferencesImpl apply + Layer1 m droid + pack.
set -eo pipefail
A16=~/aosp16
BST=~/bst-aosp
LOG=~/p2_fw_coreapp12_build.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:FW-CORE-APP-12 build start $(date -Is)"

if ! rg -q 'A16DBG:P2:FW-CORE-APP-12' \
    "$A16/frameworks/base/core/java/android/app/SharedPreferencesImpl.java" 2>/dev/null; then
  python3 "$BST/scripts/p2_fw_coreapp12_apply.py" || exit 1
else
  echo "apply: already patched (skip)"
fi

cd "$A16"
set +u
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=~/app-player HD_SOURCE_TOP=~/app-player/hd
export ALLOW_MISSING_DEPENDENCIES=true BST_BUILD_WITH_DEXPREOPT=true USE_OPENGL_RENDERER=true
source build/envsetup.sh >/dev/null 2>&1
lunch bst_x86_64-trunk_staging-eng >/dev/null 2>&1
set -u
m droid -j24
rc=$?
echo "m droid exit=$rc"
if [ "$rc" -ne 0 ]; then exit "$rc"; fi

bash "$BST/scripts/g1_build_libs.sh" || exit 1
bash "$BST/scripts/g1_stage_system.sh" || exit 1
bash "$BST/scripts/g1_copy_bst_apks.sh" || exit 1
bash ~/r228-pack-root.sh || exit 1
md5sum ~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd

cd "$A16/frameworks/base"
git diff HEAD -- core/java/android/app/SharedPreferencesImpl.java \
  > "$BST/patches/android-16/patches/p2-framework-rest/P2-FW-CORE-APP-12.diff" || true

echo "A16DBG:P2:FW-CORE-APP-12 DONE $(date -Is)"
