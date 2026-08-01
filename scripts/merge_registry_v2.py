#!/usr/bin/env python3
"""Merge dual-platform triage JSONL + boot inventory into registry.json v2."""
from __future__ import annotations

import json
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATCHES = ROOT / "patches"
OUT = PATCHES / "registry.json"

PHASE_GROUPS = {
    "G1": {
        "title": "Windows android_x86_64 baseline (qvirt is historical)",
        "phase": "P1",
        "deps": [],
        "layer2_required": True,
        "notes": "当前定制保留在 device/generic/x86_64；qvirt 只作 AOSP16 历史证据",
    },
    "G2": {
        "title": "kernel-a16 (ext4+squashfs+BS hooks)",
        "phase": "P1",
        "deps": ["G1"],
        "layer2_required": True,
    },
    "G3": {
        "title": "guest 图形 goldfish-opengl-pie",
        "phase": "P1",
        "deps": ["G1"],
        "layer2_required": True,
    },
    "G4": {
        "title": "hd guest JNI + host-guest 通道",
        "phase": "P1",
        "deps": ["G1", "G2"],
        "layer2_required": True,
    },
    "G5": {
        "title": "BST frameworks (HostCall/FilterApps/WMS)",
        "phase": "P1",
        "deps": ["G4"],
        "layer2_required": True,
    },
    "G6": {
        "title": "launcher (uncube / Launcher3)",
        "phase": "P1",
        "deps": ["G5"],
        "layer2_required": True,
    },
    "G7": {
        "title": "init / system_core / 关机闭环",
        "phase": "P1",
        "deps": ["G1"],
        "layer2_required": True,
        "notes": "含 temp_debt SELinux/bypass，Phase2 收口",
    },
    "G8": {
        "title": "HAL / VINTF",
        "phase": "P1",
        "deps": ["G1"],
        "layer2_required": True,
    },
    "G9": {
        "title": "build make/soong + art/boringssl/hwservicemanager",
        "phase": "P1",
        "deps": [],
        "layer2_required": False,
    },
    "G10": {
        "title": "buildscripts / BootImage 打包",
        "phase": "P1",
        "deps": ["G1", "G2", "G7"],
        "layer2_required": True,
    },
    "TEMP": {
        "title": "临时债（bringup bypass，Phase2 收口）",
        "phase": "P2",
        "deps": ["G7", "G5"],
        "layer2_required": True,
    },
}

