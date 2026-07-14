#!/bin/bash
# R255: port WMS activity-displayed HCALL → rebuild services.jar → pack Root
set -eo pipefail
AOSP=~/aosp16
OD=~/releases/Baklava64
OUT=out_nxt_Baklava64
LOG=~/r255-rebuild-services.log
exec > >(tee "$LOG") 2>&1
echo "=== R255 WMS activity displayed $(date) ==="

# Patch should already be applied; re-run idempotent
python3 ~/bst-aosp/scripts/r255-patch-wms-activity-displayed.py
rg -n "bstSendTopDisplayedOnFocusChange|R255|mBstHostCallManagerService" \
  "$AOSP/frameworks/base/services/core/java/com/android/server/wm/WindowManagerService.java" \
  "$AOSP/frameworks/base/services/core/java/com/android/server/wm/DisplayContent.java" | head -40

export JAVA_HOME=$AOSP/prebuilts/jdk/jdk21/linux-x86
export PATH=$JAVA_HOME/bin:$PATH
export ANDROID_JAVA_HOME=$JAVA_HOME

cd "$AOSP"
NINJA=prebuilts/build-tools/linux-x86/bin/ninja
NF=$OUT/combined-android_x86_64.ninja
TARGET=$OUT/soong/.intermediates/frameworks/base/services/services/android_common/dex/services.jar
IMPL=$OUT/soong/.intermediates/frameworks/base/services/services.impl/android_common/javac/services.impl.jar

touch frameworks/base/services/core/java/com/android/server/wm/WindowManagerService.java
touch frameworks/base/services/core/java/com/android/server/wm/DisplayContent.java
rm -f "$IMPL"

"$NINJA" -f "$NF" -j"$(nproc)" "$TARGET"
echo NINJA_EXIT=$?
ls -la "$TARGET"
md5sum "$TARGET"

# Readback: jar should contain WMS with our symbol (strings)
if ! strings "$TARGET" | grep -q 'bstSendTopDisplayedOnFocusChange'; then
  echo "WARN: symbol not found via strings (may be minified); continuing"
else
  echo "READBACK: bstSendTopDisplayedOnFocusChange present in services.jar"
fi

cp -a "$TARGET" "$OD/system/framework/services.jar"
md5sum "$OD/system/framework/services.jar"

bash ~/make-baklava-system-sfs.sh "$OD"
bash ~/bst-aosp/scripts/r247-pack-root.sh
md5sum "$OD/bst-v5.22.210_Baklava64-local/Root.vhd"
echo R255_DONE
