#!/bin/bash
# R251: Henry SecureLock null-safe → ninja services.jar → pack Root
set -eo pipefail
AOSP=~/aosp16
OD=~/releases/Baklava64
OUT=out_nxt_Baklava64
LOG=~/r251-rebuild-services.log
exec > >(tee "$LOG") 2>&1
echo "=== R251 SecureLock $(date) ==="

python3 ~/bst-aosp/scripts/r251-patch-securelock.py
grep -n 'R251 / Henry' "$AOSP/frameworks/base/services/core/java/com/android/server/security/authenticationpolicy/SecureLockDeviceService.java"

export JAVA_HOME=$AOSP/prebuilts/jdk/jdk21/linux-x86
export PATH=$JAVA_HOME/bin:$PATH
export ANDROID_JAVA_HOME=$JAVA_HOME

cd "$AOSP"
NINJA=prebuilts/build-tools/linux-x86/bin/ninja
NF=$OUT/combined-android_x86_64.ninja
TARGET=$OUT/soong/.intermediates/frameworks/base/services/services/android_common/dex/services.jar
IMPL=$OUT/soong/.intermediates/frameworks/base/services/services.impl/android_common/javac/services.impl.jar

touch frameworks/base/services/core/java/com/android/server/security/authenticationpolicy/SecureLockDeviceService.java
rm -f "$IMPL"
"$NINJA" -f "$NF" -j"$(nproc)" "$TARGET"
echo NINJA_EXIT=$?
md5sum "$TARGET"
cp -a "$TARGET" "$OD/system/framework/services.jar"

bash ~/bst-aosp/scripts/r247-pack-root.sh
echo R251_DONE
