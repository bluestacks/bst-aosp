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

### A16 droid 编译结果
- **BUILD SUCCESSFUL** `#### build completed successfully (05:18:42) ####`, 0 FAILED, 173,457 targets。
- **产品目录名差异**：A16 (trunk_staging) lunch product = `generic_x86_64`，但 Makefile 硬编码 ANDROIDOUT `.../product/x86_64`。修复：`ln -s generic_x86_64 x86_64`（不改 Makefile，A13/A16 兼容）。
- **产物**：system/（apex,app,bin,build.prop,etc...）、root/、ramdisk.img（258bytes gzip, A16 stub ramdisk）。
- **缺失**：installer/（A16 trunk_staging 无 installer，预期）。

### 问题 4.1：A16 droid 产出在 `generic_x86_64`，Makefile 期望 `x86_64`
- **症状**：ANDROIDOUT `.../product/x86_64` 为空，实际产出在 `generic_x86_64`。
- **根因**：A13 lunch `android_x86_64-eng` → product `x86_64`；A16 lunch `aosp_x86_64-trunk_staging-eng` → product `generic_x86_64`。
- **解决**：软连 `generic_x86_64 → x86_64`（免改 Makefile，两端兼容）。

### 问题 4.2：ramdisk.img 仅 258 bytes
- **现象**：ramdisk.img gzip compressed, 258B/1792B uncompressed。
- **判定**：A16 stub ramdisk（极小）。暂接受此值，启动验证时若块设备挂载失败再排查。

## 阶段 4：打包 A16 Root.vhd + fastboot.vdi

