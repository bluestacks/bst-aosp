#!/bin/bash
# R244: ninja-only rebuild of init_second_stage (avoid soong regen / mesa error)
set -eo pipefail
AOSP=~/aosp16
OUT=out_nxt_Baklava64
LOG=~/r244-ninja-init.log
cd "$AOSP"
exec > >(tee "$LOG") 2>&1
echo "=== R244 ninja init $(date) ==="

NINJA=prebuilts/build-tools/linux-x86/bin/ninja
NF=$OUT/combined-android_x86_64.ninja
TARGET=$OUT/soong/.intermediates/system/core/init/init_second_stage/android_x86_64/init
# Force rebuild of changed translation units
touch system/core/init/builtins.cpp system/core/init/init.cpp system/core/init/service.cpp
# Also bump .o mtimes so ninja definitely rebuilds even if dep scan quirks
for o in \
  $OUT/soong/.intermediates/system/core/init/libinit/android_x86_64_static/obj/system/core/init/builtins.o \
  $OUT/soong/.intermediates/system/core/init/libinit/android_x86_64_static/obj/system/core/init/init.o \
  $OUT/soong/.intermediates/system/core/init/libinit/android_x86_64_static/obj/system/core/init/service.o
do
  [ -f "$o" ] && rm -f "$o" && echo "removed $o"
done

echo "ninja -f $NF $TARGET"
"$NINJA" -f "$NF" -j"$(nproc)" "$TARGET"
echo NINJA_EXIT=$?
ls -la "$TARGET"
md5sum "$TARGET"
echo "=== strings check ==="
if strings "$TARGET" | grep -E 'R174 skip odsign|R174 skip init_user0|R173 skip wait_for_coldboot|skip exec \(vdc\)|BS bringup: skipping reboot|R173h skip critical'; then
  echo STRINGS_FAIL
  exit 2
fi
echo STRINGS_OK_HENRY_PATH
# Install into product tree if dir exists
PROD=$OUT/target/product/generic_x86_64/system/bin
mkdir -p "$PROD"
cp -f "$TARGET" "$PROD/init"
# Stage to releases
install -m 0755 "$TARGET" ~/releases/Baklava64/system/bin/init
md5sum ~/releases/Baklava64/system/bin/init
echo STAGE_DONE
