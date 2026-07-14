#!/bin/bash
# R238: Henry hostcall_gcall_libs → stage libhostcall_jni.so → system.sfs → Root.vhd
set -euo pipefail
OD=~/releases/Baklava64
PKG=bst-v5.22.210_Baklava64-local
AOSP=~/aosp16
OUT=$AOSP/out_nxt_Baklava64
SYS=$OD/system
LOG=~/r238-hostcall.log
exec > >(tee "$LOG") 2>&1
echo "=== R238 hostcall+system $(date) ==="

cd "$AOSP"
set +u
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 ALLOW_MISSING_DEPENDENCIES=true
export HD_SOURCE_TOP=~/app-player/hd
source build/envsetup.sh
lunch android_x86_64-trunk_staging-eng
set -u

NPROC=$(nproc)
echo "--- mmm xpl ---"
mmm ../hd/Source/xpl -j"$NPROC"
echo "--- mmm vmsg/guest ---"
mmm ../hd/Source/vmsg/guest -j"$NPROC"
echo "--- mmm hcall/guest ---"
mmm ../hd/Source/hcall/guest -j"$NPROC"
echo "--- mmm gcall/guest ---"
mmm ../hd/Source/gcall/guest -j"$NPROC"
echo "--- mmm libhostcall_jni ---"
mmm frameworks/base/services/java/com/bluestacks/server/native -j"$NPROC"

LIB64="$OUT/target/product/x86_64/system/lib64/libhostcall_jni.so"
[ -f "$LIB64" ] || LIB64="$OUT/target/product/x86_64/obj/PACKAGING/target_files_intermediates/android_x86_64-trunk_staging-eng/android_x86_64-trunk_staging-eng-target_files/SYSTEM/lib64/libhostcall_jni.so"
if [ ! -f "$LIB64" ]; then
  LIB64=$(find "$OUT" -name libhostcall_jni.so -type f 2>/dev/null | head -1)
fi
[ -n "$LIB64" ] && [ -f "$LIB64" ] || { echo "missing libhostcall_jni.so after mmm" >&2; find "$OUT" -name 'libhostcall*' 2>/dev/null; exit 1; }

echo "libhostcall_jni: $LIB64"
ls -la "$LIB64"
md5sum "$LIB64"

mkdir -p "$SYS/lib64"
cp -a "$LIB64" "$SYS/lib64/libhostcall_jni.so"
ls -la "$SYS/lib64/libhostcall_jni.so"

# Optional: copy gcall if built (launcher bridge may need it)
for extra in libgcall_jni.so libbstconf.so; do
  f=$(find "$OUT/target/product/x86_64/system/lib64" -name "$extra" 2>/dev/null | head -1)
  [ -n "$f" ] && cp -a "$f" "$SYS/lib64/" && echo "staged $extra"
done

bash ~/make-baklava-system-sfs.sh "$OD"
md5sum "$OD/system.sfs"

export IMAGE=Baklava64 PKG=$PKG
bash ~/r228-pack-root.sh
echo R238_HOSTCALL_DONE
