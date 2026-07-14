#!/bin/bash
# R252: disable AuthService stack → ninja services.jar → pack Root
set -eo pipefail
AOSP=~/aosp16
OD=~/releases/Baklava64
OUT=out_nxt_Baklava64
LOG=~/r252-rebuild-services.log
exec > >(tee "$LOG") 2>&1
echo "=== R252 AuthService disable $(date) ==="

python3 ~/bst-aosp/scripts/r252-patch-auth-services.py
grep -n 'R252 / Henry\|AuthService\|AuthenticationPolicyService' "$AOSP/frameworks/base/services/java/com/android/server/SystemServer.java" | head -20

export JAVA_HOME=$AOSP/prebuilts/jdk/jdk21/linux-x86
export PATH=$JAVA_HOME/bin:$PATH
export ANDROID_JAVA_HOME=$JAVA_HOME

cd "$AOSP"
NINJA=prebuilts/build-tools/linux-x86/bin/ninja
NF=$OUT/combined-android_x86_64.ninja
TARGET=$OUT/soong/.intermediates/frameworks/base/services/services/android_common/dex/services.jar
IMPL=$OUT/soong/.intermediates/frameworks/base/services/services.impl/android_common/javac/services.impl.jar

touch frameworks/base/services/java/com/android/server/SystemServer.java
rm -f "$IMPL"
"$NINJA" -f "$NF" -j"$(nproc)" "$TARGET"
echo NINJA_EXIT=$?
md5sum "$TARGET"
cp -a "$TARGET" "$OD/system/framework/services.jar"

bash ~/bst-aosp/scripts/r247-pack-root.sh
echo R252_DONE