# Boot artifacts from patches/android-16 → registry entries
BOOT_ENTRIES = [
    {
        "id": "boot-device-generic-common",
        "platform": "win",
        "project_path": "device/generic/common",
        "area": "device",
        "unify_group": "device-board",
        "related_group": "G1",
        "phase": "P1",
        "temp_debt": False,
        "confidence": "boot-proven",
        "purpose": "M1 boot 板配置主体：init.x86.rc、ueventd、manifest/VINTF、nativebridge、bst_bins/etc、media codecs",
        "quality": "当前 Windows android_x86_64 的设备定制主体；qvirt 迁移已撤销",
        "impact": "lunch/product、HAL 发现、输入设备、打包；Windows G1 核心",
        "port_status": "boot-archived",
        "host_compat": "ok",
        "verification": "M1 boot Layer2 全绿；见 RESTORE.md §7",
        "checkpoint_ref": "patches/android-16/RESTORE.md",
        "boot_artifact": "patches/android-16/patches/aosp16__device_generic_common.patch + untracked-src/aosp16__device_generic_common/",
    },
    {
        "id": "boot-device-generic-x86_64",
        "platform": "win",
        "project_path": "device/generic/x86_64",
        "area": "device",
        "unify_group": "device-board",
        "related_group": "G1",
        "phase": "P1",
        "temp_debt": False,
        "confidence": "boot-proven",
        "purpose": "x86_64 product 入口（android_x86_64），承接 common overlay",
        "quality": "当前权威 Windows product；产品例外应在此收口",
        "impact": "lunch target 名；与 Makefile ANDROIDOUT 路径耦合",
        "port_status": "boot-archived",
        "host_compat": "ok",
        "verification": "M1 lunch android_x86_64-trunk_staging-eng",
        "checkpoint_ref": "patches/android-16/RESTORE.md",
        "boot_artifact": "patches/android-16/patches/aosp16__device_generic_x86_64.patch",
    },
    {
        "id": "boot-device-generic-goldfish",
        "platform": "both",
        "project_path": "device/generic/goldfish",
        "area": "device",
        "unify_group": "graphics-goldfish",
        "related_group": "G3",
        "phase": "P1",
        "temp_debt": False,
        "confidence": "boot-proven",
        "purpose": "goldfish 设备侧配合 guest 图形",
        "quality": "与 goldfish-opengl-pie 关联",
        "impact": "图形栈；G3",
        "port_status": "boot-archived",
        "host_compat": "ok",
        "verification": "M1 graphics up + bootanim",
        "checkpoint_ref": "patches/android-16/RESTORE.md",
        "boot_artifact": "patches/android-16/patches/aosp16__device_generic_goldfish.patch",
    },
    {
        "id": "boot-goldfish-opengl-pie",
        "platform": "win",
        "project_path": "ggl/goldfish-opengl-pie",
        "area": "hardware",
        "unify_group": "graphics-goldfish",
        "related_group": "G3",
        "phase": "P1",
        "temp_debt": False,
        "confidence": "boot-proven",
        "purpose": "A16 GLES/HWC2 适配；bstpgaipc HostConnection；VsyncThread sp 修复",
        "quality": "真图形定制；mac 应对齐 goldfish-opengl-mac",
        "impact": "host qemu 图形契约；Intel GPU 路径",
        "port_status": "boot-archived",
        "host_compat": "ok",
        "verification": "M1 bootanim + SF；host Player ready",
        "checkpoint_ref": "patches/android-16/RESTORE.md",
        "boot_artifact": "patches/android-16/patches/goldfish-opengl-pie.patch",
    },
    {
        "id": "boot-hd-guest",
        "platform": "win",
        "project_path": "hd/guest",
        "area": "bootimage",
        "unify_group": "hd-guest-channel",
        "related_group": "G4",
        "phase": "P1",
        "temp_debt": False,
        "confidence": "boot-proven",
        "purpose": "BootImage init.sh/stage2、guest 模块、fastboot 注入",
        "quality": "打包链核心；含 bringup 脚本适配",
        "impact": "first/second stage、kernel 模块、关机前同步",
        "port_status": "boot-archived",
        "host_compat": "ok",
        "verification": "M1 first-stage mount sfs + stage2 exec init",
        "checkpoint_ref": "patches/android-16/RESTORE.md",
        "boot_artifact": "patches/android-16/patches/hd-guest.patch + bootimage/",
    },
    {
        "id": "boot-frameworks-base",
        "platform": "both",
        "project_path": "frameworks/base",
        "area": "frameworks",
        "unify_group": "bst-framework",
        "related_group": "G5",
        "phase": "P1",
        "temp_debt": False,
        "confidence": "boot-proven",
        "purpose": "WMS ActivityDisplayed、SystemServer 跳过、锁屏、auth 恢复、Bst* Java/AIDL/JNI",
        "quality": "真 BST + 部分 NPE 防护；与 TEMP r262 分离",
        "impact": "Player ready 门控、Settings、SystemUI 稳定",
        "port_status": "boot-archived",
        "host_compat": "ok",
        "verification": "hcallOnActivityDisplayed + Player ready",
        "checkpoint_ref": "patches/android-16/RESTORE.md",
        "boot_artifact": "patches/android-16/patches/aosp16__frameworks_base.patch + untracked-src/aosp16__frameworks_base/",
    },
    {
        "id": "boot-frameworks-base-r262-temp",
        "platform": "win",
        "project_path": "frameworks/base",
        "area": "frameworks",
        "unify_group": None,
        "related_group": "TEMP",
        "phase": "P2",
        "temp_debt": True,
        "confidence": "boot-proven",
        "purpose": "TEMP：关闭 Shell Transitions，绕过 BLAST/SF commit callback 卡住导致 Settings 不可见",
        "quality": "明确临时债；BLAST 修好后删除并恢复 ENABLE_SHELL_TRANSITIONS",
        "impact": "Settings 可见性；掩盖图形 sync 根因",
        "port_status": "boot-archived",
        "host_compat": "ok",
        "verification": "Transition Root=0；Settings visible",
        "checkpoint_ref": "patches/android-16/patches/aosp16__frameworks_base__r262-temp-disable-shell-transitions.patch",
        "boot_artifact": "patches/android-16/patches/aosp16__frameworks_base__r262-temp-disable-shell-transitions.patch",
    },
    {
        "id": "boot-frameworks-native",
        "platform": "both",
        "project_path": "frameworks/native",
        "area": "frameworks",
        "unify_group": "bst-framework",
        "related_group": "G5",
        "phase": "P1",
        "temp_debt": False,
        "confidence": "boot-proven",
        "purpose": "binder allowlist / BstFilterAppsManager.h stub 等 native 侧支撑",
        "quality": "接缝偏向 libs/binder",
        "impact": "goldfish/binder 编译与运行",
        "port_status": "boot-archived",
        "host_compat": "ok",
        "verification": "M1 Layer1+2",
        "checkpoint_ref": "patches/android-16/RESTORE.md",
        "boot_artifact": "patches/android-16/patches/aosp16__frameworks_native.patch",
    },
    {
        "id": "boot-packages-launcher3",
        "platform": "win",
        "project_path": "packages/apps/Launcher3",
        "area": "packages",
        "unify_group": "launcher",
        "related_group": "G6",
        "phase": "P1",
        "temp_debt": False,
        "confidence": "boot-proven",
        "purpose": "去 HOME 抢占、widget NPE、配合 uncube launcher",
        "quality": "真产品定制",
        "impact": "host ready 依赖 uncube ActivityDisplayed",
        "port_status": "boot-archived",
        "host_compat": "ok",
        "verification": "uncube RESUMED + Player ready",
        "checkpoint_ref": "patches/android-16/RESTORE.md",
        "boot_artifact": "patches/android-16/patches/aosp16__packages_apps_Launcher3.patch",
    },
    {
        "id": "boot-system-core",
        "platform": "both",
        "project_path": "system/core",
        "area": "system",
        "unify_group": "init-shutdown",
        "related_group": "G7",
        "phase": "P1",
        "temp_debt": True,
        "confidence": "boot-proven",
        "purpose": "init 路径/关机闭环/installd early-start；夹带 SELinux permissive 与多项 check bypass",
        "quality": "混合：关机/installd 为真定制；SELinux/property/vdc bypass 为 temp_debt",
        "impact": "boot 稳定性 vs Phase2 sepolicy 收口",
        "port_status": "boot-archived",
        "host_compat": "ok",
        "verification": "优雅关机 + boot_completed",
        "checkpoint_ref": "patches/android-16/RESTORE.md",
        "boot_artifact": "patches/android-16/patches/aosp16__system_core.patch",
        "notes": "拆分：真定制留 G7；bypass 记 TEMP 子项",
    },
    {
        "id": "boot-system-hwservicemanager",
        "platform": "win",
        "project_path": "system/hwservicemanager",
        "area": "system",
        "unify_group": "build-vintf",
        "related_group": "G9",
        "phase": "P1",
        "temp_debt": False,
        "confidence": "boot-proven",
        "purpose": "hwservicemanager 路径/产物适配 A16",
        "quality": "构建接缝",
        "impact": "HIDL 服务发现",
        "port_status": "boot-archived",
        "host_compat": "unknown",
        "verification": "Layer1",
        "checkpoint_ref": "patches/android-16/RESTORE.md",
        "boot_artifact": "patches/android-16/patches/aosp16__system_hwservicemanager.patch",
    },
    {
        "id": "boot-system-security",
        "platform": "win",
        "project_path": "system/security",
        "area": "system",
        "unify_group": "keystore",
        "related_group": "G9",
        "phase": "P1",
        "temp_debt": False,
        "confidence": "boot-proven",
        "purpose": "keystore/security 构建期适配（完整源码路径）",
        "quality": "相对 staging bypass 已改善",
        "impact": "odsign/keystore2 boot level key",
        "port_status": "boot-archived",
        "host_compat": "unknown",
        "verification": "odsign.key.done",
        "checkpoint_ref": "patches/android-16/RESTORE.md",
        "boot_artifact": "patches/android-16/patches/aosp16__system_security.patch",
    },
    {
        "id": "boot-hardware-interfaces",
        "platform": "both",
        "project_path": "hardware/interfaces",
        "area": "hardware",
        "unify_group": "hal-vintf",
        "related_group": "G8",
        "phase": "P1",
        "temp_debt": False,
        "confidence": "boot-proven",
        "purpose": "HAL 接口 / VINTF 相关适配",
        "quality": "与 manifest audio 条目关联",
        "impact": "audioserver / FactoryHal",
        "port_status": "boot-archived",
        "host_compat": "ok",
        "verification": "audioserver 无 SIGSEGV",
        "checkpoint_ref": "patches/android-16/RESTORE.md",
        "boot_artifact": "patches/android-16/patches/aosp16__hardware_interfaces.patch",
    },
    {
        "id": "boot-hardware-libhardware",
        "platform": "both",
        "project_path": "hardware/libhardware",
        "area": "hardware",
        "unify_group": "hal-vintf",
        "related_group": "G8",
        "phase": "P1",
        "temp_debt": False,
        "confidence": "boot-proven",
        "purpose": "libhardware 模块适配（含禁用冲突模块）",
        "quality": "含 .disabled Android.bp",
        "impact": "与 goldfish/hwc 共存",
        "port_status": "boot-archived",
        "host_compat": "ok",
        "verification": "Layer1+hwc",
        "checkpoint_ref": "patches/android-16/RESTORE.md",
        "boot_artifact": "patches/android-16/patches/aosp16__hardware_libhardware.patch",
    },
    {
        "id": "boot-hardware-google-aemu",
        "platform": "win",
        "project_path": "hardware/google/aemu",
        "area": "hardware",
        "unify_group": "graphics-goldfish",
        "related_group": "G3",
        "phase": "P1",
        "temp_debt": False,
        "confidence": "boot-proven",
        "purpose": "aemu 适配 / 与 gfxstream disable 配合",
        "quality": "构建接缝",
        "impact": "图形构建",
        "port_status": "boot-archived",
        "host_compat": "unknown",
        "verification": "Layer1",
        "checkpoint_ref": "patches/android-16/RESTORE.md",
        "boot_artifact": "patches/android-16/patches/aosp16__hardware_google_aemu.patch",
    },
    {
        "id": "boot-build-make",
        "platform": "win",
        "project_path": "build/make",
        "area": "build",
        "unify_group": "build-system",
        "related_group": "G9",
        "phase": "P1",
        "temp_debt": False,
        "confidence": "boot-proven",
        "purpose": "BOARD_KERNEL override、BUILD_EMULATOR=false、ENFORCE_VINTF 调整、hwservicemanager 包路径",
        "quality": "必要构建定制；部分 bringup 可收敛到 BoardConfig",
        "impact": "全树构建门禁",
        "port_status": "boot-archived",
        "host_compat": "unknown",
        "verification": "BUILD_EXIT=0 system.img",
        "checkpoint_ref": "patches/android-16/RESTORE.md",
        "boot_artifact": "patches/android-16/patches/aosp16__build_make.patch",
    },
    {
        "id": "boot-build-soong",
        "platform": "win",
        "project_path": "build/soong",
        "area": "build",
        "unify_group": "build-system",
        "related_group": "G9",
        "phase": "P1",
        "temp_debt": False,
        "confidence": "boot-proven",
        "purpose": "soong 侧 artifact 冲突修复（如 hwservicemanager）",
        "quality": "构建接缝",
        "impact": "bootstrap",
        "port_status": "boot-archived",
        "host_compat": "unknown",
        "verification": "soong bootstrap OK",
        "checkpoint_ref": "patches/android-16/RESTORE.md",
        "boot_artifact": "patches/android-16/patches/aosp16__build_soong.patch",
    },
    {
        "id": "boot-art",
        "platform": "win",
        "project_path": "art",
        "area": "art",
        "unify_group": "art",
        "related_group": "G9",
        "phase": "P1",
        "temp_debt": False,
        "confidence": "boot-proven",
        "purpose": "ART 构建/运行小改（相对完整源码路径后规模小）",
        "quality": "勿再走 staging ABI 绕路",
        "impact": "zygote/boot.art",
        "port_status": "boot-archived",
        "host_compat": "unknown",
        "verification": "odrefresh rc=80",
        "checkpoint_ref": "patches/android-16/RESTORE.md",
        "boot_artifact": "patches/android-16/patches/aosp16__art.patch",
    },
    {
        "id": "boot-external-boringssl",
        "platform": "win",
        "project_path": "external/boringssl",
        "area": "external",
        "unify_group": "boringssl",
        "related_group": "G9",
        "phase": "P1",
        "temp_debt": False,
        "confidence": "boot-proven",
        "purpose": "boringssl self-test rc 等 bringup 适配",
        "quality": "可能可收敛为 init rc noop",
        "impact": "早期 init",
        "port_status": "boot-archived",
        "host_compat": "unknown",
        "verification": "boringssl-rc disabled",
        "checkpoint_ref": "patches/android-16/RESTORE.md",
        "boot_artifact": "patches/android-16/patches/aosp16__external_boringssl.patch",
    },
    {
        "id": "boot-app-player-buildscripts",
        "platform": "win",
        "project_path": "app-player/buildscripts",
        "area": "bootimage",
        "unify_group": "packaging",
        "related_group": "G10",
        "phase": "P1",
        "temp_debt": False,
        "confidence": "boot-proven",
        "purpose": "Makefile Baklava 分支、droid target、system.sfs、UUID/create_vdi 适配",
        "quality": "打包权威；须防 init.rc 覆盖回归",
        "impact": "Root.vhd / fastboot.vdi 产出",
        "port_status": "boot-archived",
        "host_compat": "ok",
        "verification": "Root.vhd 部署启动",
        "checkpoint_ref": "patches/android-16/RESTORE.md",
        "boot_artifact": "patches/android-16/patches/app-player_buildscripts.patch",
    },
    {
        "id": "boot-kernel-a16",
        "platform": "win",
        "project_path": "kernel-a16",
        "area": "kernel",
        "unify_group": "kernel",
        "related_group": "G2",
        "phase": "P1",
        "temp_debt": False,
        "confidence": "boot-proven",
        "purpose": "ext4+squashfs+BS hooks；clang/LLVM=1 bzImage",
        "quality": "真 kernel 定制；对齐清单 kernel/kernel-mac",
        "impact": "挂载 system.sfs、BS 驱动",
        "port_status": "boot-archived",
        "host_compat": "ok",
        "verification": "A16DBG system.sfs mounted",
        "checkpoint_ref": "patches/android-16/kernel/",
        "boot_artifact": "patches/android-16/kernel/config + git.txt",
    },
    # TEMP debts called out explicitly
    {
        "id": "temp-selinux-permissive-bypasses",
        "platform": "win",
        "project_path": "system/core/init",
        "area": "system",
        "unify_group": "sepolicy",
        "related_group": "TEMP",
        "phase": "P2",
        "temp_debt": True,
        "confidence": "boot-proven",
        "purpose": "IsEnforcing=false、CheckMacPerms=true、socket context/insecure-file/coldboot/vdc exec 等 bypass",
        "quality": "明确临时债；须 BST sepolicy + 真实 fstab/vold 后撤销",
        "impact": "安全策略；判断性 → escalate",
        "port_status": "boot-archived",
        "host_compat": "pending",
        "verification": "M1 boot 依赖；Phase2 收口",
        "checkpoint_ref": "progress/android-16-boot-guide.md#阶段-5",
        "boot_artifact": "embedded in aosp16__system_core.patch",
    },
    {
        "id": "temp-keystore-data-wipe",
        "platform": "win",
        "project_path": "ops",
        "area": "other",
        "unify_group": None,
        "related_group": "TEMP",
        "phase": "P2",
        "temp_debt": True,
        "confidence": "boot-proven",
        "purpose": "运维：Data.vhdx 清 keystore/odsign/keychain（非源码 patch）",
        "quality": "运维步骤，记入 RESTORE 流程",
        "impact": "冷启动 odsign；非移植项",
        "port_status": "boot-archived",
        "host_compat": "ok",
        "verification": "r245 wipe 后 odsign.key.done",
        "checkpoint_ref": "scripts/r245-wipe-keystore-data.sh",
        "boot_artifact": "scripts/r245-wipe-keystore-data.sh",
    },
    {
        "id": "list-device-bst-qvirt-mac",
        "platform": "mac",
        "project_path": "device/bst/qvirt",
        "area": "device",
        "unify_group": "device-board",
        "related_group": "G1",
        "phase": "P1",
        "temp_debt": False,
        "confidence": "high",
        "purpose": "历史 mac qvirt/bst_arm64 板源；不再作为 Windows 或 Android-16 主线产品",
        "quality": "AOSP16 一等历史证据；当前产品决策已撤销",
        "impact": "仅用于回溯统一板试验，不得重新引入根树",
        "port_status": "superseded",
        "host_compat": "historical",
        "verification": "AOSP16 G1 historical only",
        "checkpoint_ref": None,
        "boot_artifact": None,
        "notes": "由 Windows android_x86_64 当前产品和未来独立 mac 评估取代",
    },
]

