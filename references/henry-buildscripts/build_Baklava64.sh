#!/bin/bash
set -euo pipefail

export APP_PLAYER_DIR=/home/henry/workspace/app-player
export BUILD_NUMBER="${BUILD_NUMBER:-9527}"

BUILD_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=build_Baklava_common.sh
source "$BUILD_SCRIPTS_DIR/build_Baklava_common.sh"
baklava_build "Baklava64"

# Temporary: rewrite Root.vhd / fastboot.vdi UUIDs for Tiramisu64(A13) test shell bringup.
# Remove once A16 ships with native UUID / own engine slot.
#
# 背景：测试壳是 A13(Tiramisu64) 引擎，BstkGlobal.xml 媒体注册表里记的是 A13 镜像的 UUID；
# 我们独立编出来的 A16 盘 UUID 不同，必须改回去才能在 A13 壳里挂载。
# 见 A16-init-bringup-notes.md 第 1 节。
IMAGE=Baklava64
PKG="${BRANCH}_${IMAGE}-${ANDROID_BUILD_NUMBER}"
REL_DIR="${ANDROIDOUTPUTLOC}/${IMAGE}/${PKG}"
TIRAMISU64_ROOT_UUID="54e9ad31-a169-4d5b-a0e0-705d62e96e71"
TIRAMISU64_FASTBOOT_UUID="91b80c95-aa7d-459d-93e4-c479f5babbb7"

# --- Root.vhd ---
ROOT_VHD="${REL_DIR}/Root.vhd"
if [ -f "$ROOT_VHD" ]; then
    echo "=== Temporary Tiramisu64 test UUID on Root.vhd ==="
    echo "ROOT_VHD=$ROOT_VHD"
    echo "UUID=$TIRAMISU64_ROOT_UUID"
    VBoxManage internalcommands sethduuid "$ROOT_VHD" "$TIRAMISU64_ROOT_UUID"
    md5sum "$ROOT_VHD"
else
    echo "WARNING: Root.vhd not found at $ROOT_VHD (skip UUID rewrite)" >&2
fi

# --- fastboot.vdi ---
# 注意：fastboot.vdi 在 hd/guest/BootImage/fastboot/cp_bzImage_initrd.sh 里生成时用的 UUID 是
# 7c4e9a21-3b6f-4d8e-a1c2-5f0e8d3b7a94（A16 自带），与 Tiramisu64 测试壳期望的不一致，需要改写。
FASTBOOT_VDI="${REL_DIR}/fastboot.vdi"
if [ -f "$FASTBOOT_VDI" ]; then
    echo "=== Temporary Tiramisu64 test UUID on fastboot.vdi ==="
    echo "FASTBOOT_VDI=$FASTBOOT_VDI"
    echo "UUID=$TIRAMISU64_FASTBOOT_UUID"
    VBoxManage internalcommands sethduuid "$FASTBOOT_VDI" "$TIRAMISU64_FASTBOOT_UUID"
    md5sum "$FASTBOOT_VDI"
else
    echo "WARNING: fastboot.vdi not found at $FASTBOOT_VDI (skip UUID rewrite)" >&2
fi
