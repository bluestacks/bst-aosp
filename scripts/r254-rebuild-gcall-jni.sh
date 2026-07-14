#!/bin/bash
# R254: rebuild gcall + libgcall_jni with Baklava64 BUILD_T → stage → pack Root
set -eo pipefail
AOSP=~/aosp16
OD=~/releases/Baklava64
OUT=out_nxt_Baklava64
LOG=~/r254-rebuild-gcall-jni.log
exec > >(tee "$LOG") 2>&1
echo "=== R254 libgcall_jni $(date) ==="

python3 ~/bst-aosp/scripts/r254-patch-gcall-baklava.py
grep -n 'Baklava64\|BUILD_T\|R254' ~/app-player/hd/Source/gcall/guest/Android.mk

cd "$AOSP"
set +u
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 ALLOW_MISSING_DEPENDENCIES=true
export HD_SOURCE_TOP=~/app-player/hd
export JAVA_HOME=$AOSP/prebuilts/jdk/jdk21/linux-x86
export PATH=$JAVA_HOME/bin:$PATH
export ANDROID_JAVA_HOME=$JAVA_HOME
source build/envsetup.sh
lunch android_x86_64-trunk_staging-eng
set -u

NPROC=$(nproc)
echo "IMAGE=$IMAGE HD_SOURCE_TOP=$HD_SOURCE_TOP"

# Force rebuild of gcall static lib (need BUILD_T baked in)
rm -rf "$OUT/target/product/"*/obj/STATIC_LIBRARIES/gcall_intermediates \
       "$OUT/target/product/"*/obj_x86/STATIC_LIBRARIES/gcall_intermediates \
       "$OUT/target/product/"*/obj/SHARED_LIBRARIES/libgcall_jni_intermediates \
       "$OUT/target/product/"*/obj_x86/SHARED_LIBRARIES/libgcall_jni_intermediates 2>/dev/null || true

echo "--- mmm gcall/guest ---"
mmm ../hd/Source/gcall/guest -j"$NPROC"
echo "--- mmm BstCommandProcessor/jni ---"
mmm packages/apps/BstCommandProcessor/jni -j"$NPROC"

# Prefer installed lib64 path (avoid pipefail+head SIGPIPE abort)
SO="$OUT/target/product/x86_64/system/lib64/libgcall_jni.so"
if [ ! -f "$SO" ]; then
  set +e
  SO=$(find "$OUT/target/product" -path '*/system/lib64/libgcall_jni.so' -type f 2>/dev/null | head -1)
  set -e
fi
[ -n "${SO:-}" ] && [ -f "$SO" ] || {
  echo "missing libgcall_jni.so after mmm" >&2
  find "$OUT/target/product" -name 'libgcall*' 2>/dev/null | head -30 || true
  exit 1
}

echo "libgcall_jni: $SO"
ls -la "$SO"
md5sum "$SO"
# Prefer system/lib64 layout matching libhostcall_jni
mkdir -p "$OD/system/lib64"
cp -a "$SO" "$OD/system/lib64/libgcall_jni.so"
ls -la "$OD/system/lib64/libgcall_jni.so" "$OD/system/lib64/libhostcall_jni.so"
md5sum "$OD/system/lib64/libgcall_jni.so"

bash ~/make-baklava-system-sfs.sh "$OD"
md5sum "$OD/system.sfs"

bash ~/bst-aosp/scripts/r247-pack-root.sh
echo R254_DONE
