#!/bin/bash
# R248: Henry 7W-2/7X-1 SystemServer patches → ninja services.jar (JDK21) → pack Root
set -eo pipefail
AOSP=~/aosp16
OD=~/releases/Baklava64
OUT=out_nxt_Baklava64
LOG=~/r248-rebuild-services.log
exec > >(tee "$LOG") 2>&1
echo "=== R248 ninja services $(date) ==="

python3 ~/bst-aosp/scripts/r248-patch-systemserver.py
grep -n 'R248 / Henry' "$AOSP/frameworks/base/services/java/com/android/server/SystemServer.java"

export JAVA_HOME=$AOSP/prebuilts/jdk/jdk21/linux-x86
export PATH=$JAVA_HOME/bin:$PATH
export ANDROID_JAVA_HOME=$JAVA_HOME
java -version

cd "$AOSP"
NINJA=prebuilts/build-tools/linux-x86/bin/ninja
NF=$OUT/combined-android_x86_64.ninja
TARGET=$OUT/soong/.intermediates/frameworks/base/services/services/android_common/dex/services.jar
IMPL_JAVAC=$OUT/soong/.intermediates/frameworks/base/services/services.impl/android_common/javac/services.impl.jar

# Only invalidate SystemServer compile unit — do NOT wipe turbine/combined (causes cascade)
touch frameworks/base/services/java/com/android/server/SystemServer.java
if [ -f "$IMPL_JAVAC" ]; then
  rm -f "$IMPL_JAVAC"
  echo "removed $IMPL_JAVAC"
fi

echo "ninja -f $NF $TARGET"
"$NINJA" -f "$NF" -j"$(nproc)" "$TARGET"
echo NINJA_EXIT=$?
ls -la "$TARGET"
md5sum "$TARGET"

# Verify strings show commented-out start (class still present but startService for HintManager absent in bytecode is hard;
# check source was used by comparing jar size / rebuild time).
cp -a "$TARGET" "$OD/system/framework/services.jar"
ls -la "$OD/system/framework/services.jar"
md5sum "$OD/system/framework/services.jar"

bash ~/bst-aosp/scripts/r247-pack-root.sh
echo R248_DONE
