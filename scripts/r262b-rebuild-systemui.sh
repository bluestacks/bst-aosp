#!/bin/bash
# TEMP(R262b): gate TransitionPlayer → ninja SystemUI.apk → pack Root
# TEMPORARY bringup workaround (with R262) — remove when BLAST/SF commit fixed.
set -eo pipefail
AOSP=~/aosp16
OD=~/releases/Baklava64
OUT=out_nxt_Baklava64
LOG=~/r262b-rebuild-systemui.log
exec > >(tee "$LOG") 2>&1
echo "=== TEMP R262b gate TransitionPlayer $(date) ==="

python3 ~/bst-aosp/scripts/r262-patch-disable-shell-transitions.py
python3 ~/bst-aosp/scripts/r262b-patch-gate-transition-player.py
rg -n "R262|ENABLE_SHELL_TRANSITIONS|registerTransitionPlayer" \
  "$AOSP/frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell/transition/Transitions.java" \
  | head -30

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

DEST="$OD/system/system_ext/priv-app/SystemUI/SystemUI.apk"
mkdir -p "$(dirname "$DEST")"
cp -a "$TARGET" "$DEST"
md5sum "$DEST"

python3 ~/bst-aosp/scripts/r247-patch-init-installd.py "$OD/system/etc/init/hw/init.rc" || true
bash ~/r228-pack-root.sh
echo R262B_PACK_DONE
md5sum "$OD/bst-v5.22.210_Baklava64-local/Root.vhd"
echo R262B_DONE
