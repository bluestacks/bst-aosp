#!/bin/bash
# Rebuild hwservicemanager into out_nxt_Baklava64 (same env as g1_build.sh).
set -eo pipefail
AOSP=$HOME/aosp16
STAGE=$HOME/releases/Baklava64/system
LOG=$HOME/p2_diag_mmm2_$(date +%Y%m%d-%H%M%S).log
exec > >(tee -a "$LOG") 2>&1
echo "A16DBG:P2: mmm2 start $(date -Is) log=$LOG"

cd "$AOSP"
set +u
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=$HOME/app-player HD_SOURCE_TOP=$HOME/app-player/hd
export ALLOW_MISSING_DEPENDENCIES=true BST_BUILD_WITH_DEXPREOPT=true USE_OPENGL_RENDERER=true
source build/envsetup.sh
lunch bst_x86_64-trunk_staging-eng
set -u

echo "A16DBG:P2: OUT_DIR=$OUT_DIR TARGET_PRODUCT=$TARGET_PRODUCT"
mmm system/hwservicemanager -j24
rc=$?
echo "mmm_rc=$rc"

HWSM_OUT=$AOSP/out_nxt_Baklava64/target/product/qvirt/system/bin/hwservicemanager
ls -la "$HWSM_OUT"
md5sum "$HWSM_OUT"

cp -av "$HWSM_OUT" "$STAGE/bin/hwservicemanager"
md5sum "$STAGE/bin/hwservicemanager"

VMAN="$STAGE/vendor/etc/vintf/manifest.xml"
cp -a "$VMAN" "$VMAN.bak.p2diag.$(date +%H%M%S)"
sed -i 's/target-level="legacy"/target-level="8"/' "$VMAN"
echo "vendor manifest target-level:"
grep target-level "$VMAN" | head -1
head -6 "$VMAN"

rg -n 'A16DBG:HWSM|transport ==|if \(false\)' "$AOSP/system/hwservicemanager/service.cpp" | head -10
echo "A16DBG:P2: mmm2 DONE rc=$rc $(date -Is)"
