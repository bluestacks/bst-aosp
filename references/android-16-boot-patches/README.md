# android-16-boot-patches — henry 的 android-16 (Baklava) boot 修改差异

> **叙事版 bringup 文档（优先读）**：`/home/henry/workspace/releases/bst-v5.22.210-9527/Baklava64/bst-v5.22.210_Baklava64-9527/A16-init-bringup-notes.md`  
> （改动分类 A/B、踩坑过程、§9 编译/部署复刻指南；`progress/android-16-boot-debug.md` 调试方法论亦指向此文件。）
>
> 来源：`henry@clouddev:/home/henry/workspace/app-player/android-16`（Baklava = android-16，bst-v5.22.210 分支）
> 抓取方式：`sudo -u henry repo diff`（**必须用 henry 身份**，markxu 因文件权限看不到修改）
> 抓取日期：2026-06-25

## 文件清单

| 文件 | 内容 | 说明 |
|---|---|---|
| `00-buildscripts.patch` | app-player `buildscripts/` working tree diff | Makefile/build.sh/build_nowgg/create_vdi/create_zips 改动（本地构建适配，含 android-16） |
| `01-build_Baklava64.sh` | 新文件（untracked） | henry 的 android-16 构建入口（镜像 Tiramisu64 流程） |
| `02-build_Baklava_common.sh` | 新文件（untracked） | henry 的 android-16 构建封装（env/清理/调 build.sh） |
| `10-aosp-repo-diff.patch` | **android-16 AOSP 树 12 项目 working tree diff（1125 行）** | **核心 boot patches** |
| `20-kernel-a16-working.patch` | kernel-a16 working tree diff | 仅 prebuilts 子模块指针 |
| `21-kernel-a16-status.txt` | kernel-a16 git status | dirty 文件列表 |
| `22-kernel-a16-head.txt` | kernel-a16 HEAD commit | 分支 `bst-v5.22.210` |

## AOSP boot patches 涉及项目（10-aosp-repo-diff.patch）

12 个项目，android-16 能 boot 的关键定制：

- **build/make** — BOARD_KERNEL_CONFIG_FILE/BOARD_KERNEL_VERSION override（BST bzImage 无 IKCFG）；hwservicemanager 从 system_ext 移到 /system
- **build/soong** — 构建系统适配
- **device/generic/common**, **device/generic/x86_64** — 设备配置（qvirt/x86_64）
- **external/boringssl** — 加密库适配
- **frameworks/base**, **frameworks/native** — 框架适配
- **hardware/google/gfxstream**, **hardware/interfaces**, **hardware/libhardware** — HAL/图形
- **system/core** — init/核心
- **system/hwservicemanager** — hwservicemanager（BlueStacks 放 /system 而非 system_ext）

## 应用顺序（在 markxu 的 android-16 树上复现 boot）

```bash
# 1. buildscripts 层（app-player）
cd ~/app-player && git apply references/android-16-boot-patches/00-buildscripts.patch
cp references/android-16-boot-patches/01-build_Baklava64.sh buildscripts/
cp references/android-16-boot-patches/02-build_Baklava_common.sh buildscripts/

# 2. AOSP 树（android-16 = ~/aosp16）—— 按 project 路径 apply
cd ~/aosp16
# 10-aosp-repo-diff.patch 是 repo diff 格式（含 "project X/" 头），需逐项目 apply 或用 repo 脚本

# 3. kernel-a16 已复制到 ~/aosp16/kernel-a16（含 bst-v5.22.210 分支 commit）
```

## 注意

- **henry 身份必需**：`repo diff` 用 markxu 跑输出 0（权限），用 `sudo -u henry` 才看到 1125 行。后续复查同样用 henry 身份。
- kernel-a16 真正的 BlueStacks 定制在分支 commit 里（`bst-v5.22.210`，百万级 commit 历史），working tree 仅 5 个 prebuilts dirty。kernel 通过完整复制（含 .git）而非 patch 传递。
- buildscripts.patch 含 win Tiramisu 也用的通用改动（如 chown UID 修复），非 android-16 专属。

## 补充参考资料（2026-07-08）

henry 的 hd/guest boot 脚本和 buildscripts 已镜像到本仓库：

| 目录 | 来源 | 说明 |
|------|------|------|
| `references/henry-hd-guest/` | `/home/henry/workspace/app-player/hd/guest/` | henry 的 init.sh、stage2.sh、Makefile、BootImage/ |
| `references/henry-buildscripts/` | `/home/henry/workspace/app-player/buildscripts/` | henry 的 build.sh、create_vdi.sh、build_Baklava64.sh 等 |

**关键对比（henry vs bst-aosp）**：
- henry stage2.sh：126 行，`exec /init`（标准 init 流程，无 runtime staging）
- bst-aosp stage2.sh：2500+ 行（runtime staging：art-libs、odsign bypass、zygote wrapper 等）
- henry init.sh：307 行，含 A16 APEX losetup 挂载（`com.android.runtime.apex`、`com.android.i18n.apex`）
- henry 构建方式：完整源码编译（`lunch bst_x86_64` + BS device overlay），所有二进制兼容
