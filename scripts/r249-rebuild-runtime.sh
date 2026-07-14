#!/bin/bash
# R249: Henry 7Y android_os_Debug.cpp → ninja libandroid_runtime → pack Root
set -eo pipefail
AOSP=~/aosp16
OD=~/releases/Baklava64
OUT=out_nxt_Baklava64
LOG=~/r249-rebuild-runtime.log
exec > >(tee "$LOG") 2>&1
echo "=== R249 libandroid_runtime $(date) ==="

python3 ~/bst-aosp/scripts/r249-patch-debug-configgz.py
grep -n 'R249 / Henry 7Y' "$AOSP/frameworks/base/core/jni/android_os_Debug.cpp"

export JAVA_HOME=$AOSP/prebuilts/jdk/jdk21/linux-x86
export PATH=$JAVA_HOME/bin:$PATH
export ANDROID_JAVA_HOME=$JAVA_HOME

cd "$AOSP"
NINJA=prebuilts/build-tools/linux-x86/bin/ninja
NF=$OUT/combined-android_x86_64.ninja
TARGET=$OUT/soong/.intermediates/frameworks/base/core/jni/libandroid_runtime/android_x86_64_shared/libandroid_runtime.so
OBJ=$OUT/soong/.intermediates/frameworks/base/core/jni/libandroid_runtime/android_x86_64_shared/obj/frameworks/base/core/jni/android_os_Debug.o

touch frameworks/base/core/jni/android_os_Debug.cpp
rm -f "$OBJ" "$TARGET"
echo "ninja -f $NF $TARGET"
"$NINJA" -f "$NF" -j"$(nproc)" "$TARGET"
echo NINJA_EXIT=$?
ls -la "$TARGET"
md5sum "$TARGET"
# Verify strings
strings "$TARGET" | grep -F 'no /proc/config.gz' | head -2

cp -a "$TARGET" "$OD/system/lib64/libandroid_runtime.so"
# Also 32-bit if present in tree (optional)
TARGET32=$OUT/soong/.intermediates/frameworks/base/core/jni/libandroid_runtime/android_x86_x86_64_shared/libandroid_runtime.so
if [ -f "$TARGET32" ]; then
  "$NINJA" -f "$NF" -j"$(nproc)" "$TARGET32" || true
  [ -f "$TARGET32" ] && cp -a "$TARGET32" "$OD/system/lib/libandroid_runtime.so" || true
fi
md5sum "$OD/system/lib64/libandroid_runtime.so"

bash ~/bst-aosp/scripts/r247-pack-root.sh
echo R249_DONE
