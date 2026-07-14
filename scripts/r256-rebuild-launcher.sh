#!/bin/bash
# R256: Henry AppWidget null-guard → rebuild Launcher3QuickStep → pack Root
set -eo pipefail
AOSP=~/aosp16
OD=~/releases/Baklava64
OUT=out_nxt_Baklava64
LOG=~/r256-rebuild-launcher.log
exec > >(tee "$LOG") 2>&1
echo "=== R256 Launcher3 WidgetManager null-guard $(date) ==="

python3 ~/bst-aosp/scripts/r256-patch-widgetmanager.py
grep -n 'R256\|awm == null\|AppWidget service may not' \
  "$AOSP/packages/apps/Launcher3/src/com/android/launcher3/widget/WidgetManagerHelper.java"

export JAVA_HOME=$AOSP/prebuilts/jdk/jdk21/linux-x86
export PATH=$JAVA_HOME/bin:$PATH
export ANDROID_JAVA_HOME=$JAVA_HOME

cd "$AOSP"
NINJA=prebuilts/build-tools/linux-x86/bin/ninja
NF=$OUT/combined-android_x86_64.ninja

# Known soong intermediate (from Android-android_x86_64.mk LOCAL_PREBUILT_MODULE_FILE)
TARGET=$OUT/soong/.intermediates/packages/apps/Launcher3/Launcher3QuickStep/android_common/Launcher3QuickStep.apk
INSTALLED=$OUT/target/product/x86_64/system/system_ext/priv-app/Launcher3QuickStep/Launcher3QuickStep.apk

touch packages/apps/Launcher3/src/com/android/launcher3/widget/WidgetManagerHelper.java

echo "TARGET=$TARGET"
"$NINJA" -f "$NF" -j"$(nproc)" "$TARGET"
echo NINJA_EXIT=$?
ls -la "$TARGET"
md5sum "$TARGET"

# Also refresh installed path if ninja updates it via install rule
if [ -f "$INSTALLED" ]; then
  ls -la "$INSTALLED"
  md5sum "$INSTALLED"
fi

DEST="$OD/system/system_ext/priv-app/Launcher3QuickStep/Launcher3QuickStep.apk"
echo "DEST=$DEST"
mkdir -p "$(dirname "$DEST")"
cp -a "$TARGET" "$DEST"
md5sum "$DEST"

bash ~/make-baklava-system-sfs.sh "$OD"
sudo umount -lf "$OD/rootFS" 2>/dev/null || true
bash ~/bst-aosp/scripts/r247-pack-root.sh
md5sum "$OD/bst-v5.22.210_Baklava64-local/Root.vhd"
echo R256_DONE