BOOT_ENTRIES.extend(
    [
        {
            "id": "win-hardware-bst-audio",
            "platform": "win",
            "project_path": "hardware/bst/audio",
            "area": "hardware",
            "unify_group": "hal-vintf",
            "related_group": "G8",
            "phase": "P1",
            "temp_debt": False,
            "confidence": "source-and-build-verified",
            "purpose": "Install the legacy BST primary audio HAL and ALSA policy inherited by the Windows product",
            "quality": "AOSP16 source SHA f4c2a5b71cda plus one Android 16 include-path adaptation",
            "impact": "No runtime logic change; legacy HAL buffering and parser debt remain",
            "port_status": "promotion-verified",
            "host_compat": "boot-proven-functional-pending",
            "verification": "audio.primary.bst focused build and Android-16 Windows 7/7 boot passed; playback/capture remains pending",
            "checkpoint_ref": "docs/android-16-patch-review/review-hardware-bst.md",
            "boot_artifact": None,
        },
        {
            "id": "win-hardware-bst-camera",
            "platform": "win",
            "project_path": "hardware/bst/camera",
            "area": "hardware",
            "unify_group": "hal-vintf",
            "related_group": "G8",
            "phase": "P1",
            "temp_debt": False,
            "confidence": "source-and-build-verified",
            "purpose": "Provide camera.bst selected by the common product package list",
            "quality": "AOSP16 source SHA a87e8be3bd35 adapted inline by mainline commits ccb6e51 and 33cdca5",
            "impact": "No frame-path work added; uintptr_t fixes 64-bit queue pointer truncation",
            "port_status": "promotion-verified",
            "host_compat": "boot-proven-functional-pending",
            "verification": "inline camera.bst 32/64 build and Android-16 Windows 7/7 boot passed; preview/capture remains pending",
            "checkpoint_ref": "docs/android-16-patch-review/review-hardware-bst.md",
            "boot_artifact": None,
        },
        {
            "id": "win-hardware-bst-lights",
            "platform": "win",
            "project_path": "hardware/bst/lights",
            "area": "hardware",
            "unify_group": "hal-vintf",
            "related_group": "G8",
            "phase": "P1",
            "temp_debt": False,
            "confidence": "source-and-build-verified",
            "purpose": "Provide lights.bst selected by the Windows product",
            "quality": "AOSP16 source SHA 31b9fb5f5e2e with an include-path adaptation only",
            "impact": "No runtime behavior or steady-state cost added",
            "port_status": "promotion-verified",
            "host_compat": "boot-proven-functional-pending",
            "verification": "lights.bst focused build and Android-16 Windows 7/7 boot passed; brightness exercise remains pending",
            "checkpoint_ref": "docs/android-16-patch-review/review-hardware-bst.md",
            "boot_artifact": None,
        },
        {
            "id": "win-hardware-bst-memtrack",
            "platform": "win",
            "project_path": "hardware/bst/memtrack",
            "area": "hardware",
            "unify_group": "hal-vintf",
            "related_group": "G8",
            "phase": "P1",
            "temp_debt": False,
            "confidence": "source-and-build-verified",
            "purpose": "Provide the product-selected memtrack.bst compatibility module",
            "quality": "AOSP16 source SHA b2aa1fc432d7 with include-path adaptations only",
            "impact": "Negligible runtime cost; the inherited implementation reports no accounting data",
            "port_status": "promotion-verified",
            "host_compat": "boot-proven-functional-pending",
            "verification": "memtrack.bst focused build and Android-16 Windows 7/7 boot passed; accounting fallback exercise remains pending",
            "checkpoint_ref": "docs/android-16-patch-review/review-hardware-bst.md",
            "boot_artifact": None,
        },
        {
            "id": "win-hardware-bst-power",
            "platform": "win",
            "project_path": "hardware/bst/power",
            "area": "hardware",
            "unify_group": "hal-vintf",
            "related_group": "G8",
            "phase": "P1",
            "temp_debt": False,
            "confidence": "source-and-build-verified",
            "purpose": "Retain power.bst beside the Android 16 AIDL hint-session service",
            "quality": "AOSP16 source SHA ff0cda46a0cf with include-path adaptations only",
            "impact": "No hot-path change; inherited sysfs work occurs on interactive transitions",
            "port_status": "promotion-verified",
            "host_compat": "boot-proven-functional-pending",
            "verification": "power.bst/AIDL service builds and Android-16 Windows 7/7 boot passed; suspend/resume remains pending",
            "checkpoint_ref": "docs/android-16-patch-review/review-hardware-bst.md",
            "boot_artifact": None,
        },
        {
            "id": "win-external-alsa-lib",
            "platform": "win",
            "project_path": "external/alsa-lib",
            "area": "external",
            "unify_group": "audio-payload",
            "related_group": "G8",
            "phase": "P1",
            "temp_debt": False,
            "confidence": "source-verified",
            "purpose": "Pin the ALSA configuration source consumed by the AOSP16 audio packaging flow",
            "quality": "AOSP16 source SHA b881b3666a24; obsolete Android.mk is disabled on Android 16",
            "impact": "No Android runtime module is introduced by the compatibility commit",
            "port_status": "promotion-verified",
            "host_compat": "boot-proven-functional-pending",
            "verification": "Root gitlink/[A16] history audited and packaged image booted 7/7; audio behavior remains pending",
            "checkpoint_ref": "docs/development-history/android16-merge/rework-audit.md",
            "boot_artifact": None,
        },
        {
            "id": "win-external-alsa-utils",
            "platform": "win",
            "project_path": "external/alsa-utils",
            "area": "external",
            "unify_group": "audio-payload",
            "related_group": "G8",
            "phase": "P1",
            "temp_debt": False,
            "confidence": "source-verified",
            "purpose": "Pin the alsactl initialization source consumed by the AOSP16 audio packaging flow",
            "quality": "AOSP16 source SHA 2e0c01ee6018; obsolete Android.mk is disabled on Android 16",
            "impact": "No Android runtime module is introduced by the compatibility commit",
            "port_status": "promotion-verified",
            "host_compat": "boot-proven-functional-pending",
            "verification": "Root gitlink/[A16] history audited and packaged image booted 7/7; alsactl behavior remains pending",
            "checkpoint_ref": "docs/development-history/android16-merge/rework-audit.md",
            "boot_artifact": None,
        },
    ]
)


