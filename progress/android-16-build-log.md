# android-16 (Baklava) win 构建日志

> 目标：参考 A13 流程编译 A16 Root.vhd + fastboot.vdi；UI 用 A13 壳（launcher）跑 A16 guest。
> **当前路线**：先调通直到 hd 有画面 → 保存修改 → reset 代码树 → 参考 patches + BS 定制统筹规划 patch 移植。
> 逐项记录每步、每个问题、解决办法。

## 阶段 1：A16 构建配置研究（task #22）

### A16 vs A13 构建配置差异

| 项 | A13 (Tiramisu64) | A16 (Baklava64) |
|---|---|---|
| ANDROID_VERSION | tiramisu | **baklava** |
| ANDROIDHOME | android-13 | **android-16**（→ ~/aosp16） |
| lunch target | android_x86_64-eng | **aosp_x86_64-trunk_staging-eng** |
| ROOTSIZE | 2621440 (2.5G) | **6291456 (6G)** |
| CLANG | clang-r450784d | **clang-r563880** |
| GOLDFISH_OPENGL | goldfish-opengl-pie | goldfish-opengl-pie（同） |

### 关键确认
- base = `android-16.0.0_r4`（manifest revision）。
- `aosp_x86_64-trunk_staging-eng` 在 AndroidProducts.mk COMMON_LUNCH_CHOICES ✅。
- `prebuilts/clang/host/linux-x86/clang-r563880` 存在 ✅。
- device/ 用 generic（amlogic/common/generic/google/google_car/linaro/sample），无 device/bst —— A16 走 device/generic 路径。
- kernel-a16 在 `~/aosp16/kernel-a16`（独立，有 build.config.x86_64）。

## 阶段 2：Makefile 加 Baklava 分支（task #23）

改 `~/app-player/buildscripts/Makefile`（已备份 `Makefile.bak_before_a16.*`）。4 处核心改动：

1. **ANDROID_VERSION 映射**：加 `else ifneq Baklava → ANDROID_VERSION=baklava, ANDROIDHOME=android-16, GOLDFISH_OPENGL=goldfish-opengl-pie`
2. **TARGET + ROOTSIZE**：`else ifeq baklava → TARGET=aosp_x86_64-trunk_staging-eng`；`ROOTSIZE=6291456`
3. **CLANG**：`else ifeq baklava → clang-r563880`
4. **DATASIZE**：`ifeq baklava → 1572864`

**dry-run 验证通过**：`make -n android IMAGE=Baklava64` → lunch `aosp_x86_64-trunk_staging-eng`、ANDROIDHOME=`android-16`、OUT_DIR=`out_nxt_Baklava64`、make iso_img。

### 暂跳过（遇到问题再加）
- android target 的 sepolicy python3 wrap（默认分支先试）
- hd/guest kernel 模块构建（KDIR=ANDROIDOUT/obj/kernel，A16 kernel 独立，打包阶段处理）
- security config / additional_system_props（packaging 阶段加）

## 阶段 3：A16 全量编译（task #23，进行中）

- 启动 `make -f Makefile android IMAGE=Baklava64 OEM=nxt`（后台，~/a16_build.log，PID）。
- force-kernel-clean ✅ → envsetup + lunch → make iso_img -j30 + make ramdisk。
- 监控 cron 每 10 分钟。

（编译结果 + 后续问题持续追加 below）
