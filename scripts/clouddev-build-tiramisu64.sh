#!/bin/bash
# =============================================================================
# clouddev-build-tiramisu64.sh — Win Tiramisu64 (android-13) guest 镜像全流程构建
# =============================================================================
# 在 clouddev (markxu@172.16.6.191) 上运行。固化全量/重打包两条路径 + 所有已知坑修复。
#
# 用法:
#   全量重编(android 源码变了):   ./clouddev-build-tiramisu64.sh full
#   仅重打包(apk/配置变了):       ./clouddev-build-tiramisu64.sh repack
#   仅修复 UUID 匹配 Windows:     ./clouddev-build-tiramisu64.sh uuid
#
# 产物: ~/releases/Tiramisu64/bst-v5.22.210_Tiramisu64-local/{Root.vhd,fastboot.vdi}
#        UUID 已匹配 Windows BlueStacks_nxt Tiramisu64.bstk
#
# 已知坑(均已内置修复,见 progress/porting-log.md):
#   1. chown 1000:1000 硬编码 -> Makefile 改 $(shell id -u):$(shell id -g) (markxu UID=1011)
#   2. create_setuid_su_binary 的 bstk/ 0511 残留 -> sudo rm 清 + cp 前预 chmod 0755
#   3. root 污染文件残留(rootFS/Root.fs/dataFS root-owned) -> sudo rm -rf 清(henry 式)
#   4. nowgg-common 断链(/home/build/workspace clouddev 不可得) -> build_nowgg_common_apks.sh no-op
#   5. make Root.vdi 全量重编(make_vars regenerate -> 118k targets ~4h) -> 仅 apk 变更用 repack
#   6. ramdisk.img 被 android target 的 rm -f *.img 删 -> 全量 build 会重生成; repack 前确保存在
#   7. clonehd VDI->VHD 后 sethduuid 改了 UUID, Windows .bstk 还记旧 UUID -> 本脚本 uuid 子命令匹配
# =============================================================================

set -euo pipefail

MODE="${1:-repack}"
APP_PLAYER_DIR="${APP_PLAYER_DIR:-$HOME/app-player}"
ANDROID_SDK_PATH="${ANDROID_SDK_PATH:-/home/henry/workspace/android-sdk/sdk}"
FLUTTER_ROOT="${FLUTTER_ROOT:-$HOME/flutter}"
JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-8-openjdk-amd64}"
IMAGE="Tiramisu64"
OEM="nxt"
PKG="bst-v5.22.210_Tiramisu64-local"
OUTPUTDIR="$HOME/releases/$IMAGE"
BUILDSCRIPTS="$APP_PLAYER_DIR/buildscripts"
RELEASE_PKG_DIR="$OUTPUTDIR/$PKG"

# Windows Tiramisu64.bstk 记录的介质 UUID(匹配这些才能 VBox Power up)
UUID_ROOT_VHD="54e9ad31-a169-4d5b-a0e0-705d62e96e71"
UUID_FASTBOOT_VDI="91b80c95-aa7d-459d-93e4-c479f5babbb7"

export JAVA_HOME LC_ALL=C LANG=C
export PATH="$JAVA_HOME/bin:$FLUTTER_ROOT/bin:$PATH"
export ANDROID_SDK_PATH ANDROID_HOME="$ANDROID_SDK_PATH"
export FLUTTER_ROOT
export ANDROIDOUTPUTLOC="$HOME/releases" PKG
# 低并行避免 apks gradle daemon OOM(58GB 撑不住 -j100); android make iso_img 用默认
export PARALLEL_NX_PROCESSORS="${PARALLEL_NX_PROCESSORS:-0.3}"

log() { echo "[$(date +%H:%M:%S)] $*"; }

ensure_nowgg_skip() {
    # nowgg-common 是断链软连 -> /home/build/workspace(clouddev 不可得), henry 也没有
    # build_nowgg_common_apks.sh 改 no-op(nowgg apk 已在 APKFOLDER 残留)
    local f="$BUILDSCRIPTS/build_nowgg_common_apks.sh"
    if [ -f "$f.orig" ]; then return 0; fi
    [ -f "$f" ] && cp -n "$f" "$f.orig" 2>/dev/null || true
    cat > "$f" <<'EOF'
#!/bin/bash
# SKIPPED: nowgg-common unavailable on clouddev (broken symlink -> /home/build/workspace, no github)
echo "[SKIP] build_nowgg_common_apks: nowgg-common unavailable on this host"
exit 0
EOF
    chmod +x "$f"
    log "nowgg skip 已就位(备份 $f.orig)"
}

ensure_launcher_in_apkfolder() {
    # com.bluestacks.filemanager.apk 源码树无, 从 henry scratch-rosen/apks 补
    local src="/home/henry/workspace/app-player/scratch-rosen/apks/com.bluestacks.filemanager.apk"
    local dst="$APP_PLAYER_DIR/scratch-rosen/apks/com.bluestacks.filemanager.apk"
    if [ ! -f "$dst" ] && [ -f "$src" ]; then
        cp "$src" "$dst" && log "filemanager 从 henry 补入 scratch-rosen/apks"
    fi
}

cleanup_stale_rootfs() {
    # henry 式 sudo 全清: root 污染文件(bstk/su 06755 root, rootFS root-owned)用 sudo rm
    log "sudo 清理 releases/Tiramisu64 残留..."
    cd "$OUTPUTDIR"
    sudo umount rootFSDebug 2>/dev/null || true
    sudo umount rootFS 2>/dev/null || true
    sudo umount dataFS 2>/dev/null || true
    sudo rm -rf rootFSDebug rootFS rooted_system rooted_root dataFS system 2>/dev/null || true
    sudo rm -f Root.fs Root.fs.debug Root.fs.rooted 2>/dev/null || true
    sudo rm -rf "$RELEASE_PKG_DIR/Root.rooted.vhd" 2>/dev/null || true
    rm -f Tiramisu64-Module.symvers 2>/dev/null || true
    log "清理完成"
}