def load_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        rows.append(json.loads(line))
    return rows


def enrich_from_triage(row: dict) -> dict:
    """Fill v2 defaults for triage rows."""
    area = row.get("area") or "other"
    proj = row.get("project_path") or ""
    platform = row.get("platform")

    unify = None
    related = None
    phase = row.get("phase") or "P2"
    purpose = row.get("purpose") or f"fork 偏离上游 android-13（{proj}）"
    quality = row.get("quality") or (
        "高置信 bst 信号" if row.get("has_bst") else "待复查（标签漂移或作者过滤）"
    )

    # Heuristic grouping
    if proj.startswith("device/bst") or proj in (
        "device/generic/common",
        "device/generic/x86_64",
        "device/google/cuttlefish",
    ):
        unify, related, phase = "device-board", "G1", "P1"
    elif "kernel" in proj:
        unify, related, phase = "kernel", "G2", "P1"
    elif proj.startswith("hardware/bst") or proj.startswith("hardware/"):
        unify, related, phase = "hal-vintf", "G8", "P1"
    elif proj.startswith("frameworks/"):
        unify, related, phase = "bst-framework", "G5", "P2"
    elif proj.startswith("packages/"):
        unify, related = "packages", None
        phase = "P2"
    elif proj.startswith("prebuilts/"):
        phase = "P3"
    elif proj.startswith("external/"):
        phase = "P2"
        unify = "external"
    elif proj.startswith("system/"):
        phase = "P2"
        unify = "system"
    elif proj.startswith("build/"):
        unify, related, phase = "build-system", "G9", "P1"

    # If frameworks/base etc already in boot list, leave triage as sibling list item
    out = {
        "id": row["id"],
        "platform": platform,
        "project_path": proj,
        "area": area,
        "unify_group": unify,
        "related_group": related,
        "phase": phase,
        "temp_debt": False,
        "source_commit": row.get("source_commit"),
        "base_tag": row.get("base_tag") or None,
        "since_count": row.get("since_count"),
        "bst_count": row.get("bst_count"),
        "has_bst": row.get("has_bst"),
        "confidence": row.get("confidence") or "low",
        "purpose": purpose,
        "quality": quality,
        "impact": row.get("impact") or "待 Phase 评估",
        "port_status": "pending",
        "host_compat": "unknown",
        "verification": None,
        "checkpoint_ref": None,
        "boot_artifact": None,
        "owner": "agent",
        "notes": row.get("notes"),
    }
    return out


