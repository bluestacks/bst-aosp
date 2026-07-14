#!/bin/bash
# R257: Henry HOME — remove Launcher3 HOME, stage com.uncube.launcher3, rebuild, pack Root
set -eo pipefail
AOSP=~/aosp16
OD=~/releases/Baklava64
OUT=out_nxt_Baklava64
LOG=~/r257-rebuild-home.log
exec > >(tee "$LOG") 2>&1
echo "=== R257 Henry HOME + uncube $(date) ==="

python3 ~/bst-aosp/scripts/r257-patch-launcher-home.py
rg -n "R257|category.HOME|uncube.launcher3|QuickstepLauncher" \
  "$AOSP/packages/apps/Launcher3/AndroidManifest.xml" \
  "$AOSP/packages/apps/Launcher3/quickstep/AndroidManifest-launcher.xml" \
  "$AOSP/packages/apps/Launcher3/quickstep/src/com/android/quickstep/OverviewComponentObserver.java" \
  | head -40

# Stage uncube as system app (sole HOME after Launcher3 HOME removed)
UNCUBE_SRC="$OD/dataFS/downloads/com.uncube.launcher3/com.uncube.launcher3.apk"
UNCUBE_DEST_DIR="$OD/system/priv-app/com.uncube.launcher3"
if [ ! -f "$UNCUBE_SRC" ]; then
  echo "MISSING $UNCUBE_SRC"
  exit 1
fi
mkdir -p "$UNCUBE_DEST_DIR/lib/x86_64"
cp -a "$UNCUBE_SRC" "$UNCUBE_DEST_DIR/com.uncube.launcher3.apk"
chmod 644 "$UNCUBE_DEST_DIR/com.uncube.launcher3.apk"
# System priv-app does not extract APK libs; Flutter needs lib/x86_64 next to APK.
rm -rf /tmp/uncube_extract && mkdir -p /tmp/uncube_extract
( cd /tmp/uncube_extract && unzip -qo "$UNCUBE_SRC" "lib/x86_64/*" )
cp -a /tmp/uncube_extract/lib/x86_64/. "$UNCUBE_DEST_DIR/lib/x86_64/"
ls -la "$UNCUBE_DEST_DIR/lib/x86_64/"
# also mirror into AOSP product out if present (for consistency)
mkdir -p "$AOSP/$OUT/target/product/x86_64/system/priv-app/com.uncube.launcher3"
cp -a "$UNCUBE_DEST_DIR/com.uncube.launcher3.apk" \
  "$AOSP/$OUT/target/product/x86_64/system/priv-app/com.uncube.launcher3/"
md5sum "$UNCUBE_DEST_DIR/com.uncube.launcher3.apk"
echo "UNCUBE_STAGED"

export JAVA_HOME=$AOSP/prebuilts/jdk/jdk21/linux-x86
export PATH=$JAVA_HOME/bin:$PATH
export ANDROID_JAVA_HOME=$JAVA_HOME

cd "$AOSP"
NINJA=prebuilts/build-tools/linux-x86/bin/ninja
NF=$OUT/combined-android_x86_64.ninja
TARGET=$OUT/soong/.intermediates/packages/apps/Launcher3/Launcher3QuickStep/android_common/Launcher3QuickStep.apk

touch packages/apps/Launcher3/AndroidManifest.xml \
  packages/apps/Launcher3/quickstep/AndroidManifest-launcher.xml \
  packages/apps/Launcher3/quickstep/src/com/android/quickstep/OverviewComponentObserver.java

echo "TARGET=$TARGET"
"$NINJA" -f "$NF" -j"$(nproc)" "$TARGET"
echo NINJA_EXIT=$?
ls -la "$TARGET"
md5sum "$TARGET"

DEST="$OD/system/system_ext/priv-app/Launcher3QuickStep/Launcher3QuickStep.apk"
mkdir -p "$(dirname "$DEST")"
cp -a "$TARGET" "$DEST"
md5sum "$DEST"

# Verify rebuilt APK no longer declares HOME
AAPT2=$AOSP/$OUT/host/linux-x86/bin/aapt2
if [ -x "$AAPT2" ]; then
  if "$AAPT2" dump xmltree "$DEST" AndroidManifest.xml 2>/dev/null | grep -q 'android.intent.category.HOME'; then
    echo "WARN: Launcher3QuickStep still declares HOME"
  else
    echo "OK: Launcher3QuickStep HOME removed"
  fi
  "$AAPT2" dump badging "$UNCUBE_DEST_DIR/com.uncube.launcher3.apk" | head -5 || true
fi

bash ~/make-baklava-system-sfs.sh "$OD"
sudo umount -lf "$OD/rootFS" 2>/dev/null || true
bash ~/bst-aosp/scripts/r247-pack-root.sh
md5sum "$OD/bst-v5.22.210_Baklava64-local/Root.vhd"
echo R257_DONE
