#!/bin/bash
# R258: rebuild framework-minus-apex (contains LockPatternUtils) → pack Root
set -eo pipefail
AOSP=~/aosp16
OD=~/releases/Baklava64
OUT=out_nxt_Baklava64
LOG=~/r258-rebuild-lockscreen.log
exec > >(tee "$LOG") 2>&1
echo "=== R258 Henry lockscreen disabled $(date) ==="

python3 ~/bst-aosp/scripts/r258-patch-lockscreen.py

export JAVA_HOME=$AOSP/prebuilts/jdk/jdk21/linux-x86
export PATH=$JAVA_HOME/bin:$PATH
export ANDROID_JAVA_HOME=$JAVA_HOME
export OUT_DIR=$OUT

cd "$AOSP"
touch frameworks/base/core/java/com/android/internal/widget/LockPatternUtils.java

# Prefer soong module framework-minus-apex (A16 framework.jar content)
NINJA=prebuilts/build-tools/linux-x86/bin/ninja
NF=$OUT/combined-android_x86_64.ninja

# Installed framework.jar path after build
INSTALLED=$OUT/target/product/x86_64/system/framework/framework.jar

# Build via make module name (resolves deps correctly)
set +e
source build/envsetup.sh
lunch android_x86_64-trunk_staging-eng
m framework-minus-apex
M_EXIT=$?
set -e
echo M_EXIT=$M_EXIT

# Fallback: ninja any framework-minus-apex jar that looks like the final package
if [ ! -f "$INSTALLED" ]; then
  CAND=$(find $OUT/soong/.intermediates/frameworks/base/framework-minus-apex -name 'framework-minus-apex.jar' 2>/dev/null | head -1)
  echo "CAND=$CAND"
  [ -n "$CAND" ] && INSTALLED=$CAND
fi

ls -la "$INSTALLED" || { echo "missing installed framework.jar"; exit 1; }
md5sum "$INSTALLED"

DEST="$OD/system/framework/framework.jar"
cp -a "$INSTALLED" "$DEST"
md5sum "$DEST"

# Keep uncube libs present
ls -la "$OD/system/priv-app/com.uncube.launcher3/lib/x86_64/" || true

bash ~/make-baklava-system-sfs.sh "$OD"
sudo umount -lf "$OD/rootFS" 2>/dev/null || true
bash ~/bst-aosp/scripts/r247-pack-root.sh
md5sum "$OD/bst-v5.22.210_Baklava64-local/Root.vhd"
echo R258_DONE