def main() -> None:
    win_rows = load_jsonl(PATCHES / "triage_win.jsonl")
    mac_rows = load_jsonl(PATCHES / "triage_mac.jsonl")

    # Prefer boot entries for same project_path+platform when merging
    boot_keys = {(e["platform"], e["project_path"]) for e in BOOT_ENTRIES}
    patches = list(BOOT_ENTRIES)

    for raw in win_rows + mac_rows:
        key = (raw.get("platform"), raw.get("project_path"))
        # Always keep triage items; boot-archived is separate evidence line
        # Skip exact duplicates of list-device-bst-qvirt-mac if triage also emits
        if any(p["id"] == raw["id"] for p in patches):
            continue
        if raw.get("project_path") == "device/bst/qvirt" and raw.get("platform") == "mac":
            # already have list-device-bst-qvirt-mac
            if any(p["id"] == "list-device-bst-qvirt-mac" for p in patches):
                # merge stats into existing
                for p in patches:
                    if p["id"] == "list-device-bst-qvirt-mac":
                        p["base_tag"] = raw.get("base_tag") or p.get("base_tag")
                        p["since_count"] = raw.get("since_count")
                        p["bst_count"] = raw.get("bst_count")
                        p["has_bst"] = raw.get("has_bst")
                        p["confidence"] = raw.get("confidence") or p["confidence"]
                continue
        patches.append(enrich_from_triage(raw))

    # Unify: mark win+mac same project_path as both when both present with bst
    by_proj: dict[str, list[dict]] = {}
    for p in patches:
        if p.get("port_status") == "boot-archived":
            continue
        by_proj.setdefault(p["project_path"], []).append(p)
    for proj, items in by_proj.items():
        plats = {i["platform"] for i in items}
        if plats >= {"win", "mac"}:
            ug = items[0].get("unify_group") or proj.replace("/", "-")
            for i in items:
                i["unify_group"] = ug
                # keep platform as win/mac for source tracking; note dual
                i["notes"] = (i.get("notes") or "") + " | dual-platform candidate"

    doc = {
        "schema_version": 2,
        "base_from": "android-13",
        "base_to": "android-16.0.0_r4",
        "generated_at": str(date.today()),
        "win_tree": "~/app-player/android-13 (bst-v5.22.210)",
        "mac_tree": "~/app-player-mac/android-mac (bst-v5.21.700-nxt_mac2)",
        "platform_priority": "win 先行验证, mac 同码复用",
        "method_note": (
            "v2: 远程 triage_dual.sh（android-13.0.0_r* tag..HEAD + bluestacks 作者"
            " + 关键字/路径信号）+ M1 boot 存量映射。v1 错位树 triage 已备份为"
            " registry.v1.backup.json。"
        ),
        "_a16_boot_reference": "progress/android-16-boot-guide.md",
        "_a16_restore": "patches/android-16/RESTORE.md",
        "_schema": "patches/registry.schema.md",
        "phase_groups": PHASE_GROUPS,
        "patches": patches,
    }

    OUT.write_text(
        json.dumps(doc, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    print(f"Wrote {OUT} patches={len(patches)} triage_win={len(win_rows)} triage_mac={len(mac_rows)}")


if __name__ == "__main__":
    main()
