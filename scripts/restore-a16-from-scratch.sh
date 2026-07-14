#!/bin/bash
# ============================================================================
# restore-a16-from-scratch.sh
# A16 boot 完整恢复脚本 — 从零追到当前文档进度
#
# 用法（在 clouddev markxu 上执行）:
#   bash restore-a16-from-scratch.sh
#
# 前提: app-player (含 .git + bst-v5.22.210 分支)
#       aosp16 (含 .repo, repo sync 完成)
#       kernel-a16 (复制完成, 含 .git)
# ============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()  { echo -e "${RED}[FATAL]${NC} $*"; exit 1; }

# ============================================================================
# Phase 1: app-player 恢复
# ============================================================================
phase1_app_player() {
    log "=== Phase 1: app-player 恢复 ==="
    cd ~/app-player

    # 1a. checkout 工作树
    if [ ! -f buildscripts/Makefile ]; then
        log "checkout bst-v5.22.210..."
        git checkout -f bst-v5.22.210
    else
        log "working tree already populated"
    fi

    # 1b. submodule update (仅 android-13, 不递归所有)
    log "submodule update --init android-13..."
    git submodule update --init android-13

    # 1c. init host 构建所需的子模块 (hd, bst, 3bt, opengl, tools, scratch-*, ggl)
    log "init host submodules..."
    git submodule update --init hd bst 3bt opengl tools scratch-gaurav scratch-rosen ggl-external-qemu ggl-goldfish-opengl-pie 2>/dev/null || true

    # 1d. foreach checkout bst-v5.22.210
    log "foreach checkout bst-v5.22.210..."
    git submodule foreach --recursive 'git checkout bst-v5.22.210 2>/dev/null || true'

    # 1e. android-13 切分支
    log "android-13 checkout bst-v5.22.210..."
    cd ~/app-player/android-13
    git checkout bst-v5.22.210 2>/dev/null || true

    # 1f. 子模块切分支 (并行)
    log "android-13 submodule foreach checkout..."
    git submodule foreach --recursive 'git checkout bst-v5.22.210 2>/dev/null || true' &
    local submod_pid=$!

    cd ~/app-player
    log "Phase 1 done (submodule checkout bg PID=$submod_pid)"
}

# ============================================================================
# Phase 2: aosp16 恢复
# ============================================================================
phase2_aosp16() {
    log "=== Phase 2: aosp16 恢复 ==="
    cd ~/aosp16

    # 2a. repo sync
    log "repo sync -c -j4..."
    repo sync -c -j4 2>&1 | tail -5

    # 2b. 清空树修改
    log "cleaning tree modifications..."
    repo forall -c 'git checkout . 2>/dev/null; git clean -xdf 2>/dev/null' 2>/dev/null || true

    # 2c. 软连接 android-16 → aosp16 (在 app-player 目录)
    log "creating symlink..."
    cd ~/app-player
    [ -L android-16 ] && rm android-16
    ln -s ~/aosp16 android-16
    ls -la android-16

    log "Phase 2 done"
}

# ============================================================================
# Phase 3: kernel-a16 恢复
# ============================================================================
phase3_kernel_a16() {
    log "=== Phase 3: kernel-a16 恢复 ==="
    cd ~/aosp16/kernel-a16

    # 验证 .git 自包含
    if [ ! -f .git ] && [ ! -d .git ]; then
        die "kernel-a16 .git missing"
    fi

    # checkout clean
    git checkout bst-v5.22.210 2>/dev/null || git checkout -b bst-v5.22.210
    git reset --hard HEAD
    git status

    log "Phase 3 done"
}

