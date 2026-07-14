#!/bin/bash
# Incremental Root.vhd repack — skip android/libs/apks/datafs rebuild (see docs/build-commands.md)
set -euo pipefail
APP_PLAYER=~/app-player
BS=~/app-player/buildscripts
export ANDROIDOUTPUTLOC="${ANDROIDOUTPUTLOC:-$HOME/releases}"
export PKG="${PKG:-bst-v5.22.210_Baklava64-local}"
export OEM="${OEM:-nxt}"
export IMAGE="${IMAGE:-Baklava64}"
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-8-openjdk-amd64}"
export LC_ALL=C LANG=C
export PATH="$JAVA_HOME/bin:$PATH"
export ANDROID_SDK_PATH="${ANDROID_SDK_PATH:-$HOME/android-sdk/sdk}"
export ANDROID_HOME="$ANDROID_SDK_PATH"
export FLUTTER_ROOT="${FLUTTER_ROOT:-$HOME/flutter}"
export PATH="$FLUTTER_ROOT/bin:$PATH"

OUT_SYS=~/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/system
[ -d "$OUT_SYS" ] || OUT_SYS=~/aosp16/out_nxt_Baklava64/target/product/x86_64/system
if [ ! -d "$OUT_SYS" ]; then
    echo "missing android system out — run android target first" >&2
    exit 1
fi

# henry-aligned: rooted adbd into staged system before Root.fs (baklava skips Root.fs.debug)
OUT_DIR=~/aosp16/out_nxt_Baklava64/target/product/x86_64
if [ ! -f "$OUT_DIR/ramdisk.img" ] && [ -f ~/releases/Baklava64/ramdisk.img ]; then
    cp ~/releases/Baklava64/ramdisk.img "$OUT_DIR/ramdisk.img"
    echo "staged ramdisk.img from prior releases pack"
fi
if [ ! -d "$OUT_DIR/root" ] && [ -d ~/releases/Baklava64/root ]; then
    cp -a ~/releases/Baklava64/root "$OUT_DIR/root"
    echo "staged root/ from prior releases pack"
fi

cp ~/make-baklava-system-sfs.sh "$BS/make-baklava-system-sfs.sh" 2>/dev/null || true
chmod +x "$BS/make-baklava-system-sfs.sh" 2>/dev/null || true
python3 ~/patch-makefile-baklava-system-sfs.py 2>/dev/null || true
ADBD=~/app-player/tools/tiramisu/adbd_rooted_tiramisu
if [ -f "$ADBD" ]; then
    python3 ~/fix-makefile-adbd.py
fi

LOG=~/incremental-root-vhd.log
echo "=== incremental Root.vdi $(date) ===" | tee "$LOG"
echo "ANDROIDOUTPUTLOC=$ANDROIDOUTPUTLOC PKG=$PKG IMAGE=$IMAGE" | tee -a "$LOG"

cd "$BS"
make -o android -o libs -o apks -o datafs -f Makefile Root.vdi \
    OEM="$OEM" IMAGE="$IMAGE" ANDROID_SDK_PATH="$ANDROID_SDK_PATH" \
    2>&1 | tee -a "$LOG"

ROOT_VHD="$ANDROIDOUTPUTLOC/$IMAGE/$PKG/Root.vhd"
if [ -f "$ROOT_VHD" ]; then
    VBoxManage internalcommands sethduuid "$ROOT_VHD" 54e9ad31-a169-4d5b-a0e0-705d62e96e71
    ls -la "$ROOT_VHD"
    echo INCREMENTAL_ROOT_DONE
else
    echo "ERROR: $ROOT_VHD not found" >&2
    exit 1
fi
