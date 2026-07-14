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

## 阶段 9：Android init 首次启动 + 完整问题清单

### Android init 启动成功！`exec /system/bin/init` 执行，first stage init 开始

**启动链已打通**：
kernel-a16 → initrd init.sh → sda1 mount (ext4) → system mount → stage2.sh → exec /system/bin/init ✅
`init: Init encountered errors starting first stage, aborting`

First stage init 错误分析：
- `/apex/com.android.runtime` missing（APEX 未挂载）
- `android_id is empty`（Data.vhdx 未挂载）
- `mount tmpfs on /cache failed: No such file or directory`（缺少 /cache 目录）
- A13 ramdisk `/init` 是 symlink → 未提取到 initrd root

### 完整问题清单（A16 boot bringup，118次尝试中的关键修复）

| # | 问题 | 症状 | 根因 | 解决方案 |
|---|---|---|---|---|
| 1 | showcommands 不支持 | `Invalid argument` | A16 build 移除 showcommands | Makefile baklava 分支去掉 showcommands |
| 2 | iso_img 不存在 | `unknown target iso_img` | A16 trunk_staging 无 ISO | Makefile baklava 改 `make droid` |
| 3 | product 名 generic_x86_64 | ANDROIDOUT 空 | Makefile 硬编码 x86_64 | ln -s generic_x86_64 x86_64 |
| 4 | installer 缺失 | `cp: cannot stat installer` | A16 无 installer | Makefile cp 加 [ -d ] 检查 |
| 5 | Module.symvers 缺失 | `cp: cannot stat Module.symvers` | A16 GKI kernel | Makefile cp 加 [ -f ] 检查 |
| 6 | baklava prop 缺失 | cp bluestacks.prop.us fail | ANDROID_VERSION 文件名 | cp tiramisu → baklava |
| 7 | APKFOLDER 缺 25 apk | copy_system_apks fail | make -o 跳过 datafs | 从 scratch-rosen + gapps 批量补 |
| 8 | GKI kernel ext2 only | EXT2-fs couldn't mount | 用了 upstream GKI 非 kernel-a16 | kernel-a16 build + fastboot.vdi 接入 |
| 9 | bst_hooks.h:293 -Werror | clang strict-prototypes | 函数无 void | `bst_current_uid_is_user_app(void)` |
| 10 | bst_hooks.c:6 angled include | mount.h not found | clang 严格 include | `<mount.h>` → `"mount.h"` |
| 11 | vboxguest CONST_4_15 | VBoxGuest-linux.o Error | kernel 5.15 LINUX_VERSION 报告问题 | `#if 1` 强制 CONST_4_15=const |
| 12 | vboxguest gcc vs clang | gcc 不认 clang flags | kernel-a16 clang build | CC=clang LLVM=1 |
| 13 | vboxguest AssertCompile | clang 严格声明冲突 | hd/guest build 重编译 | 预 build .ko + 跳过 VirtualBox |
| 14 | hd/Source/xpl 缺失 | libs target fail | hd 子模块未 init | git submodule init hd + branch |
| 15 | hd libs KDIR 路径 | path 解析错误 | ANDROIDHOME symlink | make -o libs 跳过 |
| 16 | create_vdi.sh mke2fs lazy init | ext4 IDNF/ACCESS_DENIED | dynamic VHD sparse | `mke2fs -D -O sparse_super` |
| 17 | Blank VDI 缺失 | create_vdi.sh fail | Baklava64 dir 不存在 | cp Tiramisu64/Root_Blank.vdi |
| 18 | PKG 变量缺失 | make_vdi_file `PKG=` 空 | 环境变量未传 | `export PKG=bst-v5.22.210_Baklava64-local` |
| 19 | make_vdi tar 卡死 | I/O 0% CPU, sleep | clouddev I/O 拥塞 | 手动 create_vdi + clonehd |
| 20 | Root.fs.debug minigzip + su | create_rootfs 失败 | minigzip 缺失, su root 权限 | Makefile baklava 跳过 Root.fs.debug |
| 21 | `mkdir: not found` | busybox applets 缺失 | PATH 或 cpio 覆盖 | 用 `/boot/bin/busybox mkdir` 绝对路径 |
| 22 | `date: not found` | stage2.sh line 1 | busybox-ndk 无 date | 替换为 shell function 返回 fixed date |
| 23 | `divide by zero` | BST_MEM_SWAP_ENABLED 未设 | 变量未初始化 | `[ ${BST_MEM_SWAP_ENABLED:-0} -gt 0 ]` |
| 24 | `function` 关键字 | syntax error `(` | busybox ash 不支持 `function` | 删除所有 `function ` 前缀 |
| 25 | `$(uname -m)` 返回空 | IS_64_BUILD=0 | busybox 无 uname | 全替换为 x86_64 + IS_64_BUILD=1 |
| 26 | `die_if_error` fatal exit | exit 1 杀死 init | bstsetup.env 多 exit 1 | source 后重定义 die_if_error 为 non-fatal |
| 27 | system mount point 不存在 | `mount: No such file or directory` | 无 mkdir system | `mkdir -p system` 在 mount 前 |
| 28 | `/init` 是 symlink | `exec /init: not found` | A13 ramdisk init -> /system/bin/init | exec /system/bin/init 直接 |
| 29 | APEX 目录缺失 | `/apex/com.android.runtime: No such` | A16 APEX .apex 文件格式 | henry init.sh 完整 APEX losetup+erofs 处理 |
| 30 | system mount loop vs bind | `mount -o loop` 目录失败 | busybox 对目录 loop mount 行为 | henry 原版 `mount -o loop` 对目录实际做 bind |
| 31 | **first stage init error** | `Init encountered errors` | APEX 缺失, /cache 缺失, android_id | ← **当前** |