- 预置完成：APPCONFFILE（baklava 复用 tiramisu）、APKFOLDER（bst/apks_Baklava64, 20 apk 含 launcher）、4 软连（3bt/gapps/misc/cpuinfo 的 baklava64→tiramisu64）。
- 打包命令：`make -o android -o libs -o apks -o datafs Root.vdi IMAGE=Baklava64 OEM=nxt`。
- 后台运行，监控 cron da4d7302。
- **打包阶段连续问题**：
  - **installer/** 缺失（A16 trunk_staging 不产）→ Makefile `$(call copy,...)` 改为 `[ -d ] && copy || true`
  - **Module.symvers** 缺失（A16 GKI kernel 不产）→ 同上容错
  - **baklava.bluestacks.prop.us** 缺失 → 从 tiramisu 版本复制（cp tiramisu.bluestacks.prop.us → baklava.bluestacks.prop.us）
  - **APKFOLDER 缺 25 apk**（GMS + rosen）→ 从 scratch-rosen/apks + gapps_tiramisu64 批量补入
  - **adbd_rooted_baklava** 缺失 → 从 tiramisu 版本复制
  - **hd 子模块未 init**（缺 Source/xpl）→ `git submodule update --init hd && git checkout bst-v5.22.210`
  - **libs target 失败**（hd/Source/xpl 路径解析 + mmm 模块索引）→ `make -o libs` 跳过（VBox guest modules，初始 boot 不必须）
  - **Root.fs.debug minigzip 缺失 + su root 权限** → Makefile baklava 跳过 Root.fs.debug 整个步骤
  - **Blank VDI 模板缺失**（hd/guest/FileSystem/Baklava64/Root_Blank.vdi）→ 从 Tiramisu64 复制 2MB
  - **Makefile 语法错误**（ifeq/else/endif 前导 tab）→ 修复
  - **PKG 变量未传入** → 补 `PKG=bst-v5.22.210_Baklava64-local`
  - **make_vdi tar 阶段卡死**：clouddev I/O 拥塞（0% CPU, sleep 态）。手动执行 create_vdi.sh + clonehd 完成 VDI→VHD 转换。
- **✅ Root.vhd (1.5G) + fastboot.vdi (11M) 产出！** clonehd 100%，UUID 匹配 .bstk，scp 替换到 Windows Engine\Tiramisu64。A13 版备份为 .bak.A13。

## 阶段 5：完成 — Root.vhd 产出 + Windows 替换

**最终产物**：`C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64\Root.vhd` (1.5G, A16 guest) + `fastboot.vdi` (11M)。

**改动汇总**（Makefile 7 处 + 软连 2 处 + 文件补全 n 处）：
- Makefile: ANDROID_VERSION Baklava 映射 + TARGET trunk_staging + ROOTSIZE 6G + CLANG r563880 + DATASIZE 1.5G + android iso_img→droid + 无 showcommands + installer/symvers 容错 + Root.fs.debug skip
- 软连: generic_x86_64→x86_64, baklava64→tiramisu64 (3bt, gapps, misc, cpuinfo)
- 文件补全: APPCONFFILE, APKFOLDER (42 apk), blank VDI, prop file, adbd, 等

## 阶段 6：启动测试 — 失败诊断（hd 无画面）

### 启动日志实锤（2026-06-26 09:56）
```
Linux version 5.15.119+ (nobody@android-build)  ← AOSP GKI 默认 kernel!
EXT2-fs (sda1): couldn't mount because of unsupported optional features (2c4)
Cannot mount Android root file system
Kernel panic - not syncing: Attempted to kill init! exitcode=0x00000100
```

### 根因：未接入 kernel-a16
- **用了 AOSP trunk_staging 默认 GKI kernel**（5.15.119, Android clang 14），**不是 kernel-a16**。
- GKI kernel **只有 ext2 驱动**，用 ext2 挂 mkfs.ext4 的 Root 分区 → unsupported features → 挂载失败。
- init 无法启动 → exitcode 0x100 → kernel panic at 3.4s。

### 打包缺陷 review
| 严重度 | 问题 |
|---|---|
| 🔴 致命 | 未接入 kernel-a16（GKI kernel ext2 only，无法挂 ext4 Root） |
| 🔴 致命 | system 是上游 AOSP（无 BS 定制 init.rc/services/HAL） |
| 🟡 严重 | libs 跳过（hd guest 模块 xpl/vmsg/hcall/gcall 未构建，host-guest 通信断裂） |
| 🟡 严重 | ramdisk.img 仅 258B stub |
| ⚪ 次要 | Root.fs.debug skip / 3bt 软连（不影响 boot） |

### 修复方向
1. **编译 kernel-a16**（build.config.x86_64 + build.sh → bzImage），含 ext4 + BlueStacks 钩子（bstvmsg 等）。
2. **AOSP prebuilt kernel 接入**（BOARD_KERNEL_CONFIG_FILE/BOARD_KERNEL_VERSION override，见 references build/make patch）。
3. system 需 BS 定制（references 12 项目 patch，后续统筹移植阶段）。
4. libs（hd guest 模块）需构建（hd/Source 路径修复）。

## 阶段 7：kernel-a16 编译 + 接入（修复 panic 根因）

### kernel-a16 编译
- defconfig: `bst-x86_64_defconfig`（BlueStacks 定制），AOSP clang r563880，LLVM=1。
- **问题 7.1**：`fs/bst_hooks.h:293` 函数无 prototype → clang 17 `-Werror,-Wstrict-prototypes`。参考修改：`bst_current_uid_is_user_app()` → `(void)`（sed 自改，非 git apply）。
- **问题 7.2**：`fs/bst_hooks.c:6` `<mount.h>` angled include 本地头 → 改 `"mount.h"`。
- **✅ bzImage 产出**（8.1M，ext4 + BS 钩子）。

### kernel 接入机制（关键认知）
- **boot 从 fastboot.vdi**（IDE port 0，UEFI）。kernel 在 fastboot.vdi，不在 Root.vhd。
- fastboot.vdi = boot loader（fastboot_asm.S + boot_bzImage.c）+ bzImage（kernel）+ initrd（cp_bzImage_initrd.sh 追加）。
- A16 之前用 GKI 5.15.119（ext2 only）→ panic。换成 kernel-a16 bzImage（ext4）。
- build: `cd hd/guest/BootImage/fastboot && make`（自动 build boot loader + 追加 bzImage + VBoxManage convertfromraw → fastboot.vdi）。
- sethduuid fastboot.vdi → 91b80c95（匹配 .bstk）。

### 当前 Windows 状态
- `fastboot.vdi`（3.0M，kernel-a16，UUID 91b80c95 ✅）
- `Root.vhd`（1.5G，A16 system，UUID 54e9ad31 ✅）

### 待验证（启动测试）
- kernel-a16 能否过 ext4 挂载（panic 根因是否解决）
- 若挂载成功但 init 失败 → system 是上游 AOSP（无 BS 定制），需后续 patch 移植
- hd 画面是否出现

### 问题 3.1：A16 不支持 `showcommands` 参数
- **现象**：首次编译 `BUILD_EXIT=2`，日志 `! The argument 'showcommands' is no longer supported` → `Invalid argument` → 失败（1 秒即退出）。
- **根因**：A16 (android-16) 的 build 系统移除了 `showcommands`，A13 的 android target 用 `make iso_img -j30 showcommands` 在 A16 失效。
- **解决**：Makefile android target 加 `ifeq baklava` 分支，用 `make iso_img -j$(numproc)`（无 showcommands）；verbose 日志改由 `out_nxt_Baklava64/verbose.log.gz` 提供。
- 重启编译，进入 make iso_img -j30。

### 问题 3.2：A16 无 `iso_img` target
- **现象**：`FAILED: ninja: unknown target 'iso_img'`。A16 编译到 soong 自举后，make iso_img 报未知 target。
- **根因**：A16 的 `trunk_staging` product 是虚拟设备产品，不构建 ISO。A13 的 `iso_img`（android-x86 风格安装 ISO）在 A16 不存在。
- **BlueStacks 打包实际需要**（copy_android_files_to_outputdir）：`$(ANDROIDOUT)/system`（目录）+ `ramdisk.img` + `root/` + `installer/` + `obj/kernel/Module.symvers`。
- **解决**：baklava android target 改用 `make droid`（AOSP 顶层完整 target，产出 system/ staging + ramdisk.img + boot.img）+ `make ramdisk`，替代 iso_img。