run_make() {
    local target="$1"
    rm -f "$HOME/tiramisu_build_exit"
    cd "$BUILDSCRIPTS"
    # full: 完整 make Root.vdi(android iso_img ~4h). repack: -o 跳过 4 phony 依赖, 仅重打包
    nohup bash -c "
        cd '$BUILDSCRIPTS'
        export JAVA_HOME='$JAVA_HOME' LC_ALL=C LANG=C PATH=\$JAVA_HOME/bin:\$PATH
        export FLUTTER_ROOT='$FLUTTER_ROOT' PATH=\$FLUTTER_ROOT/bin:\$PATH
        export ANDROID_SDK_PATH='$ANDROID_SDK_PATH' ANDROID_HOME=\$ANDROID_SDK_PATH
        export PARALLEL_NX_PROCESSORS='$PARALLEL_NX_PROCESSORS'
        export ANDROIDOUTPUTLOC='$HOME/releases' PKG='$PKG'
        make $target -f Makefile Root.vdi OEM=$OEM IMAGE=$IMAGE ANDROID_SDK_PATH=\$ANDROID_SDK_PATH
        echo BUILD_EXIT=\$? > \$HOME/tiramisu_build_exit
    " > "$HOME/tiramisu_build.log" 2>&1 &
    local pid=$!
    log "make 已启动 PID=$pid target='$target', 日志 ~/tiramisu_build.log"
    log "监控: tail -f ~/tiramisu_build.log; 完成 cat ~/tiramisu_build_exit"
}

fix_vdi_clonehd() {
    # Makefile make_vdi_file 的 vboxmanage clonehd 在 sethduuid 后可能 VBOX_E_FILE_ERROR
    # (medium registry 未注册). 若 Root.vdi 存在但 Root.vhd 损坏(file=data/过小), 单独重 clonehd
    if [ ! -f "$RELEASE_PKG_DIR/Root.vdi" ]; then
        log "Root.vdi 不存在, 跳过 clonehd 修复"; return 0
    fi
    if file "$RELEASE_PKG_DIR/Root.vhd" 2>/dev/null | grep -q "VHD\|Disk Image"; then
        log "Root.vhd 已是有效 VHD, 跳过 clonehd"; return 0
    fi
    log "Root.vhd 无效, 重新 clonehd..."
    # 清 VirtualBox medium registry 旧 Root 条目
    sed -i "/Root\./d" "$HOME/.config/VirtualBox/VirtualBox.xml" 2>/dev/null || true
    vboxmanage clonehd "$RELEASE_PKG_DIR/Root.vdi" "$RELEASE_PKG_DIR/Root.vhd" \
        --format VHD --variant Standard 2>&1 | tail -2
}

fix_uuid_match_bstk() {
    # clonehd/sethduuid 生成新 UUID, Windows .bstk 记旧 UUID -> Power up failed
    # 把 clouddev 产物 UUID 改成 .bstk 记录的值
    log "sethduuid 匹配 Windows .bstk UUID..."
    vboxmanage internalcommands sethduuid "$RELEASE_PKG_DIR/Root.vhd" "$UUID_ROOT_VHD" 2>&1 | tail -1
    vboxmanage internalcommands sethduuid "$RELEASE_PKG_DIR/fastboot.vdi" "$UUID_FASTBOOT_VDI" 2>&1 | tail -1
    log "Root.vhd UUID=$UUID_ROOT_VHD, fastboot.vdi UUID=$UUID_FASTBOOT_VDI"
}

stage_fastboot() {
    # fastboot.vdi 预制品(BootImage), 复制到 release pkg
    local src="$APP_PLAYER_DIR/hd/guest/BootImage/fastboot/fastboot.vdi"
    [ -f "$src" ] && cp "$src" "$RELEASE_PKG_DIR/fastboot.vdi" && log "fastboot.vdi 已进 release"
}

verify_products() {
    log "=== 产物验证 ==="
    ls -lh "$RELEASE_PKG_DIR/Root.vhd" "$RELEASE_PKG_DIR/fastboot.vdi" 2>/dev/null
    echo "Root.vhd:"; file "$RELEASE_PKG_DIR/Root.vhd" 2>/dev/null
    echo "Root.vhd UUID:"; vboxmanage internalcommands dumphdinfo "$RELEASE_PKG_DIR/Root.vhd" 2>/dev/null | grep -i uuid | head -1
}

# ---- 主流程 ----
case "$MODE" in
    full)
        ensure_nowgg_skip
        ensure_launcher_in_apkfolder
        cleanup_stale_rootfs
        run_make ""           # 完整 make Root.vdi(含 android iso_img ~4h)
        ;;
    repack)
        ensure_nowgg_skip
        ensure_launcher_in_apkfolder
        cleanup_stale_rootfs
        run_make "-o android -o libs -o apks -o datafs"   # 仅重打包, 复用已编译 system
        ;;
    uuid)
        fix_vdi_clonehd
        fix_uuid_match_bstk
        verify_products
        ;;
    *)
        echo "用法: $0 {full|repack|uuid}"
        echo "  full   - 全量 make Root.vdi (android 源码变了, ~4h)"
        echo "  repack - 仅重打包 (apk/配置变了, ~15min, 需 android 已编过)"
        echo "  uuid   - 仅修 clonehd + UUID 匹配 (build 已出 Root.vdi)"
        exit 1
        ;;
esac

if [ "$MODE" = "full" ] || [ "$MODE" = "repack" ]; then
    log "make 后台运行中。完成后手动跑: $0 uuid"
fi