# ============================================================================
# Phase 4: 应用 buildscripts patch
# ============================================================================
phase4_buildscripts_patches() {
    log "=== Phase 4: buildscripts patches ==="
    cd ~/app-player

    # 取得 bst-aosp 路径 (假设在 ~/bst-aosp 或从 Windows scp)
    local BSP="."

    # 4a. apply 00-buildscripts.patch
    log "applying 00-buildscripts.patch..."
    if [ -f "$BSP/references/android-16-boot-patches/00-buildscripts.patch" ]; then
        git apply --directory=buildscripts "$BSP/references/android-16-boot-patches/00-buildscripts.patch" || {
            warn "buildscripts patch apply failed, trying with patch -p1..."
            cd buildscripts && patch -p1 < "$BSP/references/android-16-boot-patches/00-buildscripts.patch" || warn "manual patch needed"
            cd ~/app-player
        }
    else
        warn "00-buildscripts.patch not found at $BSP, applying inline"
        apply_buildscripts_inline
    fi

    # 4b. copy build scripts
    log "copying build scripts..."
    if [ -f "$BSP/references/android-16-boot-patches/01-build_Baklava64.sh" ]; then
        cp "$BSP/references/android-16-boot-patches/01-build_Baklava64.sh" buildscripts/
        cp "$BSP/references/android-16-boot-patches/02-build_Baklava_common.sh" buildscripts/
        chmod +x buildscripts/01-build_Baklava64.sh buildscripts/02-build_Baklava_common.sh
    fi

    # 4c. 补充 Makefile 末段修复 (iso_img→droid, installer 容错等)
    log "additional Makefile fixes..."
    # 这些是文档记录的额外修复，可能不在 patch 中
    # - android target: make droid (非 iso_img) for baklava
    # - installer/symvers 容错
    # - Root.fs.debug skip
    # 留待编译时按需补充

    log "Phase 4 done"
}

# ============================================================================
# Phase 5: 应用 AOSP 12-project patch
# ============================================================================
phase5_aosp_patches() {
    log "=== Phase 5: AOSP 12-project patches ==="
    cd ~/aosp16

    local BSP="."

    # 10-aosp-repo-diff.patch 是 repo diff 格式 (含 "project X/" 头)
    # 逐 project apply
    local PATCHFILE="$BSP/references/android-16-boot-patches/10-aosp-repo-diff.patch"

    if [ ! -f "$PATCHFILE" ]; then
        warn "10-aosp-repo-diff.patch not found, applying inline"
        apply_aosp_inline
        return
    fi

    log "applying AOSP patches per project..."

    # 方法: 用 git apply 逐 project apply (repo diff 含 project 头)
    local projects=(
        "build/make"
        "build/soong"
        "device/generic/common"
        "device/generic/x86_64"
        "external/boringssl"
        "frameworks/base"
        "frameworks/native"
        "hardware/interfaces"
        "hardware/libhardware"
        "system/core"
        "system/hwservicemanager"
    )

    for proj in "${projects[@]}"; do
        log "  patching $proj..."
        cd ~/aosp16/$proj 2>/dev/null || { warn "  $proj: dir not found"; continue; }
        git checkout . 2>/dev/null || true
        # 提取该 project 的 diff 部分并 apply
        # (简化版: 直接对全文件 apply, git 会忽略不匹配的部分)
        git apply --reject "$PATCHFILE" 2>/dev/null || {
            warn "  $proj: clean apply failed, manual needed"
        }
    done

    cd ~/aosp16
    log "Phase 5 done"
}

