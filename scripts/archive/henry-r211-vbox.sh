#!/bin/bash
# Henry standard vbox chain for Baklava64: Root.vdi + fastboot.vdi (no ad-hoc repack)
set -euo pipefail

APP_PLAYER_DIR="${APP_PLAYER_DIR:-$HOME/app-player}"
BUILDSCRIPTS="$APP_PLAYER_DIR/buildscripts"
ANDROID_SDK_PATH="${ANDROID_SDK_PATH:-$HOME/android-sdk/sdk}"
JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-8-openjdk-amd64}"
IMAGE=Baklava64
OEM=nxt
BRANCH="${BRANCH:-bst-v5.22.210}"
ANDROID_BUILD_NUMBER="${ANDROID_BUILD_NUMBER:-local}"
PKG="${BRANCH}_${IMAGE}-${ANDROID_BUILD_NUMBER}"
ANDROIDOUTPUTLOC="${ANDROIDOUTPUTLOC:-$HOME/releases}"
AOSP="${AOSP:-$HOME/aosp16}"
OUT_DIR="$AOSP/out_nxt_Baklava64"
LOG=~/henry-r211-vbox.log

export JAVA_HOME LC_ALL=C LANG=C
export PATH="$JAVA_HOME/bin:$PATH"
export ANDROID_SDK_PATH ANDROID_HOME="$ANDROID_SDK_PATH"
export ANDROIDOUTPUTLOC PKG OEM IMAGE

exec > >(tee "$LOG") 2>&1
echo "=== Henry R211 vbox $(date) ==="

# Stale mount / artifact cleanup (build_Baklava_common pattern)
OD="$ANDROIDOUTPUTLOC/$IMAGE"
sudo umount -l "$OD/rootFS" "$OD/rootFSDebug" "$OD/dataFS" 2>/dev/null || true
sudo umount -l "$ANDROIDOUTPUTLOC/$IMAGE/$PKG/fs-to-vdi-src" 2>/dev/null || true
sudo umount -l "$ANDROIDOUTPUTLOC/$IMAGE/$PKG/fs-to-vdi-dst" 2>/dev/null || true
sudo qemu-nbd -d /dev/nbd4 /dev/nbd5 2>/dev/null || true
sudo rm -rf "$OD/rootFS" "$OD/rootFSDebug" "$OD/dataFS" 2>/dev/null || true
sudo rm -rf "$OD/rooted_root" "$OD/rooted_system" 2>/dev/null || true
cp -f "$HOME/make-baklava-system-sfs.sh" "$BUILDSCRIPTS/" 2>/dev/null || true
chmod +x "$BUILDSCRIPTS/make-baklava-system-sfs.sh" 2>/dev/null || true
[ -f "$HOME/patch-makefile-baklava-system-sfs.py" ] && python3 "$HOME/patch-makefile-baklava-system-sfs.py" || true

# Ensure A16 product path symlink (build-log 问题 4.1)
PROD_DIR="$OUT_DIR/target/product"
if [ -d "$PROD_DIR/generic_x86_64" ] && [ ! -e "$PROD_DIR/x86_64" ]; then
  ln -s generic_x86_64 "$PROD_DIR/x86_64"
fi

# Skip full m (soong regen can fail on gfxstream); use existing R192 out for copy_android_files
echo "=== skip incremental m; using existing out for Henry vbox ==="

ensure_apks_folder() {
  local dst="$APP_PLAYER_DIR/bst/apks_Baklava64"
  local henry="$APP_PLAYER_DIR/bst/apks_Baklava64"
  local henry_ref="/home/henry/workspace/app-player/bst/apks_Baklava64"
  mkdir -p "$dst"
  # Henry buildscripts expects full apks_Baklava64 (xp, baklava_appdetails, chrome, etc.)
  if [ -d "$henry_ref" ]; then
    rsync -av "$henry_ref/" "$dst/"
  fi
  [ -d "$dst/xp" ] || { echo "FATAL: missing $dst/xp after rsync"; exit 1; }
  ls -la "$dst" | head -8
}

ensure_apks_folder

echo "=== make -o android -o libs -o apks -o datafs vbox ==="
cd "$BUILDSCRIPTS"
make -o android -o libs -o apks -o datafs -f Makefile vbox \
  OEM="$OEM" IMAGE="$IMAGE" \
  ANDROIDOUTPUTLOC="$ANDROIDOUTPUTLOC" PKG="$PKG" \
  ENABLE_DEXOPT=false IS_HYPERV_BUILD=false \
  PARALLEL_NX_PROC="$(nproc)" \
  ANDROID_SDK_PATH="$ANDROID_SDK_PATH"

OUT="$ANDROIDOUTPUTLOC/$IMAGE/$PKG"
TIRAMISU64_ROOT_UUID=54e9ad31-a169-4d5b-a0e0-705d62e96e71
TIRAMISU64_FASTBOOT_UUID=91b80c95-aa7d-459d-93e4-c479f5babbb7

for f in Root.vhd fastboot.vdi; do
  [ -f "$OUT/$f" ] || { echo "MISSING $OUT/$f"; exit 1; }
done

# clonehd fails if stale Root.vhd exists (VERR_ALREADY_EXISTS)
sed -i "/Root./d" ~/.config/VirtualBox/VirtualBox.xml 2>/dev/null || true
rm -f "$OUT/Root.vhd"
VBoxManage internalcommands sethduuid "$OUT/Root.vhd" "$TIRAMISU64_ROOT_UUID"
VBoxManage internalcommands sethduuid "$OUT/fastboot.vdi" "$TIRAMISU64_FASTBOOT_UUID"

md5sum "$OUT/Root.vhd" "$OUT/fastboot.vdi"
VBoxManage showhdinfo "$OUT/Root.vhd" | head -6
VBoxManage showhdinfo "$OUT/fastboot.vdi" | head -6
echo R211_VBOX_DONE
