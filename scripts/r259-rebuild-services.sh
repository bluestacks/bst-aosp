#!/bin/bash
# R259: RESUMED → onActivityDisplayed; rebuild services.jar; pack Root
set -eo pipefail
AOSP=~/aosp16
OD=~/releases/Baklava64
OUT=out_nxt_Baklava64
LOG=~/r259-rebuild-services.log
exec > >(tee "$LOG") 2>&1
echo "=== R259 ActivityRecord RESUMED notify $(date) ==="

python3 ~/bst-aosp/scripts/r259-patch-activity-resumed.py
rg -n "R259|bstNotifyActivityDisplayed" \
  "$AOSP/frameworks/base/services/core/java/com/android/server/wm/WindowManagerService.java" \
  "$AOSP/frameworks/base/services/core/java/com/android/server/wm/ActivityRecord.java" | head -30

export JAVA_HOME=$AOSP/prebuilts/jdk/jdk21/linux-x86
export PATH=$JAVA_HOME/bin:$PATH
export ANDROID_JAVA_HOME=$JAVA_HOME

cd "$AOSP"
NINJA=prebuilts/build-tools/linux-x86/bin/ninja
NF=$OUT/combined-android_x86_64.ninja
TARGET=$OUT/soong/.intermediates/frameworks/base/services/java/services/android_common/services.jar

# common alternate
if [ ! -f "$NF" ]; then echo missing ninja; exit 1; fi
# discover if needed
if ! "$NINJA" -f "$NF" -t query "$TARGET" >/dev/null 2>&1; then
  TARGET=$OUT/soong/.intermediates/frameworks/base/services/java/services/android_common/javac/services.jar
fi
# Prefer installed path from mk
INST_PAIR=$(rg -n "LOCAL_MODULE := services$" -A5 "$OUT/soong/Android-android_x86_64.mk" | rg "LOCAL_SOONG_INSTALLED_MODULE|LOCAL_PREBUILT" | head -5 || true)
echo "$INST_PAIR"

# Use known good path from prior rounds
TARGET=$OUT/soong/.intermediates/frameworks/base/services/java/services/android_common/services.jar
# If missing, try withres/aligned variants
for cand in \
  "$OUT/soong/.intermediates/frameworks/base/services/java/services/android_common/combined/services.jar" \
  "$OUT/soong/.intermediates/frameworks/base/services/java/services/android_common/dex/services.jar" \
  "$OUT/target/product/x86_64/system/framework/services.jar"
do
  [ -f "$cand" ] && echo "exists $cand"
done

# From previous R255 rebuild pattern:
TARGET=$(rg -o "out_nxt_Baklava64/soong/.intermediates/frameworks/base/services[^ ]*services\.jar" \
  "$OUT/soong/Android-android_x86_64.mk" 2>/dev/null | head -1 || true)
if [ -z "$TARGET" ]; then
  TARGET=$OUT/soong/.intermediates/frameworks/base/services/java/services/android_common/dex/services.jar
fi
echo "TARGET=$TARGET"

touch frameworks/base/services/core/java/com/android/server/wm/WindowManagerService.java \
  frameworks/base/services/core/java/com/android/server/wm/ActivityRecord.java

"$NINJA" -f "$NF" -j"$(nproc)" "$TARGET"
echo NINJA_EXIT=$?
ls -la "$TARGET"
md5sum "$TARGET"

DEST="$OD/system/framework/services.jar"
# Prefer installed module if present
if [ -f "$OUT/target/product/x86_64/system/framework/services.jar" ]; then
  cp -a "$OUT/target/product/x86_64/system/framework/services.jar" "$DEST"
else
  cp -a "$TARGET" "$DEST"
fi
md5sum "$DEST"

# keep prior stages
ls "$OD/system/priv-app/com.uncube.launcher3/lib/x86_64/libflutter.so"
ls "$OD/system/framework/framework.jar"

bash ~/make-baklava-system-sfs.sh "$OD"
sudo umount -lf "$OD/rootFS" 2>/dev/null || true
bash ~/bst-aosp/scripts/r247-pack-root.sh
md5sum "$OD/bst-v5.22.210_Baklava64-local/Root.vhd"
echo R259_DONE