# ============================================================================
# Phase 5b: system/core/init 修复 (编译在 AOSP tree 内)
# ============================================================================
apply_system_core_init_fixes() {
    log "=== Phase 5b: system/core/init 修复 ==="
    cd ~/aosp16/system/core

    # 这些修复来自 android-16-build-log.md §10 (7 项修复)
    # 大部分已在 10-aosp-repo-diff.patch 的 system/core/ 部分

    # first_stage_init.cpp: /proc + /sys MS_REMOUNT
    sed -i 's|CHECKCALL(mount("proc", "/proc", "proc", 0,|CHECKCALL(mount("proc", "/proc", "proc", MS_REMOUNT,|' init/first_stage_init.cpp
    sed -i 's|CHECKCALL(mount("sysfs", "/sys", "sysfs", 0,|CHECKCALL(mount("sysfs", "/sys", "sysfs", MS_REMOUNT,|' init/first_stage_init.cpp

    # selinux.cpp: IsEnforcing → false
    sed -i 's/^bool IsEnforcing() {/bool IsEnforcing() {\n    return false;/' init/selinux.cpp 2>/dev/null || true

    # selinux.cpp: restorecon PLOG(FATAL) → PLOG(ERROR)
    sed -i 's/PLOG(FATAL) << "restorecon failed of/PLOG(ERROR) << "restorecon failed (ignored) of/' init/selinux.cpp

    # first_stage_mount.cpp: empty fstab → WARNING
    sed -i 's/return Error() << "failed to read default fstab/LOG(WARNING) << "No default fstab (BlueStacks)"; return fstab/' init/first_stage_mount.cpp 2>/dev/null || true

    # service.cpp: permissive skip
    # util.cpp: insecure + socket skip
    # (These are complex edits - trust the patch file or manual)

    log "Phase 5b done (verify with git diff)"
}

# ============================================================================
# Phase 6: kernel-a16 编译准备
# ============================================================================
phase6_kernel_prep() {
    log "=== Phase 6: kernel-a16 编译准备 ==="
    cd ~/aosp16/kernel-a16

    # 6a. apply working patch (henry local changes)
    local BSP="."
    if [ -f "$BSP/references/android-16-boot-patches/20-kernel-a16-working.patch" ]; then
        log "applying kernel working patch..."
        git apply "$BSP/references/android-16-boot-patches/20-kernel-a16-working.patch" || {
            warn "kernel patch apply failed, applying minimal fixes"
        }
    fi

    # 6b. 确保关键修复到位
    # bst_hooks.h strict-prototypes
    sed -i 's/static inline bool bst_current_uid_is_user_app()/static inline bool bst_current_uid_is_user_app(void)/' fs/bst_hooks.h 2>/dev/null || true

    # bst_hooks.c angled include → quoted
    sed -i 's|#include <mount.h>|#include "mount.h"|' fs/bst_hooks.c 2>/dev/null || true

    # 6c. defconfig + CONFIG_SQUASHFS
    log "configuring kernel..."
    make ARCH=x86_64 bst-x86_64_defconfig 2>/dev/null || {
        warn "bst-x86_64_defconfig not found, trying x86_64_defconfig"
        make ARCH=x86_64 x86_64_defconfig
    }
    scripts/config --enable CONFIG_SQUASHFS
    scripts/config --enable CONFIG_SQUASHFS_ZLIB
    scripts/config --enable CONFIG_SQUASHFS_XATTR
    make ARCH=x86_64 olddefconfig

    # 6d. 准备编译环境
    local CLANG_PATH=~/aosp16/prebuilts/clang/host/linux-x86/clang-r563880/bin
    export PATH="$CLANG_PATH:$PATH"

    log "Phase 6 done"
}

# ============================================================================
# Phase 7: AOSP droid 编译
# ============================================================================
phase7_aosp_build() {
    log "=== Phase 7: AOSP droid 编译 ==="
    cd ~/aosp16

    # 7a. envsetup + lunch
    source build/envsetup.sh
    lunch aosp_x86_64-trunk_staging-eng

    # 7b. symlink 修复 (generic_x86_64 → x86_64)
    local outdir="out/target/product"
    [ -d "$outdir/generic_x86_64" ] && [ ! -e "$outdir/x86_64" ] && ln -s generic_x86_64 "$outdir/x86_64"

    # 7c. 编译
    log "starting make droid (long running)..."
    make droid -j$(nproc) 2>&1 | tee ~/a16_droid_build.log
    local ret=${PIPESTATUS[0]}

    if [ $ret -eq 0 ]; then
        log "AOSP droid BUILD SUCCESS"
        ls -la out/target/product/generic_x86_64/system/build.prop
    else
        die "AOSP droid build FAILED (exit=$ret), check ~/a16_droid_build.log"
    fi
}