### 当前修复文件**
- `init.sh`: henry 完整版 + mkdir -p system + /boot/bin 绝对路径 + APEX losetup 恢复
- `stage2.sh`: henry 完整版 + IS_64_BUILD=1 + die_if_error redefined + exec /system/bin/init
- `bstsetup.env`: henry 完整版 + IS_64_BUILD=1 + $(uname -m)→x86_64 + function 删除 + SWAP 安全检查
- `Makefile`: Baklava 分支 (ANDROID_VERSION/TARGET/ROOTSIZE/CLANG/DATASIZE/android target/droid/installer-symvers容错/Root.fs.debug skip)
- `create_vdi.sh`: mke2fs -D -O sparse_super

## 阶段 8：完整 fastboot.vdi build（参照 A13，含 kernel-a16 + initrd）

### 参照 A13 的完整 fastboot.vdi 流程（buildscripts + hd/guest）
- `BootImage/Makefile build_fastboot: initrd.img $(KERNEL)`：
  - `KERNEL = $(KDIR)/arch/x86/boot/bzImage`
  - `initrd.img` = BlueStacks boot initrd（init.sh + bstmods/*.ko: vboxguest/vboxsf/vmsg/inp/aud/cam/hst + busybox）
  - cp KERNEL + cp initrd → fastboot/ → make（注入 bzImage+initrd → fastboot.vdi）
- hd/guest/Makefile fastboot.vdi → Drivers（.ko）+ BootImage（initrd + fastboot）

### 问题 8.1：vboxguest build 失败（VBoxGuest-linux.c）
- **CONST_4_15**：kernel-a16 5.15 LINUX_VERSION_CODE 报告问题，CONST_4_15 空。参考 henry fix：`#if RTLNX_VER_MIN(4,15,0)` → `#if 1`（强制 const）。
- **gcc vs clang**：vboxguest module build 默认 gcc，不认 kernel-a16 clang flags（-Qunused-arguments 等）。强制 `CC=clang LLVM=1`。
- **AssertCompile clang 严格**：hd/guest build 的 vboxguest 重 build 失败。workaround：单独 `make CC=clang` build vboxguest.ko + vboxsf.ko 成功，复制到 Drivers/VirtualBox/，Drivers/Makefile 跳过 VirtualBox。

### 问题 8.2：其他 .ko（vmsg/inp/aud/cam/hst）
- 同样需 CC=clang（kernel-a16 clang build）。hd/guest build 传 CC=clang LLVM=1。

### ✅ fastboot.vdi 12M 产出（含 kernel-a16 bzImage + initrd with .ko）
- 之前 3M 是只 bootloader（漏 cp KERNEL + cp initrd）。完整 build_fastboot 后 12M。
- sethduuid 91b80c95，scp 替换 Windows。

### 当前 Windows（完整 A16 boot 链）
- `fastboot.vdi` 12M（kernel-a16 + BlueStacks initrd with .ko 模块 + init.sh）
- `Root.vhd` 1.5G（A16 system，上游 AOSP）

### ✅ 启动测试 2：kernel-a16 ext4 panic 已修复，init 启动到 SecondStageMain
- kernel-a16 boot ✅ → initrd init.sh 挂载 Root.vhd（ext4）✅ → 加载 .ko ✅ → APEX mount ✅ → linkerconfig ✅ → stage2.sh ✅ → exec /system/bin/init ✅
- **Android init 启动成功，运行约 44 秒后触发 reboot**（非 crash，是 init 检测到配置问题后的主动重启）

### 启动时间线（经过 8 项修复后）
| 时刻 | 事件 |
|------|------|
| 0-3s | kernel boot + bootloader |
| 3-25s | init.sh: sda1 mount → ramdisk extract → system mount → APEX losetup+erofs → linkerconfig → module load → exec stage2.sh |
| 25-28s | stage2.sh: bstsetup.env → mount_data → network → exec /init |
| 28-47s | Android init 运行（FirstStageMain → SecondStageMain → 检测到配置问题） |
| 47s | init 触发 `reboot(RB_AUTOBOOT)` → VM reset |

### 当前状态：boot 链路已机械调通，剩余工作是 system 层定制移植
- 下一阶段：参考 BS 定制清单 + 12 项目 AOSP patch，移植 init.rc / fstab / SELinux 策略 / HAL 等 system 层配置

## 阶段 10：问题驱动修复 — init 源码修改（7 项）

> 方法论：碰见具体问题 → 诊断根因 → 针对该问题修复 → 验证 → 记录解决方案。不预判、不批量应用 patch。

### 问题 10.1：init mount /proc 时 EBUSY 导致 fatal
- **症状**：上游 init 在 FirstStageMain 中调用 `CHECKCALL(mount("proc", "/proc", "proc", 0, ...))`，/proc 已由 init.sh 挂载 → EBUSY → LOG(FATAL) → init 退出 → kernel panic
- **确认**：在 stage2.sh 中 umount /proc /sys 再 exec init → VM 存活 73 秒（vs 44 秒）
- **修复**：`first_stage_init.cpp`：将 mount /proc 和 /sys 的 flags 从 `0` 改为 `MS_REMOUNT`
- **编译**：`prebuilts/build-tools/linux_musl-x86/bin/ninja -f <out>/combined-*.ninja init`（8 targets，~30s）

### 问题 10.2：restorecon /system/bin/init 在 ro 文件系统上失败
- **症状**：Fix 1 后（无 umount），init 仍在 ~14s reset
- **根因**：`selinux.cpp` 中 `PLOG(FATAL) << "restorecon failed of /system/bin/init"`
- **修复**：`PLOG(FATAL)` → `PLOG(ERROR)`（降级为非致命）

### 问题 10.3-10.7：SELinux enforcing / fstab / 服务域 / socket / insecure file
- **问题**：Fix 1+2 后仍在 ~12.5s reset
- **逐一修复**：
  - `selinux.cpp`: `IsEnforcing()` return `false`（强制 permissive）
  - `first_stage_mount.cpp`: 空 fstab 返回 LOG(WARNING) 非 Error
  - `service.cpp`: `ComputeContextFromExecutable` 在 permissive 时返回 "skip"
  - `util.cpp`: 跳过 insecure file 检查（BS 文件 group/other 可写）
  - `util.cpp`: 禁用 socket SELinux context（`if(!socketcon.empty())` → `if(false)`）
- **验证**：7 项修复全部在编译后的 init 二进制中以字符串确认
- **结果**：init 运行 ~10 秒后仍 reboot（非 crash，是 init 主动重启）

### checkpoint 验证
- 在 stage2.sh 开头添加 `sleep 60` → VM 存活 60+ 秒（证明 initrd 脚本全部正常）
- sleep 后 exec init → init 运行 ~10 秒后 reboot（与无 sleep 时相同）
- **结论**：init 二进制修复已全部到位，reboot 由 system 分区上的配置问题（init.rc / SELinux / HAL）触发

### debugfs 直接修改 VHD system 分区
- VHD 无法在 clouddev 上 mount（host kernel 不支持 metadata_csum ext4 feature）
- 替代方案：使用 `debugfs -w` 直接读写 VHD 中的 ext4 文件系统（无需 mount）
- 操作：`sudo qemu-nbd --connect=/dev/nbd0 Root.vhd` → `sudo debugfs -w /dev/nbd0p1`
  - `rm android/system/bin/init` 删除旧 init
  - `write <local_init> android/system/bin/init` 写入新 init
  - `sif android/system/bin/init mode 755` 设置权限
- 本方法适用于修改 VHD 中任何单个文件，无需完整 repack

### VHD init vs initrd init 对比
- **VHD init** (直接通过 /init symlink): 18s → 加上 umount /proc /sys: **73s**
- **initrd /tmp init** (copy from initrd): 12.5s → 加上 umount: **73s**  
- **结论**：umount /proc /sys 是关键，无论 init 在哪里。VHD 方式更简洁（无需 initrd copy）
- **当前最优配置**：VHD patched init + stage2.sh umount /proc /sys = **73s init runtime**

### 修复文件清单（clouddev: `~/aosp16/system/core/init/`）
| 文件 | 修改内容 |
|------|---------|
| `first_stage_init.cpp` | /proc mount: `0` → `MS_REMOUNT`; /sys mount: `0` → `MS_REMOUNT` |
| `selinux.cpp` | `IsEnforcing()`: `return true` → `return false`; restorecon: `PLOG(FATAL)` → `PLOG(ERROR)` |
| `first_stage_mount.cpp` | 空 fstab: `return Error()` → `LOG(WARNING)` |
| `service.cpp` | ComputeContextFromExecutable: permissive 检查返回 "skip" |
| `util.cpp` | insecure file check: 删除 return Error 块; socket context: 两个 `if(!socketcon.empty())` → `if(false)` |

## 阶段 11：VM 稳定运行 — 0 ACPI Resets 达成！

### 最终配置
| 组件 | 状态 | 说明 |
|------|------|------|
| kernel-a16 | ✅ | `console=tty0 earlyprintk=serial,keep ignore_loglevel` |
| init.sh | ✅ | APEX losetup+erofs, sda1 ro mount, vboxguest disabled |
| stage2.sh | ✅ | umount /proc /sys before exec init |
| init 二进制 | ✅ | 自有 7 项修复编译 |
| VHD system | ✅ | hwservicemanager.rc 添加 + init.rc import；patched init 写入 |
| VM 稳定性 | ✅ | **3+ 分钟 0 ACPI Resets！** |

### 关键发现
- **VBox 拒绝 Root.vhd 写入**（VD#0 VERR_ACCESS_DENIED at offset 1048576）。VHD 实际上是只读的。
  - 写失败不导致 VM 崩溃（内核静默处理 ext4 写失败）
  - 这解释了为什么 `rw` mount 尝试会立即失败
- **`console=tty0` 显著提升稳定性**（之前 73s reset vs 现在 0 resets）
  - tty0 对应 VBox 虚拟显示设备（存在且可用）
  - ttyS0 对应串口（VBox BlueStacks VM 未配置）

### 下一步
1. **检查 BlueStacks 窗口**：`console=tty0 + ignore_loglevel` 应该让 kernel/init 消息显示在虚拟屏幕上
2. **尝试 adb 连接**：检查 init 是否启动了 adbd
3. **继续修复 system 分区**：frameworks/base 补丁可能还需应用

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
