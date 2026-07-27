#!/bin/bash
# Apply remaining P2 overlays only (no build)
set -uo pipefail
LOG=~/p2_apply_remaining.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:apply remaining start $(date -Is)"
A16=~/aosp16
OUT=~/bst-aosp/patches/android-16/patches

apply_patch() {
  local proj="$1"
  local patch="$2"
  echo "=== APPLY $proj ==="
  [ -f "$patch" ] || { echo "MISSING $patch"; return 0; }
  cd "$A16/$proj" || return 0
  set +e
  if git apply --3way --check "$patch" 2>/tmp/chk.err; then
    git apply --3way "$patch" && echo OK_$proj || echo APPLY_ERR_$proj
  else
    echo CHECK_FAIL_$proj
    head -25 /tmp/chk.err
    git apply --reject --whitespace=nowarn "$patch" 2>&1 | tail -25
  fi
  set -e
  git status --short 2>/dev/null | head -20
}

apply_patch external/boringssl "$OUT/p2-external/a13__boringssl__bst.patch"
apply_patch external/icu "$OUT/p2-external/a13__icu__ROB14898-iran-tz.patch"
apply_patch bionic "$OUT/p2-bionic-art/a13__bionic__bst_full.patch"
apply_patch art "$OUT/p2-bionic-art/a13__art__bst_full.patch"
apply_patch frameworks/native "$OUT/p2-framework-rest/p2_fw_native_full_a13.patch"
echo "A16DBG:P2:apply remaining DONE $(date -Is)"