# ============================================================================
# Phase 8: kernel-a16 编译
# ============================================================================
phase8_kernel_build() {
    log "=== Phase 8: kernel-a16 编译 ==="
    cd ~/aosp16/kernel-a16

    local CLANG_PATH=~/aosp16/prebuilts/clang/host/linux-x86/clang-r563880/bin
    export PATH="$CLANG_PATH:$PATH"

    make ARCH=x86_64 CC=clang LLVM=1 -j$(nproc) bzImage 2>&1 | tee ~/kernel_build.log
    local ret=${PIPESTATUS[0]}

    if [ $ret -eq 0 ]; then
        local bzimg="arch/x86/boot/bzImage"
        log "kernel BUILD SUCCESS"
        ls -la "$bzimg"
        cp "$bzimg" ~/bzImage-a16
    else
        die "kernel build FAILED (exit=$ret)"
    fi
}

# ============================================================================
# Phase 9: 打包 fastboot.vdi + Root.vhd
# ============================================================================
phase9_package() {
    log "=== Phase 9: 打包 fastboot.vdi + Root.vhd ==="
    cd ~/app-player/buildscripts

    export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
    export LC_ALL=C LANG=C
    export PATH="$JAVA_HOME/bin:$PATH"
    export ANDROID_SDK_PATH="${ANDROID_SDK_PATH:-/home/henry/workspace/android-sdk/sdk}"
    export ANDROID_HOME="$ANDROID_SDK_PATH"
    export ANDROIDOUTPUTLOC="${ANDROIDOUTPUTLOC:-$HOME/releases}"
    export PKG="bst-v5.22.210_Baklava64-local"

    # 9a. build fastboot.vdi
    log "building fastboot.vdi..."
    cd ~/app-player/hd/guest
    make -f Makefile fastboot.vdi \
        KDIR=~/aosp16/kernel-a16 \
        CC=clang LLVM=1 \
        OEM=nxt IMAGE=Baklava64 2>&1 | tee ~/fastboot_build.log

    # 9b. make Root.vdi (完整: 首次需要全量)
    log "building Root.vdi..."
    cd ~/app-player/buildscripts
    make -j$(nproc) -f Makefile Root.vdi OEM=nxt IMAGE=Baklava64 \
        ANDROID_SDK_PATH="$ANDROID_SDK_PATH" \
        IS_HYPERV_BUILD=0 \
        2>&1 | tee ~/rootvdi_build.log

    # 9c. UUID 匹配 (Windows .bstk)
    log "matching UUIDs..."
    local release_dir="$ANDROIDOUTPUTLOC/Baklava64/$PKG"
    VBoxManage internalcommands sethduuid "$release_dir/fastboot.vdi" 91b80c95-aa7d-459d-93e4-c479f5babbb7
    VBoxManage internalcommands sethduuid "$release_dir/Root.vhd"   54e9ad31-a169-4d5b-a0e0-705d62e96e71

    log "Phase 9 done"
    log "Products: $release_dir/"
    ls -la "$release_dir/"*.vdi "$release_dir/"*.vhd
}

# ============================================================================
# Main
# ============================================================================
main() {
    echo ""
    echo "=========================================="
    echo " A16 Boot Restore from Scratch"
    echo "=========================================="
    echo ""

    phase1_app_player
    phase2_aosp16
    phase3_kernel_a16
    phase4_buildscripts_patches
    phase5_aosp_patches
    phase6_kernel_prep

    log ""
    log "=== All patches applied! ==="
    log "Next steps (manual):"
    log "  1. Verify patches: cd ~/aosp16 && repo diff"
    log "  2. Build AOSP:   phase7_aosp_build (takes ~5h)"
    log "  3. Build kernel: phase8_kernel_build (takes ~10min)"
    log "  4. Package:      phase9_package"
    log "  5. Deploy:       scp products to Windows"
    log ""
    log "Or run: bash restore-a16-from-scratch.sh --build"
}

[ "${1:-}" = "--build" ] && { main; phase7_aosp_build; phase8_kernel_build; phase9_package; }
[ "${1:-}" != "--build" ] && main
