#!/bin/bash
# R254b: stage already-built libgcall_jni.so → system.sfs → Root.vhd
set -eo pipefail
AOSP=~/aosp16
OD=~/releases/Baklava64
OUT=$AOSP/out_nxt_Baklava64
LOG=~/r254b-pack-gcall.log
exec > >(tee "$LOG") 2>&1
echo "=== R254b pack libgcall_jni $(date) ==="

SO="$OUT/target/product/x86_64/system/lib64/libgcall_jni.so"
[ -f "$SO" ] || { echo "missing $SO"; exit 1; }
ls -la "$SO"
md5sum "$SO"

# Also stage 32-bit if present (BstCommandProcessor may be 64-only but install both)
mkdir -p "$OD/system/lib64" "$OD/system/lib"
cp -a "$SO" "$OD/system/lib64/libgcall_jni.so"
SO32="$OUT/target/product/x86_64/system/lib/libgcall_jni.so"
if [ -f "$SO32" ]; then
  cp -a "$SO32" "$OD/system/lib/libgcall_jni.so"
  ls -la "$OD/system/lib/libgcall_jni.so"
fi
ls -la "$OD/system/lib64/libgcall_jni.so" "$OD/system/lib64/libhostcall_jni.so"
md5sum "$OD/system/lib64/libgcall_jni.so"

bash ~/make-baklava-system-sfs.sh "$OD"
md5sum "$OD/system.sfs"

bash ~/bst-aosp/scripts/r247-pack-root.sh
ROOTVHD="$OD/bst-v5.22.210_Baklava64-local/Root.vhd"
ls -la "$ROOTVHD"
md5sum "$ROOTVHD"
echo R254B_DONE
