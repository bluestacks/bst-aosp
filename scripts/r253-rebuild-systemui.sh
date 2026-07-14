#!/bin/bash
# R253: AuthController null-safe → ninja SystemUI.apk → pack Root
set -eo pipefail
AOSP=~/aosp16
OD=~/releases/Baklava64
OUT=out_nxt_Baklava64
LOG=~/r253-rebuild-systemui.log
exec > >(tee "$LOG") 2>&1
echo "=== R253 SystemUI $(date) ==="

python3 ~/bst-aosp/scripts/r253-patch-authcontroller.py
# Ensure Log import exists
grep -n 'import android.util.Log' "$AOSP/frameworks/base/packages/SystemUI/src/com/android/systemui/biometrics/AuthController.java" || \
  sed -i '/^package /a import android.util.Log;' "$AOSP/frameworks/base/packages/SystemUI/src/com/android/systemui/biometrics/AuthController.java"

export JAVA_HOME=$AOSP/prebuilts/jdk/jdk21/linux-x86
export PATH=$JAVA_HOME/bin:$PATH
export ANDROID_JAVA_HOME=$JAVA_HOME

cd "$AOSP"
NINJA=prebuilts/build-tools/linux-x86/bin/ninja
NF=$OUT/combined-android_x86_64.ninja
TARGET=$OUT/soong/.intermediates/frameworks/base/packages/SystemUI/SystemUI/android_common/SystemUI.apk

touch frameworks/base/packages/SystemUI/src/com/android/systemui/biometrics/AuthController.java
"$NINJA" -f "$NF" -j"$(nproc)" "$TARGET"
echo NINJA_EXIT=$?
ls -la "$TARGET"
md5sum "$TARGET"

# Install into release tree (match existing priv-app layout)
DEST=$(find "$OD/system/priv-app" -name 'SystemUI*.apk' 2>/dev/null | head -1)
if [ -z "$DEST" ]; then
  DEST="$OD/system/system_ext/priv-app/SystemUI/SystemUI.apk"
  mkdir -p "$(dirname "$DEST")"
fi
echo "DEST=$DEST"
cp -a "$TARGET" "$DEST"
md5sum "$DEST"

bash ~/bst-aosp/scripts/r247-pack-root.sh
echo R253_DONE
