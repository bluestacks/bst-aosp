# android-16 (Baklava) win 构建日志

> 目标：参考 A13 流程编译 A16 Root.vhd + fastboot.vdi；UI 用 A13 壳（launcher）跑 A16 guest。
> references/android-16-boot-patches/ 仅作参考，不直接 apply。
> 逐项记录每步、每个问题、解决办法。

## 阶段 1：研究 A16 构建流程 vs A13（task #22）

### A16 vs A13 构建配置差异（from henry 00-buildscripts.patch 参考）

| 项 | A13 (Tiramisu64) | A16 (Baklava64) |
|---|---|---|
| ANDROID_VERSION | tiramisu | **baklava** |
| ANDROIDHOME | android-13 | **android-16** |
| lunch target | android_x86_64-eng | **android_x86_64-trunk_staging-eng** |
| ROOTSIZE | 2621440 (2.5G) | **6291456 (6G)** |
| CLANG | clang-r450784d | **clang-r563880** |
| GOLDFISH_OPENGL | goldfish-opengl-pie | goldfish-opengl-pie（同） |

### 问题 1.1：Makefile 无 Baklava 映射
- **现象**：Makefile 的 IMAGE→ANDROID_VERSION 映射只到 Tiramisu(android-13)，无 Baklava。
- **参考**：henry patch 加了 `else ifneq (,$(findstring Baklava,$(IMAGE)))` 分支（baklava/android-16/trunk_staging/6G/clang-r563880）。
- **解法**：需在 Makefile 加 Baklava 分支（自己改，参考 henry 不直接 apply）。

### 问题 1.2：markxu aosp16 无 device/bst/qvirt
- **现象**：`~/aosp16/device/` 只有 amlogic/common/generic/google/google_car/linaro/sample，**无 device/bst**。
- **对比**：henry 的 android-16 也无 device/bst —— BS A16 构建实际用 **device/generic**（henry patch 改 device/generic/{common,x86_64}），非 device/bst。
- **认知更新**：CLAUDE.md 假设的 "device/bst/qvirt" 对 A16 不成立；A16 走 device/generic 路径。

### 问题 1.3（调研中）：trunk_staging product 是否可用
- henry lunch target = `android_x86_64-trunk_staging-eng`。
- markxu aosp16（android-16.0.0_r4 release）build/target/product/ 只有 aosp_* 系列，可能无 trunk_staging。
- 待确认：若缺 trunk_staging，需换 product 或 manifest。

### 结论 1.4：trunk_staging 可用 + base 一致
- markxu 与 henry 都基于 `android-16.0.0_r4`（manifest revision 一致）✅
- AndroidProducts.mk 含 `aosp_x86_64-trunk_staging-eng`（上游名；henry 的 `android_x86_64-` 是 BS 改名 product）。
- markxu 用上游名 `aosp_x86_64-trunk_staging-eng`。
- clang-r563880 ✅、kernel-a16 有 build.config.x86_64 ✅。

## 阶段 2：Makefile 加 Baklava 分支（task #23 准备）

参考 henry 00-buildscripts.patch（不直接 apply，自己改），改 markxu `~/app-player/buildscripts/Makefile`（已备份 `Makefile.bak_before_a16.*`）。4 处核心改动：

1. **ANDROID_VERSION 映射**（line ~17）：加 `else ifneq Baklava → ANDROID_VERSION=baklava, ANDROIDHOME=android-16, GOLDFISH_OPENGL=goldfish-opengl-pie`
2. **TARGET + ROOTSIZE**（line ~38）：`else ifeq baklava → TARGET=aosp_x86_64-trunk_staging-eng`（上游名，非 henry 的 android_x86_64-）；`ROOTSIZE=6291456`（6G）
3. **CLANG**（line ~69）：`else ifeq baklava → clang-r563880`
4. **DATASIZE**（line ~96）：`ifeq baklava → 1572864`

**dry-run 验证通过**：`make -n android IMAGE=Baklava64` → lunch `aosp_x86_64-trunk_staging-eng`、ANDROIDHOME=`android-16`、OUT_DIR=`out_nxt_Baklava64`、make iso_img。

### 未改（暂跳过，遇到问题再加）
- android target 的 `wrap_build_sepolicy_py3`（henry pie 用，baklava 默认分支无 wrap，先试）
- hd/guest kernel 模块构建（KDIR=ANDROIDOUT/obj/kernel，A16 kernel 独立，打包阶段再处理）
- security config / additional_system_props（复用 a13，packaging 阶段加）
