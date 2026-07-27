#!/bin/bash
# AFTER systemimage completes: apply remaining P2 win overlays + rebuild
set -euo pipefail
LOG=~/p2_apply_remaining.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:apply remaining start $(date -Is)"

A16=~/aosp16
OUT=~/bst-aosp/patches/android-16/patches

apply_patch() {
  local proj="$1"
  local patch="$2"
  echo "=== APPLY $proj $patch ==="
  if [ ! -f "$patch" ]; then echo "MISSING $patch"; return 1; fi
  cd "$A16/$proj"
  set +e
  git apply --3way --check "$patch" 2>/tmp/apply_check.err
  rc=$?
  if [ $rc -eq 0 ]; then
    git apply --3way "$patch"
    echo "APPLY_OK $proj"
  else
    echo "CHECK_FAIL $proj"
    head -30 /tmp/apply_check.err
    # try reject-tolerant apply of new files only handled separately
    git apply --reject --whitespace=nowarn "$patch" 2>&1 | tail -20
  fi
  set -e
}

# Functional external (small)
apply_patch external/boringssl "$OUT/p2-external/a13__boringssl__bst.patch"
apply_patch external/icu "$OUT/p2-external/a13__icu__ROB14898-iran-tz.patch"

# bionic / art full overlays
apply_patch bionic "$OUT/p2-bionic-art/a13__bionic__bst_full.patch"
apply_patch art "$OUT/p2-bionic-art/a13__art__bst_full.patch"

# frameworks/native — prefer per-file if full fails (script p2_native_overlay.sh)
if [ -f "$OUT/p2-framework-rest/p2_fw_native_full_a13.patch" ]; then
  apply_patch frameworks/native "$OUT/p2-framework-rest/p2_fw_native_full_a13.patch" || true
fi

# Layer1
set +u
cd ~/aosp16
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=~/app-player HD_SOURCE_TOP=~/app-player/hd ALLOW_MISSING_DEPENDENCIES=true
source build/envsetup.sh
lunch bst_x86_64-trunk_staging-eng
echo "A16DBG:P2:m systemimage after overlays $(date -Is)"
m systemimage -j8
rc=$?
echo "A16DBG:P2:m systemimage after overlays rc=$rc $(date -Is)"
exit $rc
