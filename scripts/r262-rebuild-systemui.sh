#!/bin/bash
# TEMP(R262): disable shell transitions → ninja SystemUI.apk → pack Root
# TEMPORARY bringup workaround — remove when BLAST/SF commit callbacks fixed.
set -eo pipefail
AOSP=~/aosp16
OD=~/releases/Baklava64
OUT=out_nxt_Baklava64
LOG=~/r262-rebuild-systemui.log
exec > >(tee "$LOG") 2>&1
echo "=== TEMP R262 disable shell transitions $(date) ==="

python3 ~/bst-aosp/scripts/r262-patch-disable-shell-transitions.py
rg -n "R262|ENABLE_SHELL_TRANSITIONS" \
  "$AOSP/frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell/transition/Transitions.java" \
  | head -10

export JAVA_HOME=$AOSP/prebuilts/jdk/jdk21/linux-x86
export PATH=$JAVA_HOME/bin:$PATH
export ANDROID_JAVA_HOME=$JAVA_HOME

cd "$AOSP"
NINJA=prebuilts/build-tools/linux-x86/bin/ninja
NF=$OUT/combined-android_x86_64.ninja
TARGET=$OUT/soong/.intermediates/frameworks/base/packages/SystemUI/SystemUI/android_common/SystemUI.apk

touch frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell/transition/Transitions.java
"$NINJA" -f "$NF" -j"$(nproc)" "$TARGET"
echo NINJA_EXIT=$?
ls -la "$TARGET"
md5sum "$TARGET"

# Install into release tree (prefer system_ext layout used by Baklava64)
DEST="$OD/system/system_ext/priv-app/SystemUI/SystemUI.apk"
if [ ! -f "$DEST" ]; then
  DEST=$(find "$OD/system" -name 'SystemUI.apk' 2>/dev/null | head -1)
fi
[ -n "$DEST" ] || { echo "DEST SystemUI.apk not found under $OD/system"; exit 1; }
mkdir -p "$(dirname "$DEST")"
echo "DEST=$DEST"
cp -a "$TARGET" "$DEST"
md5sum "$DEST"

# Keep installd early-start + BST shutdown intact
python3 ~/bst-aosp/scripts/r247-patch-init-installd.py "$OD/system/etc/init/hw/init.rc" || true
grep -nE 'R247|start installd|start_shutdown' "$OD/system/etc/init/hw/init.rc" | head || true

bash ~/r228-pack-root.sh
echo R262_PACK_DONE
md5sum "$OD/bst-v5.22.210_Baklava64-local/Root.vhd" 2>/dev/null \
  || md5sum "$OD"/bst-v5.22.210_Baklava64-local/Root.vhd 2>/dev/null \
  || find "$OD" -name 'Root.vhd' -printf '%p ' -exec md5sum {} \;
echo R262_DONE
