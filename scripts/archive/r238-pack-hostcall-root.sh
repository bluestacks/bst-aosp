#!/bin/bash
# R238 stage libhostcall_jni.so + pack system.sfs + Root.vhd
set -euo pipefail
OD=~/releases/Baklava64
PKG=bst-v5.22.210_Baklava64-local
LIB=~/aosp16/out_nxt_Baklava64/target/product/x86_64/system/lib64/libhostcall_jni.so
LOG=~/r238-pack.log
exec > >(tee "$LOG") 2>&1
echo "=== R238 pack $(date) ==="
[ -f "$LIB" ] || { echo "missing $LIB" >&2; exit 1; }
mkdir -p "$OD/system/lib64"
cp -a "$LIB" "$OD/system/lib64/libhostcall_jni.so"
ls -la "$OD/system/lib64/libhostcall_jni.so"
md5sum "$LIB"

bash ~/make-baklava-system-sfs.sh "$OD"
md5sum "$OD/system.sfs"

export IMAGE=Baklava64 PKG=$PKG
bash ~/r228-pack-root.sh
echo R238_PACK_DONE
