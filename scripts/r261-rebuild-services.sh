#!/bin/bash
# R261: enable AuthService; ninja services.jar; pack Root
set -eo pipefail
AOSP=~/aosp16
OD=~/releases/Baklava64
OUT=out_nxt_Baklava64
LOG=~/r261-rebuild-services.log
exec > >(tee "$LOG") 2>&1
echo "=== R261 AuthService for Settings $(date) ==="

python3 ~/bst-aosp/scripts/r261-patch-auth-service.py
rg -n "R261|startService\(AuthService|startService\(AuthenticationPolicy|startService\(BiometricService" \
  "$AOSP/frameworks/base/services/java/com/android/server/SystemServer.java" | head -20

export JAVA_HOME=$AOSP/prebuilts/jdk/jdk21/linux-x86
export PATH=$JAVA_HOME/bin:$PATH
export ANDROID_JAVA_HOME=$JAVA_HOME

cd "$AOSP"
NINJA=prebuilts/build-tools/linux-x86/bin/ninja
NF=$OUT/combined-android_x86_64.ninja

# Prefer aligned/services.jar from prior rounds
TARGET=""
for cand in \
  "$OUT/soong/.intermediates/frameworks/base/services/services/android_common/aligned/services.jar" \
  "$OUT/soong/.intermediates/frameworks/base/services/java/services/android_common/aligned/services.jar" \
  "$OUT/soong/.intermediates/frameworks/base/services/java/services/android_common/dex/services.jar" \
  "$OUT/target/product/generic_x86_64/system/framework/services.jar" \
  "$OUT/target/product/x86_64/system/framework/services.jar"
do
  if [ -f "$cand" ]; then TARGET=$cand; echo "found $cand"; break; fi
done
# Fallback: ask ninja for services module jar
if [ -z "$TARGET" ]; then
  TARGET=$OUT/soong/.intermediates/frameworks/base/services/java/services/android_common/services.jar
fi
echo "TARGET=$TARGET"

touch frameworks/base/services/java/com/android/server/SystemServer.java

"$NINJA" -f "$NF" -j"$(nproc)" "$TARGET" || {
  # try common alternate ninja path
  ALT=$OUT/soong/.intermediates/frameworks/base/services/services/android_common/aligned/services.jar
  echo "retry ALT=$ALT"
  "$NINJA" -f "$NF" -j"$(nproc)" "$ALT"
  TARGET=$ALT
}
echo NINJA_EXIT=$?
ls -la "$TARGET"
md5sum "$TARGET"

# Prefer newest jar under intermediates
BEST=$(ls -t \
  $OUT/soong/.intermediates/frameworks/base/services/*/android_common/aligned/services.jar \
  $OUT/soong/.intermediates/frameworks/base/services/java/services/android_common/aligned/services.jar \
  $OUT/target/product/*/system/framework/services.jar \
  2>/dev/null | head -1)
[ -n "$BEST" ] && TARGET=$BEST && echo "BEST=$TARGET" && md5sum "$TARGET"

install -m 0644 "$TARGET" "$OD/system/framework/services.jar"
md5sum "$OD/system/framework/services.jar"

# Keep R247 + R260 init.rc intact
python3 ~/bst-aosp/scripts/r247-patch-init-installd.py "$OD/system/etc/init/hw/init.rc" || true
grep -nE 'R247|start_shutdown|AuthService' "$OD/system/etc/init/hw/init.rc" | head || true

bash ~/r228-pack-root.sh
echo R261_PACK_DONE
md5sum "$OD/bst-v5.22.210_Baklava64-local/Root.vhd"
