#!/bin/bash
# Rebuild init_second_stage after builtins.cpp fix, bypassing soong regen.
# Uses existing out_nxt_Baklava64 intermediates + ninja (Henry path: clean init, no bringup patches).
set -euo pipefail

AOSP="${AOSP:-$HOME/aosp16}"
# Ninja rules reference out/soong (not out_nxt_Baklava64/soong).
OUT_DIR="${OUT_DIR:-out}"
INSTALL_OUT="${INSTALL_OUT:-out_nxt_Baklava64}"
cd "$AOSP"

NINJA_DIR="$OUT_DIR/soong"
PREBUILT_NINJA="$AOSP/prebuilts/build-tools/linux-x86/bin/ninja"
# System ninja 1.10.1 may not support |@; try it first, fall back to sed fix.
NINJA="${NINJA:-$(command -v ninja)}"

fix_ninja_dyndep() {
  local f
  for f in "$NINJA_DIR"/build.aosp_x86_64.*.ninja; do
    [ -f "$f" ] || continue
    if grep -q '|@' "$f" 2>/dev/null; then
      cp -a "$f" "$f.bak_relink"
      sed -i 's/ |@ $/ $/g' "$f"
    fi
  done
}

try_ninja() {
  "$NINJA" -f "$OUT_DIR/soong/build.aosp_x86_64.ninja" "$@" 2>&1
}

echo "=== relink-init: verify builtins.cpp source ==="
grep -q "Could not create exec service" system/core/init/builtins.cpp
! grep -q "skip ALL exec_start" system/core/init/builtins.cpp

echo "=== relink-init: fix ninja |@ if needed ==="
if ! try_ninja -n init_second_stage >/dev/null 2>&1; then
  echo "ninja dry-run failed; patching |@ dyndep syntax"
  fix_ninja_dyndep
fi

BUILTINS_OBJ="$OUT_DIR/soong/.intermediates/system/core/init/libinit/android_x86_64_static/obj/system/core/init/builtins.o"
LIBINIT_A="$OUT_DIR/soong/.intermediates/system/core/init/libinit/android_x86_64_static/libinit.a"
INIT_OUT="$OUT_DIR/soong/.intermediates/system/core/init/init_second_stage/android_x86_64/init"
INIT_INSTALL="$AOSP/$INSTALL_OUT/target/product/x86_64/system/bin/init"

echo "=== relink-init: rebuild builtins.o + libinit.a + init_second_stage ==="
try_ninja "$BUILTINS_OBJ" "$LIBINIT_A" init_second_stage

[ -f "$INIT_OUT" ] || { echo "FATAL: missing $INIT_OUT"; exit 1; }

echo "=== relink-init: install + verify ==="
mkdir -p "$(dirname "$INIT_INSTALL")"
cp -a "$INIT_OUT" "$INIT_INSTALL"
# Henry pack uses releases/Baklava64/system/bin/init too
REL_INIT="$HOME/releases/Baklava64/system/bin/init"
if [ -d "$(dirname "$REL_INIT")" ]; then
  cp -a "$INIT_OUT" "$REL_INIT"
fi

NEW_MD5=$(md5sum "$INIT_INSTALL" | awk '{print $1}')
OLD_MD5=8cadce0679613dfc3ffa0b70384556d5
echo "init md5: $NEW_MD5 (was $OLD_MD5)"
strings "$INIT_INSTALL" | grep -E "skip ALL exec_start|R174 skip wait_for_prop apexd" && {
  echo "FATAL: new init still contains bringup patch strings"
  exit 1
} || echo "bringup patch strings absent OK"

echo RELINK_INIT_DONE
