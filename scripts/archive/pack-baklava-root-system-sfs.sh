#!/bin/bash
# Incremental Root.vhd with henry system.sfs layout (make -o android/libs/apks/datafs)
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

cp ~/make-baklava-system-sfs.sh "$BS/make-baklava-system-sfs.sh"
chmod +x "$BS/make-baklava-system-sfs.sh"
python3 ~/patch-makefile-baklava-system-sfs.py
python3 ~/fix-makefile-adbd.py
python3 ~/patch-initsh-baklava-system-sfs.py

OUT_DIR=~/aosp16/out_nxt_Baklava64/target/product/x86_64
[ -f "$OUT_DIR/ramdisk.img" ] || [ -f ~/releases/Baklava64/ramdisk.img ] && \
    cp ~/releases/Baklava64/ramdisk.img "$OUT_DIR/ramdisk.img"

LOG=~/pack-baklava-system-sfs.log
echo "=== pack system.sfs Root.vdi $(date) ===" | tee "$LOG"
# Prior create_rootfs may leave setuid su owned by root
if [ -d "$ANDROIDOUTPUTLOC/$IMAGE/system" ]; then
    sudo chown -R "$(whoami):$(whoami)" "$ANDROIDOUTPUTLOC/$IMAGE/system" 2>/dev/null || true
    sudo rm -f "$ANDROIDOUTPUTLOC/$IMAGE/system/xbin/bstk/su" 2>/dev/null || true
fi
cd "$BS"
make -o android -o libs -o apks -o datafs -f Makefile Root.vdi \
    OEM="$OEM" IMAGE="$IMAGE" ANDROID_SDK_PATH="$ANDROID_SDK_PATH" \
    2>&1 | tee -a "$LOG"

OUT="$ANDROIDOUTPUTLOC/$IMAGE/$PKG"
FSBASE="$ANDROIDOUTPUTLOC/$IMAGE"
sudo qemu-nbd -d /dev/nbd0 2>/dev/null || true
cd "$BS"
bash -x ./create_vdi.sh -t root -v "$OUT/Root.vdi" -f "$FSBASE/Root.fs" 2>&1 | tail -20 | tee -a "$LOG"
sed -i "/Root./d" ~/.config/VirtualBox/VirtualBox.xml 2>/dev/null || true
VBoxManage clonehd "$OUT/Root.vdi" "$OUT/Root.vhd" --format VHD --variant Standard
VBoxManage internalcommands sethduuid "$OUT/Root.vhd" 54e9ad31-a169-4d5b-a0e0-705d62e96e71

# Verify Root.fs layout
sudo modprobe nbd max_part=8
sudo qemu-nbd -c /dev/nbd0 "$OUT/Root.vdi"
sleep 2
sudo mount /dev/nbd0p1 /mnt/bstroot
ls -la /mnt/bstroot/android/
sudo mount -o loop /mnt/bstroot/android/system.sfs /mnt/bstroot/sfs-test 2>/dev/null || mkdir -p /mnt/bstroot/sfs-test
# quick check inside sfs if mount works on host
sudo umount /mnt/bstroot/sfs-test 2>/dev/null || true
sudo umount /mnt/bstroot
sudo qemu-nbd -d /dev/nbd0
echo PACK_SYSTEM_SFS_DONE
