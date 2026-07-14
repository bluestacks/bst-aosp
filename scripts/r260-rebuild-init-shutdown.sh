#!/bin/bash
# R260: apply Henry shutdown patches, ninja-rebuild init, stage, pack Root
set -eo pipefail
AOSP=~/aosp16
OD=~/releases/Baklava64
OUT=out_nxt_Baklava64
LOG=~/r260-rebuild-init-shutdown.log
exec > >(tee "$LOG") 2>&1
echo "=== R260 Henry shutdown $(date) ==="

python3 ~/bst-aosp/scripts/r260-patch-henry-shutdown.py

# Verify anchors
rg -n "check_status_of_last_boot|copy_cpuinfo_file|bstshutdown_sync|RemountRO" \
  "$AOSP/system/core/init/init.cpp" \
  "$AOSP/system/core/init/reboot.cpp" | head -40
rg -n "bst.config.start_shutdown|bstshutdown_core|proper_shutdown" \
  "$AOSP/system/core/rootdir/init.rc" \
  "$OD/system/etc/init/hw/init.rc" | head -30

export JAVA_HOME=$AOSP/prebuilts/jdk/jdk21/linux-x86
export PATH=$JAVA_HOME/bin:$PATH
export ANDROID_JAVA_HOME=$JAVA_HOME

cd "$AOSP"
NINJA=prebuilts/build-tools/linux-x86/bin/ninja
NF=$OUT/combined-android_x86_64.ninja
TARGET=$OUT/soong/.intermediates/system/core/init/init_second_stage/android_x86_64/init

touch system/core/init/init.cpp system/core/init/reboot.cpp
for o in \
  $OUT/soong/.intermediates/system/core/init/libinit/android_x86_64_static/obj/system/core/init/init.o \
  $OUT/soong/.intermediates/system/core/init/libinit/android_x86_64_static/obj/system/core/init/reboot.o
do
  [ -f "$o" ] && rm -f "$o" && echo "removed $o"
done

echo "ninja -f $NF $TARGET"
"$NINJA" -f "$NF" -j"$(nproc)" "$TARGET"
echo NINJA_EXIT=$?
ls -la "$TARGET"
md5sum "$TARGET"

echo "=== strings check ==="
# pipefail + head early-close can false-fail; use || true on display pipe
strings "$TARGET" | grep -F 'bstshutdown_sync' | head -10 || true
if ! strings "$TARGET" | grep -Fq '/data/.bstshutdown_sync'; then
  echo STRINGS_FAIL_NO_MARKER
  exit 2
fi
echo STRINGS_OK_SHUTDOWN

install -m 0755 "$TARGET" "$OD/system/bin/init"
# keep aosp product copy if present
PROD=$OUT/target/product/generic_x86_64/system/bin
mkdir -p "$PROD"
cp -f "$TARGET" "$PROD/init"
# Ensure release init.rc has BST block (pack reads OD/system)
# Re-apply R247 early installd after copy — stock AOSP rootdir lacks it
cp -f "$AOSP/system/core/rootdir/init.rc" "$OD/system/etc/init/hw/init.rc"
python3 ~/bst-aosp/scripts/r247-patch-init-installd.py "$AOSP/system/core/rootdir/init.rc"
python3 ~/bst-aosp/scripts/r247-patch-init-installd.py "$OD/system/etc/init/hw/init.rc"
grep -nE 'bst.config.start_shutdown|R247' "$OD/system/etc/init/hw/init.rc" | head
md5sum "$OD/system/bin/init" "$OD/system/etc/init/hw/init.rc"

bash ~/r228-pack-root.sh
echo R260_PACK_DONE
md5sum "$OD"/bst-v5.22.210_Baklava64-local/Root.vhd 2>/dev/null || \
  md5sum "$OD"/Root.vhd 2>/dev/null || \
  find "$OD" -maxdepth 2 -name 'Root.vhd' -exec md5sum {} \;
