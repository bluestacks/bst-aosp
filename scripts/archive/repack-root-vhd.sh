#!/bin/bash
# Repack Root.vhd from markxu aosp16 system output (no full Android rebuild)
set -euo pipefail

export BUILD_NUMBER="${BUILD_NUMBER:-9527}"
export APP_PLAYER_DIR="${APP_PLAYER_DIR:-$HOME/app-player}"
export OEM=nxt
export IMAGE=Baklava64
export ANDROID_VERSION=baklava
export BRANCH="${BRANCH:-bst-v5.22.210}"
export ANDROID_BUILD_NUMBER="${ANDROID_BUILD_NUMBER:-local}"
export ANDROIDOUTPUTLOC="${ANDROIDOUTPUTLOC:-$HOME/releases}"
export ANDROIDOUT="$HOME/aosp16/out_nxt_Baklava64/target/product/generic_x86_64"

PKG="${BRANCH}_${IMAGE}-${ANDROID_BUILD_NUMBER}"
REL_DIR="${ANDROIDOUTPUTLOC}/${IMAGE}/${PKG}"
TIRAMISU64_ROOT_UUID="54e9ad31-a169-4d5b-a0e0-705d62e96e71"
BUILD_SCRIPTS="$APP_PLAYER_DIR/buildscripts"

echo "=== Repack Root.vhd ==="
echo "ANDROIDOUT=$ANDROIDOUT"
echo "REL_DIR=$REL_DIR"
mkdir -p "$REL_DIR"

sudo umount -d "$REL_DIR/fs-to-vdi-dst" 2>/dev/null || true
sudo umount -d "$REL_DIR/fs-to-vdi-src" 2>/dev/null || true
sudo qemu-nbd -d /dev/nbd0 2>/dev/null || true
sudo rm -rf "$REL_DIR/fs-to-vdi-src" "$REL_DIR/fs-to-vdi-dst" 2>/dev/null || true

make -f "$BUILD_SCRIPTS/Makefile" Root.vdi \
    OEM="$OEM" IMAGE="$IMAGE" \
    ANDROIDOUTPUTLOC="$ANDROIDOUTPUTLOC" PKG="$PKG" \
    ENABLE_DEXOPT=false IS_HYPERV_BUILD=false \
    PARALLEL_NX_PROC="$(nproc)" \
    ANDROID_SDK_PATH="${ANDROID_SDK_PATH:-/home/henry/workspace/android-sdk/sdk}" \
    2>&1 | tee "/tmp/repack-root-$$.log" | tail -30

ROOT_VHD="$REL_DIR/Root.vhd"
if [ -f "$ROOT_VHD" ]; then
    VBoxManage internalcommands sethduuid "$ROOT_VHD" "$TIRAMISU64_ROOT_UUID"
    ls -la "$ROOT_VHD"
    file "$ROOT_VHD"
    echo "DONE $ROOT_VHD"
else
    echo "FAILED: no Root.vhd"
    exit 1
fi
