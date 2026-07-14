# Baklava64 (Android 16) 在 Tiramisu64 壳里启动 —— init bringup 改动 & 踩坑记录

> 目标：用 A13(Tiramisu64)的测试壳(Windows / Hyper-V 引擎)启动我们独立编译出来的
> A16(Baklava64)`Root.vhd` + `fastboot.vdi`，让 Android `init` 一路跑起来。
>
> 本文档记录截至目前为"让 A16 init 跑起来"+"让 A16 完整镜像编出来"所做的**全部改动**和**踩坑过程**。
> 文档时间：2026-06-18（最近更新：2026-06-22，补 7k VINTF keymaster 重复声明致 keymint addService abort（A16 libvintf 严格校验，A13 容忍）；7j boringssl system 侧 rc 致 boot 循环（7e 的遗漏补全）；7h libgcall_jni 链接错误 / Soong 环境变量白名单踩坑；7i BstCommandProcessor 适配 A16 API 变化，含本次 `removeTaskWrapper → ActivityTaskManager.removeTask` 修复；7f 补充首次重编 dangling symlink 致 cp 失败；第 1 节说明 `build_Baklava64.sh` 已内置两个 UUID 改写）。

---

## 0. 改动分类总览

改动分两类：

- **【A 临时/测试用，后续必须回退】**：只为在 A13 壳里测试 A16、或为定位问题加的调试代码。
- **【B A16 适配，属于真正需要的 bringup 修复】**：A16 与 A13 行为差异导致的、需要保留的修复
  （后续合入正式流程时保留，但实现方式可再 review）。

| # | 文件 | 类别 | 一句话说明 |
|---|------|------|-----------|
| 1 | `Root.vhd` / `fastboot.vdi` 的 UUID | A 临时 | 改成 Tiramisu64 媒体注册表里的 UUID 才能在 A13 壳里挂载 |
| 2 | `hd/guest/BootImage/init.sh` 调试输出 | A 临时 | loglevel=8、关 kmsg 限速、A16DBG 标记 |
| 3 | `hd/guest/BootImage/init.sh` vbox insmod | A 临时 | 改成"失败不退出 + 打印 rc"做验证 |
| 4 | `hd/guest/BootImage/init.sh` APEX 挂载 | B 适配 | A16 apex 是 .apex(erofs) 文件，需 loop 挂载 |
| 5 | `system/core/init/first_stage_init.cpp` | B 适配 | proc/sys 用 `MS_REMOUNT`(init.sh 已挂载) |
| 6 | `system/core/init/first_stage_mount.cpp` | B 适配 | 找不到 fstab 时返回空 fstab(而非 abort) |
| 7 | `system/core/init/selinux.cpp` | B 适配 | `IsEnforcing()` 强制 permissive；`/system/bin/init` restorecon 非致命(对齐 A13) |
| 8 | `hd/guest/BootImage/stage2.sh` 调试输出 | A 临时 | A16DBG 标记 |
| 9 | `system/core/init/util.cpp` | B 适配 | 关闭 `.rc` 的 group/other 可写"insecure file"检查(对齐 A13) |
| 10 | `system/core/init/service.cpp` | B 适配 | permissive 下跳过 SELinux 域转换检查；失败返回 skip(对齐 A13) |
| 11 | `system/hwservicemanager/Android.bp` + `hwservicemanager.rc` | B 适配 | A16 把 hwservicemanager 挪到 system_ext；Root.vhd 单分区无 system_ext → 改回 /system 安装 |
| 12 | `device/generic/common/packages.mk` | B 适配 | 显式 `PRODUCT_PACKAGES += hwservicemanager` 及 HIDL helper |
| 13 | `build/make/target/product/{generic/Android.bp, base_system.mk}` | B 适配 | 去掉 system_image deps 里 hwservicemanager(与 PRODUCT_PACKAGES 同名冲突) + 注释 compat symlink |
| 14 | `frameworks/base/core/java/com/bluestacks/os/*` + `android/util/BstUtils.java` | B 适配 | 从 A13 拷贝 BlueStacks Manager/AIDL/Utils 源到 A16 |
| 15 | `frameworks/base/core/java/Android.bp` | B 适配 | `framework-connectivity-shared-srcs` 加 `IBstFilterAppsService.aidl`(对齐 A13) |
| 16 | `frameworks/base/core/java/android/content/Context.java` | B 适配 | 加 `BST_UTILS`/`BST_FILTER_APPS`/`BST_HOST_CALL` 服务名常量 |
| 17 | `frameworks/base/core/java/android/app/SystemServiceRegistry.java` | B 适配 | 注册 3 个 BlueStacks Manager |
| 18 | `frameworks/base/services/java/com/android/server/SystemServer.java` | B 适配 | 启动 3 个 BlueStacks 服务 + `mBstUtilsService.setWindowManager(wm)` |
| 19 | `ILegacyPermissionManager.aidl` + `LegacyPermissionManager*` + `DefaultPermissionGrantPolicy` | B 适配 | 加 `assignPermissionsToBstApps`；A16 改用 `UserManagerService.getUserIds()` |
| 20 | `ActivityManagerInternal` + `ActivityManagerService` + `BatteryStatsImpl` | B 适配 | 加 `mapIsolatedUid` / `bstMapUid`(BstFilterAppsService 依赖) |
| 21 | `WindowManagerPolicy` + `PhoneWindowManager` + `DisplayRotation` + `WindowManagerService` | B 适配 | 加 `setBstProposedRotation`(BstUtilsService 依赖) |
| 22 | BlueStacks Manager / BstUtils 源加 `@hide` | B 适配 | A16 metalava `--error UnflaggedApi` 会把没 `@hide` 的类当公共 API 报错 |
| 23 | `hd/Source/gcall/guest/Android.mk` + `GcallDec.cpp` | B 适配 | A16 Soong 环境变量白名单不含 `IMAGE`，需改判 `ANDROID_IMAGES` 并用独立宏 `BUILD_BAKLAVA`（不复用 `BUILD_T`） |
| 24 | `packages/apps/BstCommandProcessor` 多文件 | B 适配 | A13→A16 app 侧 API 适配：`Features` 类删、`setComponentEnabledSetting` 加形参、`InputManager.bstReloadPointerIcon` 删、`removeTaskWrapper` 改走 `ActivityTaskManager.removeTask` |
| 25 | `system/core/rootdir/Android.bp` + hot-fix 删 rc | B 适配 | A16 装了 system 侧 boringssl zygote rc（A13 没装），Baklava64 是 64-only 镜像没有 `boringssl_self_test32` → `exec_start` 失败 → 触发 `reboot,boringssl-self-check-failed`。禁掉两个 `prebuilt_etc` + 从 `init.rc` required 列表里移除 |
| 26 | `device/generic/common/manifest.xml` + hot-fix 覆盖 manifest | B 适配 | A16 libvintf 对 mainifest 与 fragment 重复声明同一 HAL 实例变严（@4.1::IKeymasterDevice/default 在两处都声明）→ 整个 manifest 解析失败 → keymint addService abort。删 main manifest 里的 keymaster 块，保留 fragment 唯一声明 |

> 路径前缀：`/home/henry/workspace/app-player/`，Android 源码在 `android-16/`。

---

## 1. 测试环境 UUID 适配【A 临时】

**现象**：A16 镜像在 A13 壳里启动报
`UUID {xxx} of the medium 'fastboot.vdi/Root.vhd' does not match the value {yyy} stored in the media registry`。

**原因**：测试壳是 A13(Tiramisu64)引擎，`BstkGlobal.xml` 注册表里记的是 A13 镜像的 UUID；
我们 A16 独立编出来的盘 UUID 不同。

**处理**(每次重编盘后都要重做)：
```
# fastboot.vdi
VBoxManage internalcommands sethduuid fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
# Root.vhd
VBoxManage internalcommands sethduuid Root.vhd   54e9ad31-a169-4d5b-a0e0-705d62e96e71
```
两个路径都已内置：
- `hd/guest/build_fastboot_vdi.sh`（开发期手工打 fastboot.vdi 用）：通过 `FASTBOOT_UUID` 变量内置 fastboot UUID 改写。
- `buildscripts/build_Baklava64.sh`（正式整盘构建流程）：构建结束后自动改写 **Root.vhd + fastboot.vdi 两个** UUID（脚本尾部 `TIRAMISU64_ROOT_UUID` / `TIRAMISU64_FASTBOOT_UUID` 两段），无需手工补做。
  > 注意 fastboot.vdi 在 `hd/guest/BootImage/fastboot/cp_bzImage_initrd.sh` 生成时 UUID 是 `7c4e9a21-3b6f-4d8e-a1c2-5f0e8d3b7a94`（A16 自带），与 Tiramisu64 测试壳期望的 `91b80c95-...` 不一致，必须由 `build_Baklava64.sh` 这一步统一改写。

> 回退：正式流程下用各自原生 UUID，不需要这步。

---

## 2. init.sh 调试输出【A 临时】

文件：`hd/guest/BootImage/init.sh`（`stage2.sh` 同理加了 `A16DBG` 标记）。

- `echo 8 > /proc/sys/kernel/printk` —— 把所有 kmsg 打到串口/Player.log。
- `echo on > /proc/sys/kernel/printk_devkmsg` —— **关闭 /dev/kmsg 限速**。
  - 踩坑：不关的话 second-stage init 日志会被
    `printk: init: NNN output lines suppressed due to ratelimiting` 大量吞掉，根本看不到崩溃点。
- 大量 `echo "<0>A16DBG: ..." > /dev/kmsg` 标记，用来定位 boot 走到哪一步死的。

> 回退：删除这些 `A16DBG` 行、`printk`/`printk_devkmsg` 两行。

---

## 3. init.sh vbox insmod 改成非致命验证【A 临时】

文件：`hd/guest/BootImage/init.sh`

之前为绕过问题一度**跳过** `vboxguest.ko` / `vboxsf.ko`。本轮改回加载，但**失败不退出**、只打印 rc：
```sh
log_echo "Loading module /boot/bstmods/vboxguest.ko (non-fatal verify)"
insmod /boot/bstmods/vboxguest.ko
echo "<0>A16DBG: insmod vboxguest.ko rc=$?" > /dev/kmsg
# vboxsf.ko 同理
```
**结论**：`rc=0`，两个模块都能正常加载(`vboxguest: Successfully loaded version 6.1.36`)。
即之前的 insmod 失败是被早期改动/启动环境影响导致的，**内核本身没问题**，VMMDev PCI 也能枚举到。

> 回退：恢复成 git 版本的 `load_module /boot/bstmods/vboxguest.ko` 等（致命语义）。

---

## 4. init.sh —— A16 APEX 挂载【B 适配】★关键

文件：`hd/guest/BootImage/init.sh`（`bstandroid == baklava64` 分支）

**踩坑过程**：
- A13：`/system/apex/com.android.runtime` 是 **flatten 目录**，init.sh 直接 `ln -s` 到 `/apex/` 即可。
- A16：apex 变成 **`.apex` 文件**(zip，payload 是 erofs 镜像，STORED 未压缩，偏移 4096)。
- `/system/bin/{sh,init,linkerconfig}` 都是 64-bit PIE，解释器
  `/system/bin/linker64 -> /apex/com.android.runtime/bin/linker64`。
  若 apex 没挂上 → 解释器是悬空软链 → `exec /init` / 任何 /system 动态二进制直接失败
  → busybox(PID1) 退出 → `Kernel panic: Attempted to kill init exitcode=0x200`。

**修复**：在挂载 system 后、用任何 /system 动态二进制前，把核心 apex **零拷贝 loop 挂载**：
```sh
losetup -o 4096 <free_loop> com.android.runtime.apex   # 偏移 4096 = erofs payload
mount -t erofs -o ro <free_loop> /apex/com.android.runtime
# com.android.i18n 同理
```
- 踩坑：busybox 1.19.4 的 `losetup -f` **第二次调用会段错误**，所以自己写 `find_free_loop()`
  遍历 `/sys/block/loopN/loop` 找空闲设备。
- 其余 apex（尤其 `.capex` 压缩包）留给 Android `apexd` 阶段处理。

**已知遗留**：`/system/bin/linkerconfig` 执行 `rc=127`(not found)，`/linkerconfig/ld.config.txt`
没生成，后续 linker 一直 warn `failed to find generated linker configuration`。目前**不阻塞**启动，
但后面 second-stage 起服务时可能要补（待办）。

> 该改动是 A16 真实需要的，只影响 `baklava64` 分支，不动 A13/其它实例。

---

## 5. first_stage_init.cpp —— proc/sys 用 MS_REMOUNT【B 适配】

文件：`android-16/system/core/init/first_stage_init.cpp`

**现象**：first stage 起来后
`mount("sysfs", "/sys", ...) failed: Device or resource busy (EBUSY)` → fatal abort。

**原因**：BlueStacks 的 `init.sh` 在 `exec /init` 前已经挂了 `/proc`、`/sys`；
A16 stock 的 first stage 又做了一次全新 `mount` → EBUSY。A13 早就打了 `MS_REMOUNT` 补丁。

**修复**(对齐 A13)：
```cpp
CHECKCALL(mount("proc", "/proc", "proc", MS_REMOUNT, "hidepid=2,gid=" ...));
CHECKCALL(mount("sysfs", "/sys", "sysfs", MS_REMOUNT, NULL));
```

---

## 6. first_stage_mount.cpp —— 找不到 fstab 不致命【B 适配】

文件：`android-16/system/core/init/first_stage_mount.cpp`（`ReadFirstStageFstab`）

**现象**：
```
ReadDefaultFstab(): failed to find device default fstab
Failed to create FirstStageMount : failed to read default fstab for first stage mount
init: FirstStageMount not available → InitFatalReboot signal 6
```

**原因链**：
- guest 内核 cmdline 只有 `bstandroid=baklava64`，**没有** `androidboot.hardware` / `androidboot.fstab_suffix`。
- `GetFstabPath()` 必须靠这些后缀才能定位 `/fstab.baklava`，拿不到后缀 → 返回空 → 读 fstab 失败 → A16 直接 abort。
- 而 `fstab.baklava` 里**没有任何 `first_stage_mount` 条目**；BlueStacks 本来就由 init.sh 预挂载一切。
  A13 实际走的就是"fstab 过滤后为空 → 跳过 first stage mount"这条路（只是 A13 能找到 fstab 文件）。

**修复**：`ReadFirstStageFstab` 在 `ReadDefaultFstab` 失败时**返回空 fstab**（而非 `Error()`），
让流程走 `empty fstab -> First stage mount skipped`，与 A13/Tiramisu 一致：
```cpp
} else {
    LOG(WARNING) << "No default fstab found; returning empty fstab "
                    "(BlueStacks pre-mounts rootfs in init.sh)";
}
return fstab;   // 空
```
验证日志：`First stage mount skipped (missing/incompatible/empty fstab in device tree)` ✓

---

## 7. selinux.cpp —— 强制 permissive【B 适配】★关键

文件：`android-16/system/core/init/selinux.cpp`（`IsEnforcing`）

**现象**：
```
audit: enforcing=1 old_enforcing=0
selinux: No path given to file labeling backend
selinux: initialize_backend: Error getting file handle (No such file or directory)
init: execv("/system/bin/init") failed: Permission denied → InitFatalReboot signal 6
```

**原因**：A16 stock 默认 `enforcing`（cmdline 没有 `androidboot.selinux=permissive`）。
BlueStacks 的 rootfs 由 init.sh 预挂载、缺正确的 file_contexts 标签，enforcing 下
init 给自己 `restorecon /system/bin/init` 失败 → re-exec 被拒。

**对比发现**：A13 的 `selinux.cpp` 早把 `IsEnforcing()` patch 成 `return false`（永远 permissive），
并注释掉了 `StatusFromProperty()`。

**修复**(原样照搬 A13)：
```cpp
bool IsEnforcing() {
    return false;          // BlueStacks(baklava bringup): 强制 permissive，对齐 A13
    /* if (ALLOW_PERMISSIVE_SELINUX) { ... } return true; */
}
// StatusFromProperty() 整段注释，避免 -Werror=unused-function
```
验证日志：不再出现 `enforcing=1`，file_contexts 成功加载（plat/system_ext/product/vendor）。

> 注意：这是"对齐 A13 现状"的做法。A13 本身就是 permissive 跑的，所以保留。

### 7b. selinux.cpp —— `/system/bin/init` restorecon 改非致命【B 适配】★关键

文件：`android-16/system/core/init/selinux.cpp`（`SetupSelinux` 末尾）

**现象**(permissive 修好后才暴露出来的下一个崩溃)：
```
selinux: SELinux: Could not set context for /system/bin/init:  Read-only file system
init: restorecon failed of /system/bin/init failed: Read-only file system
init: InitFatalReboot: signal 6
  #04 SetupSelinux(char**)+597
```

**原因**：`SetupSelinux` 末尾会对 `/system/bin/init` 做 `selinux_android_restorecon(..., 0)`，A16/A13
代码都是失败即 `PLOG(FATAL)`。`selinux_android_restorecon` 会先比对当前 xattr 标签与 file_contexts：
- 一致 → 不写，直接成功（**A13 正常构建的 init 标签本就正确 → no-op → 不崩**）。
- 不一致 → 尝试写 xattr。我们 A16 是用 `cp`(经 qemu-nbd)**手工替换**了 `/system/bin/init`，
  新文件 SELinux xattr 丢失/不对 → restorecon 想改写 → `/system` 只读 → `EROFS` → FATAL。

**修复**：把这次 restorecon 降级为**非致命**(打 ERROR 继续)。理由：BlueStacks 的 `/system` 只读、
且已强制 permissive，init 域转换不依赖这次 relabel：
```cpp
if (selinux_android_restorecon("/system/bin/init", 0) == -1) {
    PLOG(ERROR) << "restorecon of /system/bin/init failed (ignored for BlueStacks ro /system)";
}
```

> 这一条**部分是自找的**：根因是我们手工 cp 替换 init 丢了 xattr。
> 正式流程若 init 随整个 system 镜像一起构建(标签正确)，本不会触发；但只读 system 下保留
> 非致命更稳妥。

### 7c. util.cpp —— 关闭 `.rc` "insecure file" 检查【B 适配】★关键

文件：`android-16/system/core/init/util.cpp`（`ReadFile`）

**现象**(进 second stage 后，解析 `.rc` 时几乎每个文件都)：
```
init: Parsing file /system/etc/init/servicemanager.rc...
init: could not import file '...': Unable to read config file '...': Skipping insecure file
```
→ servicemanager / surfaceflinger / vold / zygote ... **所有服务定义都没被加载**，
后续不可能起 Android。

**原因**：`ReadFile()` 出于安全，拒绝 **group 可写 或 other 可写**(`S_IWGRP|S_IWOTH`)的文件。
BlueStacks 打包出来的 rootfs 里大量文件带 group-write 位（构建里就能看到
`-rwxrw-r-- init.baklava.rc`），全部被判 insecure 跳过。

**对比发现**：A13 的 `util.cpp` 早把这段检查**整段注释**，注释原文：
"a lot of files like build.prop, modules.* have group writable and others writable flags set"。

**修复**(照搬 A13)：注释掉 `ReadFile` 里的 `S_IWGRP|S_IWOTH` 判断：
```cpp
/*
if ((sb.st_mode & (S_IWGRP | S_IWOTH)) != 0) {
    return Error() << "Skipping insecure file";
}
*/
```

> 也可改成"重打包时把 /system 权限收成 0644"，但那要每次重建都做；照 A13 关检查更省事且一致。

### 7d. service.cpp —— permissive 下跳过 SELinux 域转换【B 适配】★关键

文件：`android-16/system/core/init/service.cpp`（`ComputeContextFromExecutable`）

**现象**(`.rc` 能正常 import 后，early-init 起服务时)：
```
init: ... started service 'ueventd' has pid 327
init: Command 'exec_start apexd-bootstrap' ... failed:
  File /system/bin/apexd(labeled "u:object_r:unlabeled:s0") has incorrect label or no domain transition ...
init: Got shutdown_command 'reboot,bootloader,bootstrap-apexd-failed'
→ reboot bootloader
```

**原因**：BlueStacks 的 `/system` 只读挂载 + 文件 xattr 未正确 restorecon → 二进制标签是
`unlabeled`。A16 stock 的 `ComputeContextFromExecutable` **即使在 permissive 下**仍做域转换检查，
失败就 Error → `apexd-bootstrap` 起不来 → init 主动 reboot。

**对比发现**：A13 的 `service.cpp` 有两处 BlueStacks patch：
1. `security_getenforce() == 0` 时直接 `return "skip"`（不做域转换）。
2. 域转换失败时 `return "skip"` + WARNING，而非 Error。

**修复**(照搬 A13)：
```cpp
if (!is_selinux_enabled() || security_getenforce() == 0) {
    return "skip";
}
// ...
if (rc == 0 && computed_context == mycon.get()) {
    LOG(WARNING) << "File " << service_path << "...";
    return "skip";   // 不再 return Error()
}
```

### 7e. boringssl self-test —— 对齐 A13 禁用 vendor init_rc【B 适配】★当前卡点

文件：`android-16/external/boringssl/selftest/Android.bp`

**现象**(apexd-bootstrap 通过后，early-init 继续往下时)：
```
processing action (ro.product.cpu.abilist32=* && early-init) from
  (/vendor/etc/boringssl_self_test.zygote64_32.rc:1)
exec_start boringssl_self_test32_vendor failed:
  Cannot find '/vendor/bin/boringssl_self_test32'
Got shutdown_command 'reboot,boringssl-self-check-failed'
→ Entering shutdown mode（on init 根本没跑到，/dev/binder 未 mount）
```

**根因链**：
1. `ro.zygote=zygote64_32` → `boringssl_self_test.rc` import `zygote64_32.rc`
2. `zygote64_32.rc` 在 `abilist32=*` 时 `exec_start boringssl_self_test32_vendor`
3. A16 x86_64-only（`TARGET_2ND_ARCH` 注释）只编出 `boringssl_self_test64`，**无 32 位二进制**
4. `boringssl_self_test.rc` 里 service 带 `reboot_on_failure reboot,boringssl-self-check-failed` → 直接 shutdown

**A13 对比**：
| 项 | A13 (Tiramisu64) | A16 (Baklava64) |
|----|------------------|-----------------|
| `Android.bp` `init_rc` | **注释掉** | 启用 |
| vendor `boringssl_self_test*.rc` | **无**（只有 bin） | 5 个 rc 全装上 |
| vendor bin | `self_test32` + `self_test64` | 仅 `self_test64` |
| `ro.zygote` | — | `zygote64_32` |

**修复**(照搬 A13)：注释 `init_rc` 并去掉 `required` zygote rc，不再把 boringssl init 脚本装进 vendor：
```bp
cc_binary {
    name: "boringssl_self_test_vendor",
    ...
    // init_rc: ["boringssl_self_test.rc"],
}
```

**快速验证（不重编整盘）**：qemu-nbd 挂载 Root.vhd 后删掉（注意路径是 `android/system/vendor`，不是 `android/vendor`）：
- `/android/system/vendor/etc/init/boringssl_self_test.rc`
- `/android/system/vendor/etc/boringssl_self_test.zygote64_32.rc`（及同目录其它 zygote*.rc）

可选：把 `/android/system/etc/init/hw/init.boringssl.zygote64_32.rc` 改成只保留 64 位 `exec_start`，避免进入 `on init` 后再因缺 32 位二进制 reboot。

**正式修复**：改 `Android.bp` 后重编 vendor 分区或整链 `make ... Root.vhd`。

### 7f. hwservicemanager —— A16 挪到 system_ext 导致悬空 symlink【B 适配】★关键

**现象**（init 跑过 boringssl 后，vendor HAL 起来时）：
```
vendor.keymaster-4-1: SIGABRT — Could not register service for Keymaster 4.1
# 根因不在 keymaster，而是 hwservicemanager 缺失：
# /system/bin/hwservicemanager 是 39 字节的悬空 symlink，没有真实二进制
# 也没有 hwservicemanager.rc → 服务根本起不来
```

**原因**：A16 上游把 `hwservicemanager` 从 `/system/bin` 挪到 `/system_ext/bin`，并在 `/system/bin/hwservicemanager` 留一个 compat symlink 兜底。BlueStacks 的 Root.vhd **只有一个分区**（system_ext 不存在），所以：
- `/system/bin/hwservicemanager` 是 39 字节悬空 symlink → 无法 exec
- 没有任何 `hwservicemanager.rc` → init 不会拉起它

keymaster4.1 走 HIDL，必须通过 hwservicemanager 注册，于是 SIGABRT。

**对比 A13**：A13 直接把 `hwservicemanager` 装在 `/system/bin/hwservicemanager`，配 `hwservicemanager.rc`，一切正常。

**修复**（让 A16 装回 `/system`，对齐 A13，4 个文件）：
- `system/hwservicemanager/Android.bp`：
  ```bp
  cc_binary {
      name: "hwservicemanager",
      // 删掉 system_ext_specific: true
      // 安装到 /system/bin/hwservicemanager
  }
  ```
- `system/hwservicemanager/hwservicemanager.rc`：路径改回 `/system/bin/hwservicemanager`。
- `device/generic/common/packages.mk`：`PRODUCT_PACKAGES += hwservicemanager` + `android.hidl.allocator@1.0-service` + `android.hidl.memory@1.0-impl`（HIDL helper）。
- `build/make/target/product/base_system.mk`：注释 `hwservicemanager_compat_symlink_module`（不再走 compat symlink）。

**踩坑（Soong 冲突）**：第一版直接改 `generic/Android.bp` 把真实 `hwservicemanager` 加进 system_image deps，结果报：
```
dependency "hwservicemanager" of "aosp_shared_system_image" missing variant: os:android,arch:common
```
原因：`android_system_image` 期望 arch:common 的虚拟变体，但真实 cc_binary 只有 `arch:x86_64`。`PRODUCT_PACKAGES -= hwservicemanager` 也无效（upstream 在 base_system.mk 里通过 PRODUCT_PACKAGES 强装）。

**最终处理**：从 `generic/Android.bp` 的 `aosp_shared_system_image.deps` 里**移除** `hwservicemanager` / `android.hidl.allocator@1.0-service` / `android.hidl.memory@1.0-impl`，**只保留** `device/generic/common/packages.mk` 的 `PRODUCT_PACKAGES` 路径安装。这样既装上真实二进制又绕开 arch 冲突。

#### 7f 补充：7f 修复后首次重编触发 `cp: not writing through dangling symlink`【环境清理】

**现象**（7f 修好后整盘重编，跑到 `copy_android_files_to_outputdir` 阶段时）：
```
cp -ar .../out_nxt_Baklava64/target/product/x86_64/system .../releases/.../Baklava64/ \
  || (sudo umount -d ...; ...; echo "Error in copying..."; exit 1)
umount: .../Baklava64/: not mounted.
umount: .../Baklava64//../: not mounted.
Error in copying...
make: *** [Makefile:150: Root.vdi] Error 1
```
表面上 `make` 报 `Root.vdi` target 失败，**实际根因**在 cp 上一条命令：
```
$ cp -ar system .../Baklava64/ ; echo $?
cp: not writing through dangling symlink '.../Baklava64/system/bin/hwservicemanager'
1
```

**根因链**：
1. 7f 修复**之前**的某次构建（6/15），`out_.../system/bin/hwservicemanager` 还是 A16 stock 的 compat symlink（→ `/system/system_ext/bin/hwservicemanager`），被 cp 到 release 目录后就是个 dangling symlink。
2. 7f 修复**之后**重编（6/22），`out_.../system/bin/hwservicemanager` 变成了真实二进制（137KB），但 **release 目录里残留的还是旧 dangling symlink**。
3. `cp -ar` 默认 follow symlink：源是普通文件，目标是 dangling symlink → 拒绝写（`not writing through dangling symlink`）→ cp 退出 1。
4. Makefile 的 `copy` 宏（第 420 行）用 `|| (sudo umount ...; exit 1)` 做 fallback，假设 cp 失败是因为 target 被挂载占用；但这里根本没挂载 → umount 报 not mounted → 最终 `exit 1` → make 失败。

> 实际上 release 目录里 `fastboot.vdi` 已经成功拷过来了（md5 与源一致），其它 1.7G 的 system 文件也都拷完了，**只有 hwservicemanager 这一个文件 cp 跳过了**。但 cp 整体退出码非 0 → 整个 make 链失败。

**处理**（一次性环境清理）：
```bash
# 扫描 release system 下所有 dangling symlink（共 19 个，其中 hwservicemanager 是触发 cp 失败的那个）
find .../releases/.../Baklava64/system -xtype l
# 最稳的做法：删掉整个 staging system + root（都是 cp 中间产物，下次构建会重新生成）
# 注意保留 dataFS（独立生成，删除会触发完整重建）和 bst-v5.22.210_Baklava64-9527/（产物目录）
sudo rm -rf .../Baklava64/system .../Baklava64/root
# 删 system/xbin/bstk/su 需要 sudo（root 拥有 + setuid 位，目录 dr-x--x--x 无 w）
```

**为什么不在 Makefile `copy` 宏里加 `-L` 或预 rm**：BlueStacks `copy` 宏是通用的，多处调用，贸然改可能影响其它路径。当前做法（清 staging）已经够用，等正式流程上去之后再 review 是否要给 `copy` 宏加 dangling symlink 兜底。

**经验**：以后凡是**修改了某个文件的安装形态**（symlink ↔ 普通文件），重编前要清掉 release staging 里对应的旧残留，否则 `cp -ar` 会因为 target dangling symlink 整体退出码非 0。具体扫描命令：`find <staging_dir> -xtype l`。

### 7g. BlueStacks framework / 服务编译适配【B 适配】★关键

**现象**（7f 之后整盘重编，跑 `build_Baklava64.sh`）：
```
# 第一批：
frameworks/base/services/java/com/bluestacks/server/BstFilterAppsService.java:18:
  error: package com.bluestacks.os does not exist
  → 缺 IBstFilterAppsService / BstFilterAppsManager / BstHostCallManager / BstUtilsManager
BstUtilsService.java: cannot find symbol: BstUtils, BstUtilsManager, setBstProposedRotation
BstFilterAppsService.java: cannot find symbol:
  mPermMgr.assignPermissionsToBstApps(...)
  service.mapIsolatedUid(uid)

# 第二批（补完上面后）：
BstFilterAppsManager.java:117: cannot find symbol: Context.BST_FILTER_APPS
BstUtilsManager.java:77: cannot find symbol: Context.BST_UTILS
BstUtils.java:460: cannot find symbol: Context.BST_FILTER_APPS

# 第三批（补完 Context 后）：
metalava: BstUtils.java: New API must be flagged with @FlaggedApi [UnflaggedApi]
metalava: BstUtils.java: Missing nullability ... [MissingNullability]
```

**根因**：A13 框架里**预装**了 BlueStacks 一整套 patch（`com/bluestacks/os/*`、`android/util/BstUtils`、`Context` 里的 BST 服务名、`SystemServiceRegistry` 注册、`SystemServer` 启动、`ILegacyPermissionManager.assignPermissionsToBstApps`、AMS `mapIsolatedUid`、WMS `setBstProposedRotation` 等），但 A16 是从干净 AOSP fork 的，**这些 BlueStacks 补丁一条都没有**。`frameworks/base/services/java/com/bluestacks/server/*.java` 这几个 BlueStacks 服务实现**存在**（不知为何 checkout 进来了），但它们依赖的 framework 侧接口都没补 → 编译连环失败。

**修复（逐批对照 A13）**：

#### 第一批：拷贝 BlueStacks framework 源
- `frameworks/base/core/java/com/bluestacks/os/`：从 A13 拷 7 个文件
  - `IBstFilterAppsService.aidl` / `BstFilterAppsManager.java`
  - `IBstHostCallService.aidl` / `BstHostCallManager.java` / `BstHostCallCcCodes.java`
  - `IBstUtilsService.aidl` / `BstUtilsManager.java`
- `frameworks/base/core/java/android/util/BstUtils.java`：从 A13 拷。

#### 第二批：框架接口补丁（对齐 A13）
- **`ILegacyPermissionManager.aidl`**：加 `void assignPermissionsToBstApps(String filepath);`
- **`LegacyPermissionManagerInternal.java`** + **`LegacyPermissionManagerService.java`**：加 Internal 接口 + 实现。
- **`DefaultPermissionGrantPolicy.java`**：加 `assignPermissionsToBstApps()`，并注意 A16 API 差异：
  ```java
  // A13 用 ActivityManager.getUserIds()，A16 这个静态方法没了
  // 改用 UserManagerService.getInstance().getUserIds()（对齐 LegacyPermissionManagerService 既有用法）
  for (int userId : UserManagerService.getInstance().getUserIds()) { ... }
  // pm.getPackageInfo() 也对齐 A13 改成 getSystemPackageInfo()
  ```
- **`ActivityManagerInternal.java`**：加 `public abstract int mapIsolatedUid(int isolatedUid);`
- **`ActivityManagerService.java`**：`LocalService` 实现 `mapIsolatedUid`，转发给 `BatteryStatsImpl.bstMapUid`。
- **`BatteryStatsImpl.java`**：加 `bstMapUid(uid)`（A13 里这个方法也存在，A16 没有），内部转调 `mapIsolatedUid`。
- **`WindowManagerPolicy.java`**：加 `void setBstProposedRotation(int proposedRotation);`
- **`PhoneWindowManager.java`**：实现 `setBstProposedRotation`，调用 `mDefaultDisplayRotation.setBstProposedRotation()`。
- **`DisplayRotation.java`**：新增 public 包装方法 `setBstProposedRotation()`。
  > 踩坑：A16 的 `setUserRotation(mode, rot, caller)` 改成了 **package-private**，A13 是 public；`dispatchProposedRotation` 也是 package-private。PWM 在 `com.android.server.policy`，跨不到 `com.android.server.wm.DisplayRotation` 的 package-private 方法 → 在 DisplayRotation 内包一层 public 方法。
- **`WindowManagerService.java`**：加 `setBstProposedRotation()`，转发给 `mPolicy.setBstProposedRotation()`。

#### 第三批：Context / SystemServiceRegistry / SystemServer
- **`Context.java`**：加 `BST_UTILS`/`BST_FILTER_APPS`/`BST_HOST_CALL` 三个服务名常量（A13 已有，A16 完全缺失）。
- **`SystemServiceRegistry.java`**：在 `registerService(Context.ACTIVITY_SERVICE, ...)` 之前，注册 3 个 BlueStacks Manager 的 `CachedServiceFetcher`。
- **`SystemServer.java`**：
  - import 3 个服务类，加字段 `private BstUtilsService mBstUtilsService;`
  - 在 `mActivityManagerService.initPowerManagement()` 后启动 3 个服务：
    ```java
    ServiceManager.addService(Context.BST_FILTER_APPS, new BstFilterAppsService(mSystemContext));
    mBstUtilsService = new BstUtilsService(mSystemContext);
    ServiceManager.addService(Context.BST_UTILS, mBstUtilsService);
    ServiceManager.addService(Context.BST_HOST_CALL, new BstHostCallService(mSystemContext));
    ```
  - 在 `mActivityManagerService.setWindowManager(wm)` 后加 `mBstUtilsService.setWindowManager(wm);`

#### 第四批：metalava `@hide`
- **现象**：`framework-minus-apex` 的 `api-stubs-docs-non-updatable` metalava 步骤报：
  ```
  BstUtils.java:36: New API must be flagged with @FlaggedApi: class android.util.BstUtils
  BstUtils.java:57: Missing nullability on method `readFile` return
  ...（几十条）
  ```
- **原因**：A16 metalava 默认开 `--error UnflaggedApi` + `--error UnhiddenSystemApi`，把没标 `@hide` 的类当公共 API 检查；BlueStacks 这些类全是 internal 但没加 javadoc `@hide`。A13 在 `frameworks/base/Android.bp` 用 `--api-lint-ignore-prefix com.bluestacks.` / `android.util.` 整体豁免过，但**那是 A13 旧 Soong 的 metalava flag**，A16 新 Soong 不认这个 flag，试过加回去直接报 unknown option。
- **修复**：给所有 BlueStacks 公共类加 javadoc `/** @hide */`，让 metalava 把它们当 hidden 跳过：
  - `BstUtils`、`BstFilterAppsManager`、`BstUtilsManager`、`BstHostCallManager`、`BstHostCallCcCodes`
  > 这是 A13→A16 升级里 metalava 变严 的通病，BlueStacks 原作者在 A13 时代用 ignore-prefix 逃避了，A16 改用 `@hide` 显式标注更干净。

**验证**：`m framework-minus-apex` ✅ `m services.impl` ✅ 均通过。

### 7h. libgcall_jni 链接错误 —— Soong 环境变量白名单不含 `IMAGE`【B 适配】★关键

**现象**（`m services.impl` 通过后，整盘重编跑到 native 阶段时）：
```
error: undefined symbol: gcallCreatorsStudioEffectControlClbk
  referenced by GcallDec.o
  in archive out_nxt_Baklava64/.../libgcall_jni_intermediates/libgcall.a
```

**根因链**：
1. `hd/Source/gcall/guest/GcallDec.cpp` 里有这么一段（第 272 行附近）：
   ```cpp
   #if !defined(BUILD_PIE) && !defined(BUILD_RVC) && !defined(BUILD_T)
       gcallCreatorsStudioEffectControlClbk(...);   // A13+ 不编这个函数
   #endif
   ```
   原作者的语义：**A13(Tiramisu)/RVC/PIE 不调用** `gcallCreatorsStudioEffectControlClbk`，因为这个函数定义在更高版本（或别的模块）里，A13 没有定义 → 不编就不会链接报错。
2. A13 时代靠 `BUILD_T` 宏表达"我是 Tiramisu"。A13 构建链里 `BUILD_T` 由 `Android.mk` 里 `ifeq ($(IMAGE), Tiramisu64)` 定义。
3. 到了 A16(Baklava64)，**没有对应的宏**。这段代码在 Baklava 编译时就直接进入了 → 链接时找不到符号 → 失败。

**第一次尝试（照搬 A13 风格）**：把 `ifeq ($(IMAGE), Tiramisu64)` 的判断加上 Baklava64，复用 `BUILD_T`：
```makefile
ifeq ($(IMAGE), Baklava64)
    LOCAL_CFLAGS += -DBUILD_T   # ❌ 仍然报错
endif
```
失败 —— **整盘构建仍然报 `undefined symbol`**，说明这个 `ifeq` **没命中**。

**深度排查（这条踩坑最重要）**：

BlueStacks 的构建链分两层：
- 外层：`buildscripts/build.sh` → `make -f buildscripts/Makefile vbox IMAGE=Baklava64 ...`
- 内层（跑 AOSP）：外层 Makefile 的 `export_env` 宏 source `envsetup.sh` + `lunch`，再 `make iso_img`，最终走 `soong_ui.bash`。

`IMAGE=Baklava64` 是作为 **make 命令行参数**传给外层 Makefile 的（`build.sh:249`），它在**外层 Makefile 及其子 make** 里是 make 变量；但要传到 `soong_ui.bash` / kati 解析的 `Android.mk`，**必须先 export 成环境变量**。`export_env` 宏里第 892 行确实 `export IMAGE="$(IMAGE)"`，但 —— **soong 的环境是"白名单制"的**：

- `soong_ui` 启动时通过 `config.Environment() = OsEnvironment()` dump 出 `out_nxt_Baklava64/soong/soong.environment.available`，
  实测这个文件里**没有 `IMAGE`**，但有 `OEM`、`HD_SOURCE_TOP`、`APP_PLAYER_DIR`、`ANDROID_IMAGES`、`ALLOW_MISSING_DEPENDENCIES`、`USE_CCACHE` 等变量。
- 规律：凡是 BlueStacks 在 `build_Baklava_common.sh` 早就 `export` 过、或者 AOSP 标准 build 流程会保留的变量，soong 都能稳定捕获；
  而只在 `Makefile` 的 `export_env` 宏里才 `export` 的变量（`IMAGE`、`BST_USE_JEMALLOC`、`IS_MAC_BUILD`、`IS_64_BUILD` 等），soong 的 available 里**一个都没有**。

> `soong.environment.available` 是每次 soong_ui 跑都会无条件重写的（`build/soong/ui/build/soong.go:601`）。
> 它代表"soong_ui 启动那一刻 `os.Environ()` 里有什么"，**不是**"整个构建链里 export 过什么"。
> 只要 soong 在某个增量阶段被以"没 export IMAGE 的环境"启动一次（比如手动 `m <module>`、kati 增量），available 就被覆盖成无 IMAGE 的版本。
> 而 `Android.mk` 在 kati 解析阶段读 `$(IMAGE)` 时，取的就是这个 soong 暴露出来的环境 → **`ifeq ($(IMAGE), Baklava64)` 永远不命中**。

**最终修复**：

1. `hd/Source/gcall/guest/Android.mk`：**两个 `ifeq` 都判**（保险起见，覆盖两条执行路径）：
   ```makefile
   ifeq ($(IMAGE), Baklava64)          # 给 A13 风格的外层 Makefile 直调路径
       LOCAL_CFLAGS += -DBUILD_BAKLAVA
   endif
   ifeq ($(ANDROID_IMAGES), Baklava64) # 给 A16 的 soong→kati 路径（这才是实际命中的）
       LOCAL_CFLAGS += -DBUILD_BAKLAVA
   endif
   ```
   - 用独立宏 `BUILD_BAKLAVA`，**不复用 `BUILD_T`**：`BUILD_T` 字面是 Tiramisu，混用会让"A16 需要、A13 不需要"的差异无处表达（这是上一次会话讨论后定的）。
   - 关于"两个 ifeq 会不会重复定义 `BUILD_BAKLAVA`"：`LOCAL_CFLAGS +=` 是字符串追加，重复 `-D` 对 gcc/clang 合法；而且 A16 实际跑下来两个条件几乎不会同时为真（外层 Makefile 链里 IMAGE 才有值，soong→kati 链里 ANDROID_IMAGES 才有值），第一段是兜底/历史路径，第二段才是实际起作用的。

2. `hd/Source/gcall/guest/GcallDec.cpp`：条件编译加上 `BUILD_BAKLAVA`：
   ```cpp
   #if !defined(BUILD_PIE) && !defined(BUILD_RVC) && !defined(BUILD_T) && !defined(BUILD_BAKLAVA)
       gcallCreatorsStudioEffectControlClbk(...);
   #endif
   ```

**验证**：链接通过，整盘 `build_Baklava64.sh` 跨过 native 阶段继续往下走。

**经验**（这条以后还会遇到）：
- BlueStacks `Android.mk` 里凡是按 `$(IMAGE)` / `$(OEM)` 切版本的，**在 A16 上必须同时判 `$(ANDROID_IMAGES)`**（或其它在 soong available 白名单里的变量），否则 kati 解析时不命中，行为与预期不符。
- 想知道当前构建里某个 make 变量到底取没取到，最直接的方法是看 `out_<oem>_<image>/soong/soong.environment.available`（白名单全集）和 `soong.environment.used.<...>`（实际被 Soong 读过的子集）。两个文件都是 protobuf-json，Python `json.load` 就能解析。

### 7i. BstCommandProcessor app 适配 A16 API 变化【B 适配】★关键

**背景**：`packages/apps/BstCommandProcessor` 是 BlueStacks 的命令处理 app（`sharedUserId="android.uid.system"`，跑在 system uid），它在 A13 时代调用了一些 BlueStacks 自 patch 的 framework API。A16 是干净 AOSP fork，这些 BlueStacks 自加的 API 没移植过来，同时 AOSP 自己也有一些 API 演进，导致编译连环失败。

**处理原则**：跟 7g 的 framework 补丁不同 —— **BstCommandProcessor 是 app，优先改 app，不轻易动框架**。只要 A16 有等价的 AOSP 标准 API（哪怕是搬到别的 class 上的），就让 app 去用新 API；只在完全没有等价物时才考虑移植 BlueStacks patch。

**4 处适配**（均为 `BstCommandLoop.java` / `BstCommandProcessorApplication.java` / `BstCommandProcessorService.java` 单文件改动）：

#### (1) `android.util.Features` 整个类在 A16 被删
- **A13**：`Features.GetArmAppMarker()` 返回 `"containsArmLibs.txt"`，用来在 nativeLibraryDir 里找 ARM 兼容标记文件。
- **A16**：`android.util.Features` 类不存在。
- **修复**（`BstCommandProcessorService.java`）：去掉 import，直接用字面量：
  ```java
  // A16: android.util.Features 整个类被删；marker 文件名固定（见 A13 Features.GetArmAppMarker()）。
  String pathName = aInfo.nativeLibraryDir + "/" + "containsArmLibs.txt";
  ```

#### (2) `IPackageManager.setComponentEnabledSetting` 签名加了 `callingPackage`
- **A13**：`setComponentEnabledSetting(ComponentName, int, int, int)` —— 4 参。
- **A16**：`setComponentEnabledSetting(ComponentName, int, int, int, String callingPackage)` —— 末尾加了个 callingPackage。
- **修复**（`BstCommandProcessorApplication.java`）：补自己的包名：
  ```java
  // A16: IPackageManager.setComponentEnabledSetting 多了 callingPackage 形参。
  mPm.setComponentEnabledSetting(cn, newState, flags, userId, getPackageName());
  ```

#### (3) `InputManager.getInstance().bstReloadPointerIcon()` 没有 A16 等价物
- **A13**：BlueStacks 在 `InputManager` 里 patch 了 `bstReloadPointerIcon()`，用来强制刷新鼠标光标。
- **A16**：`InputManager.getInstance()` 被拆成 `InputManagerGlobal` + `PointerIconCache`，**没有任何公共 reload API**；BlueStacks 的 `bstReloadPointerIcon` patch 也没移植过来。
- **修复**（`BstCommandLoop.java` 的 `showNativeMousePointerClbk`）：去掉这次调用，只设 SystemProperty。原因：实际观察鼠标光标的组件（SurfaceFlinger / InputFlinger 等）本来就是读 `bst.config.show_mouse_ptr` prop，prop 一变它们自己会响应，**多调一次 reload 反而是冗余**。
  ```java
  // A16: InputManager.getInstance()/bstReloadPointerIcon() 都没了（拆成 InputManagerGlobal +
  // PointerIconCache，无公共 reload API）。观察鼠标光标的组件直接读下面的 prop，设上即可。
  SystemProperties.set("bst.config.show_mouse_ptr", show ? "true" : "false");
  ```

#### (4) `ActivityManager.removeTaskWrapper(int, boolean)` —— 走 ActivityTaskManager【本次修复】
- **A13**：BlueStacks 在 `ActivityManager` patch 了 `removeTaskWrapper(int taskId, boolean isBstRequest)`，app 里调 `mActivityManager.removeTaskWrapper(persistenttaskId, true)` 来杀 task。
- **A16 第一版（错误）**：上次会话误以为它合并成了 `ActivityManager.removeTask(int)`，改成 `mActivityManager.removeTask(persistenttaskId)`。**但 A16 `ActivityManager` 根本没有 `removeTask`**（AOSP 从 A10 起把所有 task API 搬到了 `ActivityTaskManager`），整盘构建报：
  ```
  BstCommandLoop.java:2854: error: cannot find symbol
      mActivityManager.removeTask(persistenttaskId);
    symbol: method removeTask(int)
    location: variable mActivityManager of type ActivityManager
  ```
- **最终修复**：改用 AOSP 标准 API `ActivityTaskManager.getInstance().removeTask(int)`（`frameworks/base/core/java/android/app/ActivityTaskManager.java:478`）。A13/A16 都存在，运行时行为等价（A13 `removeTaskWrapper` 内部最终也是走到 ATMS）。
  ```java
  // BstCommandLoop.java 顶部加 import：
  import android.app.ActivityTaskManager;
  // 调用点（第 2854 行附近）：
  ActivityTaskManager.getInstance().removeTask(persistenttaskId);
  ```
  > 权限：`@RequiresPermission(MANAGE_ACTIVITY_TASKS)`，本 app `sharedUserId="android.uid.system"`，自动持有，运行时不会拦。

**验证**：`m BstCommandProcessor` 编译通过。整盘 `build_Baklava64.sh` 跨过此模块继续往下走。

**经验**（与 7g 对比）：
- 框架侧（`frameworks/base/services/...`）缺的 BlueStacks API —— 优先**移植 BlueStacks patch**（因为多个 BlueStacks 服务都要用，且 API 已经成为 BlueStacks 内部约定）。
- app 侧（`packages/apps/BstCommandProcessor`）缺的 BlueStacks API —— 优先**改 app 用 AOSP 标准 API**，不要为单个 app 调用点去 patch 框架（除非完全没等价物，比如 (3) 的 `bstReloadPointerIcon` 是 BlueStacks 独有语义，但实际发现 prop 已经够用，连移植都不需要）。

---

### 7j. boringssl system 侧 rc —— 7e 的遗漏补全【B 适配】★关键

**现象**（7h/7i 修完后整盘重编成功，跑 Player.log 启动）：

`init` 解析完 `.rc` 进入 `on init` 阶段时：
```
[4.658875] init: Command 'exec_start boringssl_self_test32' action=ro.product.cpu.abilist32=* && init
          (/system/etc/init/hw/init.boringssl.zygote64_32.rc:2) took 0ms and failed:
          Could not start exec service: Cannot find '/system/bin/boringssl_self_test32': No such file or directory
[4.663802] init: Got shutdown_command 'reboot,boringssl-self-check-failed' Calling HandlePowerctlMessage()
[4.671064] init: Reboot start, reason: reboot,boringssl-self-check-failed
[4.692470] init: starting service 'vold'...           ← vold 是被这次 reboot 牵连 SIGKILL 的，不是 vold 自己挂
[4.953034] init: Service vold has 'reboot_on_failure' option and failed, shutting down system.
```

注意日志末尾 `Service vold has 'reboot_on_failure' ... and failed` 容易让人误以为是 vold 故障 —— 实际上 vold 是被前一行 `shutdown_command 'reboot,boringssl-self-check-failed'` 触发的整盘 reboot 关停的，**vold 是受害者不是元凶**。真正的根因在 `boringssl_self_test32`。

**根因**：

第 7e 节当时只禁了 vendor 侧的 `boringssl_self_test.rc`（`external/boringssl/selftest/Android.bp` 里的 `boringssl_self_test_vendor.init_rc`），但**漏掉了 system 侧 4 个 zygote rc**：
- `/system/etc/init/hw/init.boringssl.zygote64_32.rc`（主文件）
- `/system/etc/init/hw/init.boringssl.zygote32.rc`（symlink → 64_32）
- `/system/etc/init/hw/init.boringssl.no_zygote.rc`（symlink → 64_32）
- `/system/etc/init/hw/init.boringssl.zygote64.rc`

这 4 个 rc **不是** `external/boringssl/selftest/` 那两个 prebuilt_etc 生成的（那两个内容里是 `boringssl_self_test32_vendor` 后缀，安装到 vendor），而是来自 **`system/core/rootdir/Android.bp`**：

```bp
// system/core/rootdir/Android.bp
prebuilt_etc {
    name: "init.boringssl.zygote64_32.rc",
    src: "init.boringssl.zygote64_32.rc",
    sub_dir: "init/hw",
    symlinks: [
        "init.boringssl.zygote32.rc",
        "init.boringssl.no_zygote.rc",
    ],
}

prebuilt_etc {
    name: "init.boringssl.zygote64.rc",
    src: "init.boringssl.zygote64.rc",
    sub_dir: "init/hw",
}

prebuilt_etc {
    name: "init.rc",
    src: "init.rc",
    sub_dir: "init/hw",
    required: [
        "platform-bootclasspath",
        "init.boringssl.zygote64.rc",       ← ★ 这两行强制把 boringssl rc 拉进 system 分区
        "init.boringssl.zygote64_32.rc",
        "init-perfetto.rc",
    ],
}
```

`init.boringssl.zygote64_32.rc` 内容（system 侧模板，跟 vendor 侧不一样的关键点 —— 用的是不带 `_vendor` 后缀的 service 名）：
```
on init && property:ro.product.cpu.abilist32=*
    exec_start boringssl_self_test32          ← 这个 service 在 system rc 里没有对应 service 定义
on init && property:ro.product.cpu.abilist64=*
    exec_start boringssl_self_test64
on property:apexd.status=ready && property:ro.product.cpu.abilist32=*
    exec_start boringssl_self_test_apex32
on property:apexd.status=ready && property:ro.product.cpu.abilist64=*
    exec_start boringssl_self_test_apex64
```

而 Baklava64 镜像的矛盾配置：
- **构建侧**：`TARGET_2ND_ARCH` 注释 → 只编 64 位二进制，`/system/bin/boringssl_self_test32` 不存在
- **属性侧**：`/system/build.prop` 第 34 行 `ro.product.cpu.abilist32=x86,armeabi-v7a,armeabi`（声称支持 32 位 abi）

boringssl rc 看到 `abilist32=*` 匹配 → `exec_start boringssl_self_test32` → 二进制不存在 → 触发该 service 隐含的 `reboot_on_failure reboot,boringssl-self-check-failed` → 整盘 reboot。

A13(Tiramisu64) 干脆不装 system 侧 boringssl rc（`find Tiramisu64/system -name 'init.boringssl*'` 为空），所以根本不触发。

**修复**（方案 A —— 跟 A13 对齐，禁掉 system 侧 boringssl rc）：

修改 `android-16/system/core/rootdir/Android.bp`：
- 给两个 boringssl `prebuilt_etc` 加 `enabled: false`
- 从 `init.rc` 的 `required:` 列表里删掉两个 boringssl 引用

```bp
// BlueStacks: boringssl self-test rc disabled.（注释说明见原文）
prebuilt_etc {
    name: "init.boringssl.zygote64_32.rc",
    enabled: false,
    src: "init.boringssl.zygote64_32.rc",
    sub_dir: "init/hw",
    symlinks: [ "init.boringssl.zygote32.rc", "init.boringssl.no_zygote.rc" ],
}
prebuilt_etc {
    name: "init.boringssl.zygote64.rc",
    enabled: false,
    src: "init.boringssl.zygote64.rc",
    sub_dir: "init/hw",
}
prebuilt_etc {
    name: "init.rc",
    src: "init.rc",
    sub_dir: "init/hw",
    required: [
        "platform-bootclasspath",
        "init-perfetto.rc",                  ← boringssl 两行已删
    ],
}
```

**未选方案对比**：
- 方案 B（清空 `ro.product.cpu.abilist32`）：副作用大，可能影响 App 兼容性检查（Play Store / PackageParser 等）。
- 方案 C（编 32 位 `boringssl_self_test32`）：要解 `TARGET_2ND_ARCH`，会引入一大堆 32 位依赖，影响面远超收益。

**部署**：

由于 Root.vhd 是 2.5GB 的大文件，整盘重编要 30+ 分钟。为了快速验证修复有效，准备了热替换脚本（不重编，直接改 Root.vhd）：

```bash
sudo bash /home/henry/workspace/releases/bst-v5.22.210-9527/Baklava64/bst-v5.22.210_Baklava64-9527/hotfix-A16-bringup.sh
```

脚本做的事（统一 hot-fix 脚本，含 7j + 7k）：qemu-nbd 挂载 Root.vhd / Root.vdi → 删 `/android/system/etc/init/hw/` 下 4 个 boringssl rc + 覆盖 `/android/system/vendor/etc/vintf/manifest.xml` 删 keymaster 重复声明 → 卸载。release 目录里 staging area 的 `system/etc/init/hw/` 和 `rooted_system/etc/init/hw/` 已经手动清掉，`system/vendor/etc/vintf/manifest.xml` 和 `rooted_system/vendor/etc/vintf/manifest.xml` 已同步修复。

**验证清单**（部署后下次 Player.log 应该看到）：
- 不再出现 `exec_start boringssl_self_test32 ... failed`
- 不再出现 `shutdown_command 'reboot,boringssl-self-check-failed'`
- vold 能正常起来（不被 boringssl 牵连 SIGKILL）
- 进入 `on init` 后续 action（mount binderfs / start servicemanager 等）

---

### 7k. VINTF keymaster 重复声明 → keymint addService abort【B 适配】★当前卡点

**现象**（7j 修好后启动，进入 HAL 启动阶段时）：

两个 keymaster HAL 服务在 `addService` 时 SIGABRT：
```
>>> /vendor/bin/hw/android.hardware.keymaster@4.1-service <<<
>>> /vendor/bin/hw/android.hardware.security.keymint-service <<<
Abort message: 'Check failed: status == STATUS_OK (status=-3, STATUS_OK=0)'
#03 ... addService<AndroidKeyMintDevice, SecurityLevel>...
#04 ... main.cfi
```

`status=-3` 来自 `servicemanager` 拒绝注册。前置日志（service 启动之前就开始刷）：
```
servicemanager: getDeviceHalManifest: -2147483648 VINTF parse error:
  Cannot add manifest fragment /vendor/etc/vintf/manifest/android.hardware.keymaster@4.1-service.xml:
  HAL "android.hardware.keymaster" has a conflict:
  Conflicting FqInstance: @4.1::IKeymasterDevice/default
    (from /vendor/etc/vintf/manifest.xml)
  vs.
  @4.1::IKeymasterDevice/default
    (from /vendor/etc/vintf/manifest/android.hardware.keymaster@4.1-service.xml).
  Check whether or not multiple modules providing the same HAL are installed.

servicemanager: Caller(pid=438) Could not find
  android.hardware.security.keymint.IKeyMintDevice/default
  in the VINTF manifest. No alternative instances declared in VINTF.
```

注意 keymint 服务本身没问题，是 keymaster 重复声明让**整个 VINTF manifest 解析失败**，导致 keymint 也找不到自己的声明。

**根因**：

`/vendor/etc/vintf/manifest.xml` 主 manifest 和 `/vendor/etc/vintf/manifest/android.hardware.keymaster@4.1-service.xml` fragment manifest 都声明了 `@4.1::IKeymasterDevice/default`。

| 文件 | 声明来源 |
|---|---|
| `manifest.xml`（mainifest）| `device/generic/common/manifest.xml`（BlueStacks 用的 generic device 配置）|
| `android.hardware.keymaster@4.1-service.xml`（fragment）| `hardware/interfaces/keymaster/4.1/default/...xml`（AOSP 默认 HAL 模块自带的 vintf_fragment）|

主 manifest 内容（源 `device/generic/common/manifest.xml`）：
```xml
<!-- keymaster -->
<hal format="hidl">
   <name>android.hardware.keymaster</name>
   <transport>hwbinder</transport>
   <fqname>@4.0::IKeymasterDevice/default</fqname>
   <fqname>@4.1::IKeymasterDevice/default</fqname>      ← ★ 与 fragment 冲突
</hal>
```

A13 也有同样的配置（同样的 device/generic/common/manifest.xml + 同样的 fragment），但 A13 `libvintf` 容忍 fragment 与 mainifest 重复声明，所以日志里看不到任何 VINTF error（用 `rg VINTF Player-A13.log` 验证为空）。**A16 libvintf 变严，重复声明直接 fail 整个 manifest 解析**。

**修复**：删主 manifest 里的 keymaster 声明，让 fragment 唯一声明（fragment 是 AOSP 标准 HAL 模块自带的，应该优先）。

| 位置 | 修改 |
|---|---|
| 源码 `device/generic/common/manifest.xml`（line 177-183）| 把整个 `<hal>...keymaster...</hal>` 块注释掉（保留旧内容做追溯）|
| Release staging `system/vendor/etc/vintf/manifest.xml` + `rooted_system/vendor/etc/vintf/manifest.xml`（line 66-70）| 同样注释掉（assemble_vintf 转换后的版本，只有 @4.1，没 @4.0）|

**为什么删 main 而不删 fragment**：
- fragment 是 AOSP 标准 HAL 模块（`android.hardware.keymaster@4.1-service`）通过 `vintf_fragment` 自动安装的，删它要改 `hardware/interfaces/keymaster/4.1/default/Android.bp`，影响面大
- main manifest 是 BlueStacks 设备配置（generic device），改它是单文件改动，跟 BlueStacks "device manifest 是设备权威" 的角色一致
- fragment 在合并时会自动加进最终 manifest，删 main 不会丢 HAL 声明

**部署**：跟 7j 共用统一 hot-fix 脚本 `hotfix-A16-bringup.sh`，做两件事：
1. 删 4 个 boringssl rc（7j）
2. 用 staging `system/vendor/etc/vintf/manifest.xml` 覆盖 vhd 内的对应文件（7k）

```bash
sudo bash /home/henry/workspace/releases/bst-v5.22.210-9527/Baklava64/bst-v5.22.210_Baklava64-9527/hotfix-A16-bringup.sh
```

**验证清单**（部署后下次 Player.log 应该看到）：
- 不再出现 `VINTF parse error ... Conflicting FqInstance: @4.1::IKeymasterDevice/default`
- `vendor.keymaster-4-1` 和 `vendor.keymint-default` 能成功 `addService`（不 SIGABRT）
- keystore / gatekeeper / vold 等依赖 keymint 的服务能正常起来

**未选方案**：
- 改 fragment（`hardware/interfaces/keymaster/4.1/default/Android.bp` 加 `enabled: false` 或禁 `vintf_fragment`）：会让整个 keymaster 4.1 HAL 模块消失，更激进，影响面大
- 给 fragment 加 `override="true"`：libvintf 是否支持需要验证，且 A13 没这么做，没必要引入新的语义

---

## 8. 当前进度 & 下一步

按 boot 顺序，已打通的关卡（每个都对应上面一条修复）：

1. ✅ 盘 UUID 匹配，能在 A13 壳里挂载启动
2. ✅ vboxguest/vboxsf 加载成功
3. ✅ APEX(runtime/i18n) loop 挂载成功 → `exec /init` 不再因悬空 linker 失败
4. ✅ first stage proc/sys MS_REMOUNT，不再 EBUSY → `init first stage started!`
5. ✅ 找不到 fstab 不再 abort → `First stage mount skipped`
6. ✅ SELinux permissive，file_contexts 加载成功，不再 `execv Permission denied`
7. ✅ 关闭 printk 限速(`printk_devkmsg=on`)，second-stage 日志不再被吞
8. ✅ `/system/bin/init` restorecon 改非致命，不再因只读 system EROFS 而 FATAL
9. ✅ 进入 **second stage init**，开始解析 `.rc`、处理内建 action（SetupCgroups / wait_for_coldboot_done 等）
10. ✅ 关闭 "insecure file" 检查，`.rc` 正常 import（servicemanager / zygote / vold 等）
11. ✅ second stage 进入 `early-init`，`ueventd` 成功拉起(pid 327)
12. ✅ permissive 下跳过 SELinux 域转换检查（第 7d 条），`apexd-bootstrap` exit 0，激活 4 个 bootstrap apex
13. ✅ `early_system_aconfigd_platform_init` 成功

**当前卡点**：boringssl 32 位自检找不到二进制 → `reboot,boringssl-self-check-failed` shutdown（第 7e 条）。
`Android.bp` 已按 A13 注释 `init_rc`；待重编/热删 vendor rc 后验证能否进入 `on init`（binderfs mount）。

**7j 已定位并修复**：之前 7e 只删了 vendor 侧 rc，但 system 侧 `/system/etc/init/hw/init.boringssl.zygote*.rc` 仍在（来自 `system/core/rootdir/Android.bp`），其 `on init && abilist32=*` 分支照样会 `exec_start boringssl_self_test32` 失败。**Player.log 末尾的 `Service vold has 'reboot_on_failure' ... and failed` 是被这次 reboot 牵连的，不是 vold 自己挂**。修复方案 A（跟 A13 对齐，禁 system 侧 boringssl rc）：`system/core/rootdir/Android.bp` 加 `enabled: false` + 从 `init.rc` required 移除。同时 release staging area 已清，提供 hot-fix 脚本 `hotfix-A16-bringup.sh` 直接改 Root.vhd/vdi 验证。

**7j 验证结果**：部署 hot-fix 后启动到 20 秒（之前只能到 5 秒），vold / servicemanager / zygote / logd 都起来了，boringssl 完全不再触发。但出现了**新的崩点（7k）**。

**7k 已定位并修复**：VINTF keymaster 重复声明（mainifest + fragment 都声明 `@4.1::IKeymasterDevice/default`）。A13 libvintf 容忍，A16 变严 → 整个 manifest 解析失败 → keymint addService `status=-3` abort。修复：删 `device/generic/common/manifest.xml` 主 manifest 里的 keymaster 块，让 fragment 唯一声明。release staging 已同步，统一 hot-fix 脚本 `hotfix-A16-bringup.sh` 同时处理 7j（删 rc）+ 7k（覆盖 manifest.xml）。

**编译侧进展（7f/7g/7h/7i 解决后）**：hwservicemanager 已装回 `/system/bin`，BlueStacks framework/服务编译连环失败已修复，`m framework-minus-apex` / `m services.impl` 均通过；`libgcall_jni` 因 A16 Soong 环境变量白名单不含 `IMAGE` 导致 `BUILD_BAKLAVA` 没定义、链接报 `undefined symbol: gcallCreatorsStudioEffectControlClbk`，已通过"Android.mk 改判 `ANDROID_IMAGES` + GcallDec.cpp 条件编译加 `BUILD_BAKLAVA`"修复；`BstCommandProcessor` app 适配了 4 处 A16 API 变化（含本次 `removeTaskWrapper → ActivityTaskManager.removeTask` 修复）。整盘 `build_Baklava64.sh` 已跑通生成可启动 Root.vhd，正在迭代运行时问题。

**待办 / 怀疑点**：
- 部署 boringssl 修复后，关注 servicemanager / vold / zygote / adbd 能否起。
- 重编完后看 hwservicemanager + keymaster4.1 是否不再 SIGABRT（第 7f 条运行时验证）。
- 重编完后看 BlueStacks 服务（BstFilterApps/BstUtils/BstHostCall）能否在 SystemServer 里正常注册拉起（第 7g 条运行时验证）。
- `linkerconfig` rc=127 / `ld.config.txt` 缺失（第 4 条遗留）。
- `ro.vendor.init_dev_config.path` 不存在（init.rc:79 的 exec_start init_dev_config 失败，可能非致命）。

---

## 9. 完整复刻指南（编译 / 打包 / 部署细节）

> 本节目标：让拿到本仓库的人能**从源码复刻出可在 A13 壳里启动到当前进度的 A16 镜像**。
> 所有路径以本机为例，按需替换前缀。

### 9.0 环境 & 前置依赖

| 项 | 值 / 说明 |
|----|-----------|
| OS | Ubuntu 22.04（容器/物理机均可），bash |
| 源码根 `BASEPATH` | `/home/henry/workspace/app-player` |
| Android 源码 `ANDROIDHOME` | `$BASEPATH/android-16`（AOSP 16 + BlueStacks patch） |
| out 目录 `OUT_DIR` | `out_nxt_Baklava64`（即 `$ANDROIDHOME/out_nxt_Baklava64`） |
| hd 源码 `HD_SOURCE_TOP` | `$BASEPATH/hd`（guest 驱动 / BootImage / init.sh 等） |
| 构建脚本 | `$BASEPATH/buildscripts`（`Makefile` + `bin/` 工具 + `create_vdi.sh`） |
| release 目录 `REL_DIR` | `/home/henry/workspace/releases/bst-v5.22.210-9527/Baklava64/bst-v5.22.210_Baklava64-9527` |
| OEM / IMAGE | `OEM=nxt`，`IMAGE=Baklava64` |
| lunch target | `android_x86_64-trunk_staging-eng`（baklava 专用，见 `buildscripts/Makefile`） |
| sudo 密码 | 本机为 `1`（脚本里走 `BST_SUDO_PASSWORD` / `echo 1 | sudo -S`） |

需要的系统工具：`qemu-nbd`(qemu-utils)、`VBoxManage`(virtualbox)、`parted`、`mke2fs`、
clang(AOSP 自带 `prebuilts/clang/...`)。

测试壳：Windows 上的 BlueStacks **Tiramisu64(A13)** 引擎
（`C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64\`）。我们把编出来的 A16 `Root.vhd` /
`fastboot.vdi` 覆盖进去，借 A13 引擎启动 A16 guest，从 `Player.log` 读 guest 串口日志。

### 9.1 一次性：完整构建 Root.vhd（首次 / 大改动时）

`Root.vhd` 走正式流程整体构建（**out-of-tree**，产物在 `../hd` 同级，不污染 vendor）：

```bash
cd /home/henry/workspace/app-player
export BST_SUDO_PASSWORD=1
# 完整链路：android(iso_img+ramdisk) -> libs -> 各 fs -> create_vdi.sh -> clonehd 出 Root.vhd
make -f buildscripts/Makefile <目标> OEM=nxt IMAGE=Baklava64 \
     ANDROIDOUTPUTLOC=/home/henry/workspace/releases/bst-v5.22.210-9527 \
     PKG=bst-v5.22.210_Baklava64-9527
```
- `buildscripts/Makefile` 的 `make_vdi_file` 宏：先 `create_vdi.sh` 把 `*.fs` 灌成 `*.vdi`，
  再 `vboxmanage clonehd ... --format VHD` 出 `Root.vhd`。
- **踩坑(create_vdi.sh)**：原先用 `fdisk` heredoc 建分区，在 nbd 上不稳定、`/dev/nbd0p1` 出不来。
  已改成 `parted -s ... mklabel msdos mkpart primary ext4 1MiB 100%` + `partx -u`，并
  `modprobe nbd max_part=8`。

> 日常只改 `system/core/init/*.cpp` 时**不必**重跑整链，用 9.3 的 `m init` + 9.4 注入即可，快得多。

### 9.2 内核（kernel-a16）

`fastboot.vdi` 里的 `bzImage` 来自 `$OUT_DIR/.../obj/kernel`。改了 `kernel-a16` 源码 / defconfig
（`bst-x86_64_defconfig`）才需要重编：

```bash
cd /home/henry/workspace/app-player
make -f buildscripts/Makefile kernel OEM=nxt IMAGE=Baklava64 \
     ANDROIDOUTPUTLOC=/home/henry/workspace/releases/bst-v5.22.210-9527 \
     PKG=bst-v5.22.210_Baklava64-9527
# 或直接 BUILD_KERNEL=1 交给 9.5 的脚本
```

### 9.3 单独重编 init（最常用：改了 system/core/init/*.cpp 后）

```bash
cd /home/henry/workspace/app-player/android-16
export PATH="/home/henry/workspace/app-player/buildscripts/bin:$PATH"
export BST_SUDO_PASSWORD=1
export OEM=nxt OUT_DIR=out_nxt_Baklava64 IMAGE=Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=/home/henry/workspace/app-player
export HD_SOURCE_TOP=/home/henry/workspace/app-player/hd      # ★缺它 kati 会报 "Please set HD_SOURCE_TOP"
export ALLOW_MISSING_DEPENDENCIES=true LC_ALL=C LANG=C
source build/envsetup.sh
lunch android_x86_64-trunk_staging-eng
m init
# 产物：out_nxt_Baklava64/target/product/x86_64/system/bin/init  (≈20s)
```
- 关键环境变量缺一不可：`OUT_DIR`(决定产物落到 out_nxt_Baklava64)、`HD_SOURCE_TOP`(否则
  解析 `../hd/Source/.../Android.mk` 时 kati 直接报错)、`ALLOW_MISSING_DEPENDENCIES`(容忍裁剪)。

### 9.4 把新 init 注入 release 的 Root.vhd（qemu-nbd 热替换）

> 避免整盘重建。Root.vhd 内部布局：ext4 分区里是 `/android/system/...`、`/dataFS`。
> 真正的 first-stage init = `/android/system/bin/init`。

```bash
cd /home/henry/workspace/releases/bst-v5.22.210-9527/Baklava64/bst-v5.22.210_Baklava64-9527
NEW=/home/henry/workspace/app-player/android-16/out_nxt_Baklava64/target/product/x86_64/system/bin/init
echo 1 | sudo -S modprobe nbd max_part=8
sudo qemu-nbd -d /dev/nbd1 2>/dev/null || true
sudo qemu-nbd --connect=/dev/nbd1 -f vpc Root.vhd   # ★ VHD 在 qemu 里是 -f vpc
sleep 2; sudo partx -u /dev/nbd1
sudo mkdir -p /mnt/a16root && sudo mount /dev/nbd1p1 /mnt/a16root
sudo cp -f "$NEW" /mnt/a16root/android/system/bin/init
sudo chmod 0755 /mnt/a16root/android/system/bin/init; sync
md5sum "$NEW" /mnt/a16root/android/system/bin/init   # 两边应一致
sudo umount /mnt/a16root; sudo qemu-nbd -d /dev/nbd1; sleep 1
# 改 UUID 成 A13 媒体注册表的值（见第 1 节），并清掉 VirtualBox.xml 里的旧缓存
sed -i "/Root./d" "$HOME/.config/VirtualBox/VirtualBox.xml" 2>/dev/null || true
VBoxManage internalcommands sethduuid Root.vhd 54e9ad31-a169-4d5b-a0e0-705d62e96e71
md5sum Root.vhd
```
- **踩坑**：`-f vpc` 才是 VHD 格式；用 `nbd1` 而非 `nbd0`(0 常被整盘构建占用)；
  改完内容后 VHD footer UUID 不变，但仍显式 `sethduuid` 保险。
- **副作用**：手工 cp 会丢 SELinux xattr → 触发第 7b 条的 restorecon EROFS（已用源码补丁兜住）。

### 9.5 重编并部署 fastboot.vdi（改了 init.sh / stage2.sh / kernel 后）

封装脚本：`hd/guest/build_fastboot_vdi.sh`（**本次 bringup 新增**，非正式流程）。

```bash
cd /home/henry/workspace/app-player
export BST_SUDO_PASSWORD=1
bash hd/guest/build_fastboot_vdi.sh                 # 用现成 bzImage 打包
BUILD_KERNEL=1 bash hd/guest/build_fastboot_vdi.sh  # 先 make kernel 再打包
```
脚本做的事（按顺序）：
1. 前置检查：`obj/kernel/.../bzImage`、clang、`out_bstconf/bstconf`、`out_bstchkdata/bstchkdata`
   （后两个需先编过 `libs`）。
2. 把 `bstconf` / `bstchkdata` 拷进 `BootImage/`。
3. `cd hd/guest && make all`：编 guest 驱动 + `build_fastboot`，产出
   `BootImage/fastboot/fastboot.vdi`（内含 bzImage + initrd，initrd 里就是 `init.sh`/`stage2.sh`）。
4. `VBoxManage internalcommands sethduuid fastboot.vdi $FASTBOOT_UUID`
   （默认 `91b80c95-aa7d-459d-93e4-c479f5babbb7`，可用 `FASTBOOT_UUID=` 覆盖；空则不改）。
5. 拷到 `$REL_DIR/fastboot.vdi`，并打印 UUID / md5 / 大小。

可覆盖变量：`IMAGE`/`OEM`/`ANDROIDHOME`/`OUT_DIR`/`REL_DIR`/`FASTBOOT_UUID`/`BUILD_KERNEL`
/`CLANG_PREBUILT_BIN` 等（见脚本头注释）。

### 9.6 端到端复刻流程（TL;DR）

```text
①(首次) make ... 出 Root.vhd            # 9.1
②(改内核) make kernel 或 BUILD_KERNEL=1  # 9.2
③ 改 system/core/init/*.cpp → m init     # 9.3
④ qemu-nbd 把 init 注入 Root.vhd + 改UUID # 9.4
⑤ 改 init.sh/stage2.sh → build_fastboot_vdi.sh（自动改UUID+拷release）# 9.5
⑥ 把 REL_DIR 下的 Root.vhd / fastboot.vdi 拷到 Windows Tiramisu64 引擎目录覆盖
⑦ 启动，看 Player.log（guest 串口）；按日志定位下一个崩点，回到③/⑤迭代
```
- 只改 `.cpp`：跑 ③④⑥（不用动 fastboot.vdi）。
- 只改 `init.sh`/`stage2.sh`：跑 ⑤⑥（不用动 Root.vhd）。
- Windows 端校验：`md5sum.exe <文件>` 与 Linux 端 `md5sum` 对一致，确认拷贝成功。

---

## 10. 回退清单（测试完成后）

正式合入前，**至少回退以下【A 临时】项**：

- [ ] init.sh：删 `printk=8` / `printk_devkmsg=on` / 所有 `A16DBG` 标记
- [ ] init.sh：vbox insmod 恢复 `load_module`(致命)语义
- [ ] stage2.sh：删所有 `A16DBG` 标记
- [ ] UUID 改写仅用于测试，正式流程用原生 UUID

【B 适配】项（4/5/6/7/7b~7j/11~26）按需保留，但建议 review 实现方式是否进 BlueStacks 正式 patch 集。
重点 review：
- `7f` hwservicemanager 回 /system：是否干脆给 BlueStacks 镜像加上 system_ext 分区（更接近上游），而不是把二进制搬回 /system。
- `7g` BlueStacks framework 补丁：`@hide` 标注是否应该回到 BlueStacks 上游 patch 源头统一处理，而不是每次 A→A+1 升级手工补。
- `7g` 中 `DefaultPermissionGrantPolicy` 用 `UserManagerService.getUserIds()`：这是 A16 API 迁移，正常做法。
- `7h` gcall `Android.mk`：双 `ifeq`（`IMAGE` + `ANDROID_IMAGES`）是为绕开 Soong 白名单缺失 `IMAGE` 的临时写法。更干净的做法是 BlueStacks 把 `IMAGE` 注册进 Soong 的允许列表（或全局改用 `ANDROID_IMAGES` 单一变量），届时可以把两段 `ifeq` 收成一段 `ifneq ($(filter Baklava64,$(IMAGE) $(ANDROID_IMAGES)),)`。
- `7i` BstCommandProcessor 适配：注意 (3) `bstReloadPointerIcon` 被直接去掉、(4) 改走 `ActivityTaskManager`，这两条都改了运行时行为。若 BlueStacks 后续发现有鼠标光标刷新/任务删除的回归，先回这两条 review（看是否需要把 BlueStacks 原 patch 移植到 A16 框架）。
- `7j` boringssl system rc 禁用：跟 `7e` 配套。本质上是 BlueStacks 64-only 镜像不需要 boringssl self-test（那是 AOSP 给 OEM 做合规验证用的）。也可以考虑反过来 —— 解开 `TARGET_2ND_ARCH` 让镜像真的支持 32 位（但影响面比禁 rc 大得多）。本次走"跟 A13 对齐禁 rc"路线。注意 `7e` + `7j` 是**两处不同 Android.bp**（前者 `external/boringssl/selftest/`，后者 `system/core/rootdir/`），下次 review 时不要只看一处。
- `7k` VINTF keymaster 重复声明：A16 libvintf 比 A13 严，要求 HAL 实例声明唯一。本次删 mainifest 保 fragment，本质是认 AOSP 标准 HAL 模块的 vintf_fragment 为权威。更彻底的做法是 review BlueStacks 整个 `device/generic/common/manifest.xml`，看看其它 HAL（light/health/usb 等）是不是也跟 fragment 重复（这次只有 keymaster 真撞了，可能因为只有它装了 fragment + 又在 main 里显式声明）。后续 A→A+1 升级时，类似的"mainifest vs fragment 冲突"可能还会出现，可以考虑写个 `assemble_vintf` 前的预校验脚本。

---

## 附：本轮产物校验值

| 文件 | UUID | 说明 |
|------|------|------|
| fastboot.vdi | `91b80c95-aa7d-459d-93e4-c479f5babbb7` | 含 init.sh 全部改动 + kmsg 限速关闭 |
| Root.vhd | `54e9ad31-a169-4d5b-a0e0-705d62e96e71` | boringssl rc 热删后 md5=`7066af7bef6691b4a66f6aeeedca82bd`；**完整重编（含 7f/7g）后 md5 会变** |

> md5 每次重编都会变，以 `build_fastboot_vdi.sh` 输出和 `md5sum Root.vhd` 为准。

---

## 附 B：最近一次会话修改的文件清单（2026-06-18）

### hwservicemanager 适配（第 7f 条）
- `system/hwservicemanager/Android.bp`：去掉 `system_ext_specific: true`
- `system/hwservicemanager/hwservicemanager.rc`：路径改 `/system/bin/hwservicemanager`
- `device/generic/common/packages.mk`：`PRODUCT_PACKAGES += hwservicemanager` + HIDL helper
- `build/make/target/product/generic/Android.bp`：从 `aosp_shared_system_image.deps` 移除 hwservicemanager / hidl.allocator / hidl.memory（避免 arch:common 冲突）
- `build/make/target/product/base_system.mk`：注释 `hwservicemanager_compat_symlink_module`

### BlueStacks framework 补丁（第 7g 条）
**拷贝自 A13（7 + 1 文件）**：
- `frameworks/base/core/java/com/bluestacks/os/`（7 文件）
- `frameworks/base/core/java/android/util/BstUtils.java`

**已 patch**：
- `frameworks/base/core/java/Android.bp`（加 AIDL 到 connectivity-shared-srcs）
- `frameworks/base/core/java/android/content/Context.java`（加 BST 服务名常量）
- `frameworks/base/core/java/android/app/SystemServiceRegistry.java`（注册 3 个 Manager）
- `frameworks/base/core/java/android/permission/ILegacyPermissionManager.aidl`（加 assignPermissionsToBstApps）
- `frameworks/base/core/java/com/bluestacks/os/{BstFilterAppsManager,BstUtilsManager,BstHostCallManager,BstHostCallCcCodes}.java` + `android/util/BstUtils.java`（加 `@hide`）
- `frameworks/base/services/core/java/com/android/server/pm/permission/{LegacyPermissionManagerInternal,LegacyPermissionManagerService,DefaultPermissionGrantPolicy}.java`
- `frameworks/base/services/core/java/com/android/server/am/ActivityManagerService.java`（mapIsolatedUid 实现）
- `frameworks/base/core/java/android/app/ActivityManagerInternal.java`（mapIsolatedUid 抽象）
- `frameworks/base/services/core/java/com/android/server/power/stats/BatteryStatsImpl.java`（bstMapUid）
- `frameworks/base/services/core/java/com/android/server/policy/{WindowManagerPolicy,PhoneWindowManager}.java`
- `frameworks/base/services/core/java/com/android/server/wm/{DisplayRotation,WindowManagerService}.java`
- `frameworks/base/services/java/com/android/server/SystemServer.java`（启动 3 个服务）

**编译脚本**：
- `buildscripts/build_Baklava64.sh`：构建成功后 `VBoxManage sethduuid Root.vhd 54e9ad31-...`（对齐第 1 节测试 UUID）

### gcall native 适配（第 7h 条）
- `hd/Source/gcall/guest/Android.mk`：加 `ifeq ($(IMAGE), Baklava64) ... -DBUILD_BAKLAVA` + `ifeq ($(ANDROID_IMAGES), Baklava64) ... -DBUILD_BAKLAVA`（两段，分别覆盖外层 Makefile 与 soong→kati 两条执行路径）。
- `hd/Source/gcall/guest/GcallDec.cpp`：`#if !defined(BUILD_PIE) && !defined(BUILD_RVC) && !defined(BUILD_T)` 末尾加 `&& !defined(BUILD_BAKLAVA)`，让 `gcallCreatorsStudioEffectControlClbk(...)` 调用在 Baklava64 上也被排除。

### BstCommandProcessor app 适配（第 7i 条）
- `packages/apps/BstCommandProcessor/src/com/bluestacks/BstCommandProcessor/BstCommandProcessorService.java`：去掉 `import android.util.Features;`，`Features.GetArmAppMarker()` 改成字面量 `"containsArmLibs.txt"`。
- `packages/apps/BstCommandProcessor/src/com/bluestacks/BstCommandProcessor/BstCommandProcessorApplication.java`：`mPm.setComponentEnabledSetting(...)` 补 `getPackageName()` 形参（A16 多了 callingPackage）。
- `packages/apps/BstCommandProcessor/src/com/bluestacks/BstCommandProcessor/BstCommandLoop.java`：
  - `showNativeMousePointerClbk`：去掉 `InputManager.getInstance().bstReloadPointerIcon()` 调用，只设 `SystemProperties.set("bst.config.show_mouse_ptr", ...)`。
  - 加 `import android.app.ActivityTaskManager;`，`mActivityManager.removeTaskWrapper(persistenttaskId, true)` 改成 `ActivityTaskManager.getInstance().removeTask(persistenttaskId)`。

### 7L. util.cpp socket context —— 禁用 setsockcreatecon (对齐 A13)【B 适配】★关键

**现象**（7j/7k 修完后重启，进入 HAL/服务启动阶段）：

```
init: Could not create socket 'tombstoned_crash': setsockcreatecon("skip") failed: Invalid argument
init: Could not create socket 'logd': setsockcreatecon("skip") failed: Invalid argument
init: Could not create socket 'lmkd': setsockcreatecon("skip") failed: Invalid argument
```

→ `logd` / `lmkd` / `tombstoned` socket 创建失败 → 服务起不来 → `keystore2` 依赖它们也连锁失败 → 重试 4 次触发 `InitFatalReboot`。

**根因链**：

1. 第 7d 节修改 `service.cpp`，在 permissive 下 `ComputeContextFromExecutable()` 返回字符串 `"skip"`（不是合法的 SELinux context，只是个占位符）。
2. `service.cpp:673` 把这个 `"skip"` 赋值给 `scon` 变量。
3. `service.cpp:685` 调用 `socket.Create(scon)`，把 `"skip"` 传给 socket 创建函数。
4. `util.cpp:CreateSocket(..., socketcon="skip")` 调用 `setsockcreatecon("skip")`，但 `"skip"` 不是合法 SELinux context → 返回 `EINVAL`。
5. socket 创建失败 → 核心服务无法启动 → 连锁崩溃。

**对比 A13**：

A13 的 `util.cpp:CreateSocket` 直接把 `setsockcreatecon` 调用用 `if (false)` 禁掉了（第 98 行和第 109 行）：

```cpp
if (false) {   // 原本是 if (!socketcon.empty())
    if (setsockcreatecon(socketcon.c_str()) == -1) {
        return ErrnoError() << "setsockcreatecon(\"" << socketcon << "\") failed";
    }
}
// ...
if (false) setsockcreatecon(nullptr);  // 原本是 if (!socketcon.empty())
```

A13 这样做的原因（注释）："a lot of files like build.prop, modules.* have group writable and others writable flags set" —— 权限问题导致 SELinux context 设置不可靠，干脆全部跳过。BlueStacks permissive 模式下也不需要给 socket 打 context。

**修复**（完全对齐 A13）：

修改 `android-16/system/core/init/util.cpp` 的 `CreateSocket()` 函数，两处 `if (!socketcon.empty())` 改成 `if (false)`：

```cpp
Result<int> CreateSocket(const std::string& name, int type, bool passcred, bool should_listen,
                         mode_t perm, uid_t uid, gid_t gid, const std::string& socketcon) {
    // BlueStacks(baklava bringup): 禁用 socket SELinux context（对齐 A13）。
    // service.cpp 在 permissive 下返回占位符 "skip"，它不是合法 context，
    // setsockcreatecon("skip") 会 EINVAL，导致 logd/lmkd/tombstoned socket 起不来。
    if (false) {
        if (setsockcreatecon(socketcon.c_str()) == -1) {
            return ErrnoError() << "setsockcreatecon(\"" << socketcon << "\") failed";
        }
    }

    android::base::unique_fd fd(socket(PF_UNIX, type, 0));
    if (fd < 0) {
        return ErrnoError() << "Failed to open socket '\" << name << "''";
    }

    if (false) setsockcreatecon(nullptr);  // BlueStacks: 同上（对齐 A13）

    struct sockaddr_un addr;
    // ... 后续代码不变
}
```

**验证**（重编 init → 注入 Root.vhd → 启动）：

```
init: Created socket '/dev/socket/logd', mode 666, user 1036, group 1036       ✅
init: Created socket '/dev/socket/logdr', mode 666, user 1036, group 1036      ✅
init: Created socket '/dev/socket/logdw', mode 222, user 1036, group 1036      ✅
init: ... started service 'logd' has pid 420                                    ✅
init: Created socket '/dev/socket/lmkd', mode 660, user 1000, group 1000       ✅
init: ... started service 'lmkd' has pid 421                                    ✅
init: Created socket '/dev/socket/tombstoned_crash', mode 666, user 1000, group 1000      ✅
init: Created socket '/dev/socket/tombstoned_intercept', mode 666, user 1000, group 1000  ✅
init: Created socket '/dev/socket/tombstoned_java_trace', mode 666, user 1000, group 1000 ✅
init: ... started service 'tombstoned' has pid 449                              ✅
```

不再出现任何 `setsockcreatecon("skip") failed` 错误。`logd` / `lmkd` / `tombstoned` 正常启动。

**新崩点**：`keystore2` 仍然 `exited with status 1` 连续 4 次 → `InitFatalReboot`。但这是 **keystore2 本身的问题**，与 socket 创建无关（socket 已经成功）。下一步需要定位 keystore2 为什么启动失败（缺依赖？HAL 问题？二进制损坏？）。

---

## 8. 当前进度 & 下一步（更新 2026-06-22 20:10）

按 boot 顺序，已打通的关卡：

1. ✅ 盘 UUID 匹配
2. ✅ vboxguest/vboxsf 加载成功
3. ✅ APEX loop 挂载
4. ✅ first stage init（proc/sys MS_REMOUNT, fstab 不致命）
5. ✅ SELinux permissive
6. ✅ second stage init 进入
7. ✅ `.rc` import（跳过 insecure file 检查）
8. ✅ `ueventd` 拉起
9. ✅ `apexd-bootstrap` 成功（permissive 下跳过域转换）
10. ✅ boringssl self-test 禁用（7e + 7j，两处）
11. ✅ hwservicemanager 装回 `/system/bin`（7f）
12. ✅ VINTF keymaster 重复声明修复（7k）
13. ✅ **socket SELinux context 禁用（7L）** —— logd / lmkd / tombstoned 正常启动

**当前卡点**：`keystore2` 启动后立即退出（exit status 1），连续 4 次 → `InitFatalReboot`。

可能原因：
- 缺少依赖的 HAL（keymint？gatekeeper？）
- keystore2 配置问题
- 二进制本身问题（ABI 不匹配？）

**待办**：
- 查看 keystore2 输出（如果 logd 能捕获的话）
- 检查 keystore2 依赖的 HAL 服务是否启动
- 对比 A13 的 keystore2 配置

**编译侧完成**（7f/7g/7h/7i/7j/7k/7L）：
- hwservicemanager 回 /system
- BlueStacks framework/服务编译通过
- gcall 链接修复
- BstCommandProcessor API 适配
- boringssl rc 全部禁用
- VINTF manifest 修复
- **socket context 禁用（本次）**

---


### 7M. keystore2 —— ICU 库缺失【B 适配】★本次核心交付

**现象**（7L socket 修复后 boot 推进到服务阶段）：keystore2 启动后立即 `exited with status 1`；去掉 critical 后 boot 仍卡在 `wait_for_prop keystore.module_hash.sent true`（init.rc:1015），zygote 永远不起。

**诊断技巧**（Rust 程序错误走 logd 不走 stderr，Player.log/kmsg 看不到）：写临时诊断脚本，先清 logd、跑目标进程、再把 logcat dump 回 kmsg：

```sh
#!/system/bin/sh   # ks2_diag.sh
logcat -c 2>/dev/null
/system/bin/keystore2 /data/misc/keystore >/dev/kmsg 2>&1 &
P=$!
sleep 5
logcat -d -v brief *:E 2>/dev/null >/dev/kmsg   # 关键：dump logd 回 kmsg 才看得到 Rust 错误
```

在 init.rc 里 `restorecon /data/misc/keystore` 后插 `exec - root root -- /system/bin/sh /system/bin/ks2_diag.sh` 调用。
> 踩坑：init.rc 里 `$` 会被当成属性引用吞掉（报 "deprecated syntax for specifying property"），含 `$` 的逻辑**必须放进独立 .sh 脚本再 exec 调用**，不能直接写在 exec 行内。

**根因**（logcat 抓到的真实错误）：
```
F/linker: CANNOT LINK EXECUTABLE "/system/bin/keystore2":
  library "libandroidicu.so" not found: needed by /system/lib64/libsqlite.so in namespace (default)
```
- keystore2 → libsqlite → 需要 libandroidicu.so
- A13：libandroidicu.so 在 `/system/lib64/`，default namespace 直接找到
- A16：ICU 整体挪进 `com.android.i18n` APEX，`/system/lib64/` 下没有；正常应由 ld.config.txt 把 i18n APEX 路径映射进链接命名空间，但 linkerconfig 没生成 ld.config.txt（见 7P）→ default namespace 找不到 → 链接失败

**修复**（热改 Root.vhd，A13 对齐：把 i18n APEX 里的 ICU 库放到 /system/lib64）。i18n apex 是 erofs（不是 capex），payload 在 offset 4096：
```bash
losetup -o 4096 <loop> /system/apex/com.android.i18n.apex
mount -t erofs -o ro <loop> /mnt/i18n
cp /mnt/i18n/lib64/{libandroidicu,libicuuc,libicui18n,libicu,libicu_jni}.so /system/lib64/
```
> libandroidicu.so 只有 52KB（stub），它还 NEEDS libicuuc.so(1.9MB)/libicui18n.so(2.8MB)，必须一起复制；A16 没有 libicudata.so（ICU 数据内嵌）。

**验证**：keystore2 不再 exit 1（pid 持续存活）；`init: Wait for property keystore.module_hash.sent=true took 28ms` 门控解除。

### 7N. odsign 禁用（A14+ 新增, A13 无）【对齐 A13】

**现象**：odsign（ART AOT 编译签名）链接失败循环 exit 1，卡 init.rc 两处门控 `wait_for_prop odsign.key.done 1`(L1049) / `odsign.verification.done 1`(L1103)。odsign 是 A14+ 才有，**A13 根本没有 odsign**，对 boot 完成非必需。

**修复**（纯对齐 A13）：注释 init.rc 三处 —— `start odsign`(L1046) + 两个 `wait_for_prop odsign.*`。

**验证**：不再 odsign 循环；boot 越过 zygote-start 门控。

### 7O. zygote 链接 —— art APEX 库软链到 /system/lib64【B 临时】

**现象**（odsign 禁用后）：
```
CANNOT LINK EXECUTABLE "/system/bin/app_process64": library "libnativeloader.so" not found: needed by main executable
```
libnativeloader.so 在 com.android.art APEX。A13 里 ART 库在 /system/lib64；A16 把 ART 挪进 com.android.art APEX。

**修复**：art 是 `.capex`（压缩），先解压再挂载提取，软链到 /system/lib64：
```bash
unzip com.android.art.debug.capex -d art_unzipped          # 得到 original_apex
losetup -o 4096 <loop> art_unzipped/original_apex           # erofs payload @ 4096
mount -t erofs -o ro <loop> /mnt/art
for lib in /mnt/art/lib64/*.so; do
  name=$(basename $lib)
  [ ! -e /system/lib64/$name ] && ln -s /apex/com.android.art/lib64/$name /system/lib64/$name
done   # 共 34 个软链（6 个已存在跳过）
```
软链指向 `/apex/com.android.art/lib64/X`（运行时 apexd 挂载 art APEX 到此，目标有效）。

**验证**：zygote 不再报链接错误，能 `started service zygote has pid`。

> 7M/7O 都是 7P 的症状（无 ld.config.txt）。修好 7P 后这两节的库复制/软链理论上可回退。

### 7P. ★根因: linkerconfig abort —— ro.vndk.version 残留【B 适配】★关键

7M/7O 都是本节症状。**对比 A13 参照日志**（`out_nxt_Baklava64/.../tiramisu-shell-baklava64/Player-A13.log`）定位到精确差异。

linkerconfig abort：
```
linkerconfig: libc: Fatal signal 6 (SIGABRT)
DEBUG: Abort message: 'Check failed: !"undefined var" SANITIZER_DEFAULT_VENDOR is not defined'
```

**A13 vs A16 行为差异**（`system/linkerconfig/contents/namespace/vendordefault.cc`）：
- **A13** 用 `if (ctx.IsVndkAvailable())`：`IsVndkAvailable()`（context.cc:87）遍历已加载 APEX 找 `com.android.vndk.*`，**BlueStacks 无 VNDK APEX → false → 跳过 Var() 块 → 不 abort**
- **A16** 改用 `if (IsVendorVndkVersionDefined())`：`IsVendorVndkVersionDefined()`（environment.cc:43）只看 `ro.vndk.version` 属性。镜像 build.prop 里残留 `ro.vndk.version=33` → true → 进入块 → 但 VNDK APEX 缺失致变量没加载（`LoadVndkLibraryListVariables` 里 `access(/apex/com.android.vndk.vXX)!=0` 提前 return）→ `Var("SANITIZER_DEFAULT_VENDOR")` CHECK abort

A13 日志里 linkerconfig 也报 `Unable to access VNDK APEX at path: /apex/com.android.vndk.v33`，但那是 `PLOG(ERROR)` + continue，**不 abort**。A13 的 `Var()` 和 A16 的 `Var()`（context.cc:101 `CHECK(!"undefined var")`）代码相同；区别纯在调用处的 guard 条件。

**临时修复**（热改 Root.vhd，验证用）：删 build.prop 里的 `ro.vndk.version=33`。删除后 `IsVendorVndkVersionDefined()=false` → 跳过 abort 块，对齐 A13 的 `IsVndkAvailable()=false` 路径。
**验证**：linkerconfig 不再 SIGABRT、不再报 SANITIZER_DEFAULT_VENDOR。

### 7Q. ★源头修复: scratch-gaurav 属性文件全部更新为 A16 值【B 适配】

7P 的 `ro.vndk.version=33` 来自 BlueStacks 的属性覆盖文件，源头在 `app-player/scratch-gaurav/misc_x86_64/baklava/`（107 个区域/运营商 `baklava.bluestacks.prop.*` + `additional_system_props/additional_system_prop*`，共 110 个文件）。这些文件全是 A13(Tiramisu) 时代的值，被直接用于 A16 镜像覆盖。

**对照 A16 AOSP 自带 build.prop**（`out_nxt_Baklava64/.../system/build.prop`，A16 正确基准）批量更新全部 110 个文件：

| 属性 | 改前(A13残留) | 改后(A16) |
|---|---|---|
| `ro.vndk.version` | 33 | **注释删除**（A16 build.prop 本就无此项，VNDK 已废弃）|
| `*.build.version.sdk`（system/system_ext/product/odm/vendor_dlkm/system_dlkm/odm_dlkm）| 33 | 36 |
| `*.build.version.release` | 13 | 16 |
| `*.release_or_codename` / `release_or_preview_display` | 13 | 16 |
| `*.build.id` | TQ2B.230505.005.A1 | BP4A.251205.006 |
| `*.security_patch` | 2023-05-05 | 2025-11-05 |
| `ro.product.first_api_level` | 33 | 36 |
| `min_supported_target_sdk` | 23 | 28 |
| fingerprint / display.id / description | `:13/TQ2B.230505.005.A1/` | `:16/BP4A.251205.006/` |

**故意保留**：`ro.build.version.codename=REL` —— release 构建的标准值（A16 out 显示 Baklava 是因为 trunk_staging-eng 预发布版；BlueStacks 是 user release-keys，REL 正确）。

备份在 `scratch-gaurav/misc_x86_64/baklava.bak_a13_20260622`。下次 `build_Baklava64.sh` 重建即生效（含 7P 的 vndk.version 删除，linkerconfig 不再 abort）。

---

## 8. 当前进度 & 下一步（更新 2026-06-22 23:30）

按 boot 顺序已打通的关卡：

1. ✅ 盘 UUID 匹配 / vbox 模块加载 / APEX loop 挂载 / first stage init / SELinux permissive
2. ✅ second stage init / .rc import / ueventd / apexd-bootstrap
3. ✅ boringssl 禁用（7e+7j）/ hwservicemanager 回 /system（7f）/ VINTF keymaster（7k）
4. ✅ socket SELinux context 禁用（7L）—— logd/lmkd/tombstoned 正常
5. ✅ **keystore2 修复（7M，ICU 库）** —— `keystore.module_hash.sent` 门控解除
6. ✅ **odsign 禁用（7N，对齐 A13）**
7. ✅ **zygote 链接修复（7O，art 库软链）** —— zygote 能启动
8. ✅ **linkerconfig abort 根因（7P）+ 源头属性修正（7Q）** —— linkerconfig 不再 abort

**当前卡点**：zygote 启动后约 600ms 被 SIGKILL（onrestart 循环重启），错误走 logd 未抓到。boot 已从最初的"26s reboot"推进到"zygote-start @ 6.6s"。

**zygote 死因排查方向**（下一步）：
- zygote (app_process64) 链接已过（art 库软链），死在 ART VM / Java 初始化阶段
- 错误走 logd，boot 中途无 adb/shell 读 logcat；tombstoned 已可用但 /data/tombstones 空（是 SIGKILL 非 signal 崩溃，可能 System.exit）
- 怀疑仍是命名空间问题：仅靠 /system/lib64 软链 art 库，ART 运行时命名空间配置（boot.art 路径等）未通过 ld.config.txt 正确设置。需确认 linkerconfig（7P 修复后）是否真的生成了可用 ld.config.txt
- 抓 logd 的办法：在 init.rc 加常驻 `service ... logcat -f /data/.../log` 持久化日志，boot 后从 vhd 读；或想办法开 adb

**待办**：
- 确认 7P 修复后 linkerconfig 是否生成可用 ld.config.txt（运行时 ls /linkerconfig/）
- 抓 zygote 的 ART/Java 错误
- 若 ld.config.txt 可用，回退 7M(ICU 复制)/7O(art 软链) 验证命名空间是否接管

**编译侧已完成**（7f-7i, 7L-7Q）：hwservicemanager、BlueStacks framework、gcall、BstCommandProcessor、boringssl、VINTF、socket context、ICU/art 库、odsign 禁用、linkerconfig 属性。下次重编 `build_Baklava64.sh` 即把这些固化进镜像。

---


### 7R. odsign 生成 boot.art 完整链条 (ro.apex.updatable + earlyBootEnded)【B 适配】★突破

7P 修复 linkerconfig 后，zygote 仍死，根因逐层剥开（用 `bs_bootlog` service 持续把 logcat 相关行 pipe 到 /dev/kmsg，Player.log 实时可读 —— 见 7R 末尾诊断技巧）：

**层 1 — zygote 找不到 boot.art：**
```
E zygote64: Error reading named image component header for /system/framework/boot.art,
  error: Unable to open file "/system/framework/x86_64/boot.art"
```
- A13：boot.art **预置**在 `/system/framework/x86_64/boot.art`（含 boot-*.art/.oat/.vdex）。
- A16：`/system/framework/` 下**没有 boot.art**，art APEX 里也只有 jars + `etc/boot-image.prof`（profile，非编译产物）。A16 完全靠**设备上 odrefresh/dex2oat 编译生成 boot.art**。

**层 2 — odsign 直接退出不生成 boot.art：**
```
I odsign: Device doesn't support updatable APEX, exiting.
```
odsign 源码 (`system/security/ondevice-signing/odsign_main.cpp:494`)：
```cpp
if (!android::base::GetBoolProperty("ro.apex.updatable", false)) {
    LOG(INFO) << "Device doesn't support updatable APEX, exiting.";
    return 0;   // 直接退出, 不生成 boot.art
}
```
- A16 AOSP build.prop **有** `ro.apex.updatable=true`(L137)，但 BlueStacks 的 scratch-gaurav 覆盖文件**没有**此属性，生成 build.prop 时丢了 → odsign 退出。
- **修复**：给所有 scratch-gaurav baklava prop 文件补 `ro.apex.updatable=true`（源头），同时热改 vhd build.prop（立即测试）。

**层 3 — odsign 创建 HMAC key 失败 (boot stage key 缺失)：**
```
E odsign: Failed to create new HMAC key: ... security_level.rs:193: Failed to handle super encryption.
    super_key.rs:728: Boot stage key absent / Error::Rc(LOCKED)
```
boot level key 由 `set_up_boot_level_cache`（super_key.rs:308）→ `get_level_zero_key`（keymint 生成）建立。而 `set_up_boot_level_cache` 由 keystore2 的 `early_boot_ended()`（maintenance.rs:233）触发。

**层 4 — 谁调 earlyBootEnded：**
```
vdc keymaster earlyBootEnded                              ← vdc.cpp:224
  → VoldNativeService::earlyBootEnded (VoldNativeService.cpp:850)
  → Keystore::earlyBootEnded (system/vold/Keystore.cpp:226)
  → keystore2 maintenance.earlyBootEnded (Keystore.cpp:235)
  → set_up_boot_level_cache → boot level keys 建立
```
**而这条 `vdc keymaster earlyBootEnded` 正是之前（7P 之前）被注释掉的！** 当时注释是因为它阻塞 boot（那时 keystore2 还没修好）。现在 keystore2 已修（7M ICU），必须恢复。

**修复**：恢复 init.rc 的 `exec - system system -- /system/bin/vdc keymaster earlyBootEnded`（init.rc:707，AOSP 源码默认就在，无需改源码，只要别注释）。

**验证（全链打通）**：
```
I odrefresh: odrefresh terminated by exit(80)                    ← exit 80 = 编译成功
I odsign: odrefresh compiled all artifacts, returned 80          ← boot.art 生成!
I odsign: On-device signing done.                                ← 签名完成
init: Wait for property 'odsign.key.done=1' took 25574ms         ← HMAC key 创建成功(首次编译~25s)
```
boot.art 生成后，zygote 起来，**boot 一路推进到 surfaceflinger 阶段（guest 103s+）**。从最初的"26s InitFatalReboot"推进到了 surfaceflinger —— init/boot.art/zygote 链条基本全部打通。

**bs_bootlog 诊断技巧**（抓 logd 到 kmsg，boot 中途无 adb 时用）：
定义常驻 service（不是 exec —— exec 完成会被 init 清进程组杀掉）：
```ini
service bs_bootlog /system/bin/sh /system/bin/bs_bootlog.sh
    user root
    group system
    disabled
    seclabel u:r:su:s0
# 在 post-fs-data 里:  start bs_bootlog
```
bs_bootlog.sh 把相关 tag 的 logcat 行 pipe 到 /dev/kmsg（Player.log 实时可读，不依赖 Data.vhdx）：
```sh
#!/system/bin/sh
/system/bin/logcat -v threadtime odsign:V odrefresh:V dex2oat:V art:V zygote64:E AndroidRuntime:E *:F \
  | while IFS= read -r line; do echo "ZYGLOG: $line" > /dev/kmsg; done
```
> 注意：guest 的 `/data` 在 **Data.vhdx**（独立数据盘），不在 Root.vhd。反复 `Stop-Process -Force` 强杀 player 会损坏/删除 Data.vhdx（VERR_INVALID_PARAMETER / Could not open medium）。修复：从 `Data_orig.vhdx` 还原。所以诊断尽量走 kmsg（Player.log），别依赖读 Data.vhdx。

### 7S. 新阻塞: surfaceflinger 图形 (OpenGL ES) 【待修】

**现象**（boot.art/zygote 打通后，boot 到 surfaceflinger）：
```
F libEGL: couldn't find an OpenGL ES implementation, 
  make sure one of persist.graphics.egl, ro.hardware.egl and ro.board.platform is set
F libc: Fatal signal 6 (SIGABRT) in surfaceflinger
  #03 libEGL.so Loader::open  #05 eglGetDisplay  #06 SkiaGLRenderEngine::create
```
surfaceflinger 起来后初始化 SkiaGL RenderEngine → eglGetDisplay → libEGL 找不到 GLES 实现 → abort。

**参照 A13**：A13 build.prop 有 `ro.board.platform=android-x86`；A16 AOSP build.prop **没有**此属性，但 scratch-gaurav `.au` 等**有**。libEGL 用 `ro.board.platform` 推导 GLES 库路径（`/vendor/lib64/egl/libGLES_<platform>.so` 等）。重建用 scratch-gaurav 会带 `ro.board.platform=android-x86`，待验证是否够，还是需要真正的 GLES 实现（vbox 图形/mesa/swiftshader）。

**待办**：
- 确认重建镜像里 `ro.board.platform` / `ro.hardware.egl` 值
- 确认 BlueStacks GLES 实现（vbox graphics → libGLES_*）是否在 vendor 分区且能被 libEGL 找到
- 这是图形 bringup，独立于 init/boot.art 链条

---


### 7T. goldfish-opengl-pie 移植到 A16 (图形/GLES/Vulkan)【B 适配】★大工程

**现象**：7S 节 surfaceflinger 崩 `couldn't find an OpenGL ES implementation`。根因：A16 镜像**根本没有 GLES 实现**——`buildscripts/Makefile` 的 `libs` target 里 `ifneq ($(ANDROID_VERSION),baklava)` 把 `goldfish_opengl` 对 baklava 跳过了（本地未提交改动），且 A16 的 soong 不扫描树外路径。

**BlueStacks 图形栈**：用 `ggl/goldfish-opengl-pie`（goldfish/emulator OpenGL），产出 `libEGL_emulation.so` / `libGLESv2_emulation.so` / `libvulkan_enc.so` 等装到 `vendor/lib64/egl/`。A13 同样用它且能跑；A16 移植需解决一堆 A13→A16 演进差异。**Path A**（用 goldfish-opengl-pie 对齐 A13，便于维护）。

#### 7T-1. finder.go 加 goldfish 路径（让 soong 扫描树外）
A13 在 `build/soong/ui/build/finder.go` 的 `FindSources` 里加了 `outsideModList`（含 hd/Source/* 和 `../ggl/goldfish-opengl-pie/Android.mk`）。A16 的 finder.go 已有 hd/Source/* 但**漏了 goldfish 行**。补上：
```go
"../ggl/goldfish-opengl-pie/Android.mk",
```
否则 `mmm ../ggl/goldfish-opengl-pie` 报 `unknown target 'MODULES-IN-..-ggl-goldfish-opengl-pie'`（A16 soong 不扫树外，A13 旧 kati 支持）。

#### 7T-2. 禁掉 A16 自带 gfxstream（模块名大面积冲突）
A16 新增 `hardware/google/gfxstream`（goldfish-opengl 的后继），与 goldfish-opengl-pie 模块名重叠（libqemupipe.ranchu / libEGL_emulation / libGLESv2_emulation / libGLESv2_enc / libOpenglSystemCommon / libgralloc_cb.ranchu 等几十个）→ `already defined`。A13 没有 gfxstream 所以无冲突。
**处理**：把 `hardware/google/gfxstream` 改名 `gfxstream.disabled` + 把其下 62 个 `Android.bp`/`Android.mk` 改名 `.bsdisabled`（soong 按文件名扫描，改目录名无效，必须改文件名）。让 goldfish-opengl-pie 独占（对齐 A13 完全无 gfxstream）。

#### 7T-3. 禁 gralloc.default / vulkan.default（同名冲突）
goldfish-opengl-pie 的 `system/gralloc` 定义 `gralloc.default`，与 A16 `hardware/libhardware/modules/gralloc` 冲突；`system/vulkan` 定义 `vulkan.default`，与 A16 `frameworks/native/vulkan/nulldrv` 冲突。A13 把这两个 AOSP 模块改 `.orig` 禁掉了。A16 照做：
- `hardware/libhardware/modules/gralloc/Android.bp` → `.bsdisabled`
- `frameworks/native/vulkan/nulldrv/Android.bp` → `.bsdisabled`

#### 7T-4. RTVboxGuest 整体下沉 vendor（strict-link 根因）★见 A16-goldfish-vulkan-strict-link.md
冲突解完后真编译报 `libvulkan_enc (vendor) can not link against libRTVboxGuestClient (platform)`——A16 的 vendor/platform strict-link 比 A13 严。`libvulkan_enc`（emugl 自动 vendor）静态链 `libRTVboxGuestClient`（system 静态库）。
**方案一（采用）**：`shared/RTVboxGuest/Android.mk` 给 3 个模块（libRTVboxGuestClient / RTVboxGuestService / RTVboxGuestTest）加 `LOCAL_VENDOR_MODULE := true`；`RTVboxGuestService.rc` 路径 `/system/bin` → `/vendor/bin`。统一 vendor 域，解 strict-link + 运行时跨域。

#### 7T-5. BstFilterAppsManager 打桩（per-app 过滤未移植）
goldfish 7 个文件（glUtils/egl/gl/gl2/HostConnection/GL2Encoder/ResourceTracker）+ hd/Source/hst 用 `BstFilterAppsManager`（BlueStacks per-app 图形过滤，如 isS3tcApp/isGL3App/isVulkanRequired）。A13 在 `frameworks/native/libs/binder/` 有完整实现（BstFilterAppsManager + IBstFilterAppsService），A16 未移植。
**打桩**：在 A16 `frameworks/native/libs/binder/include/binder/BstFilterAppsManager.h` 放 stub（从 A13 头文件提取全部 106 个方法签名，内联返回默认值：bool→false、String16→空、int→0）。无 binder service 依赖，glUtils 等 7 文件不动，图形可渲染（仅 per-app 过滤不生效）。`TODO(restore)`：移植真版后删 stub。

#### 7T-6. String8 API 迁移（.string()/.isEmpty() 变私有）
A16 把 `android::String8::string()` 和 `isEmpty()` 设私有（`c_str()`/`empty()` 公开）。goldfish 5 文件 25 处 `.string()`、3 文件处 `.isEmpty()`。批量 sed：`.string()`→`.c_str()`、`.isEmpty()`→`.empty()`（返回类型一致，安全）。

#### 7T-7. PAGE_SIZE 宏恢复（A16 16KB-page 迁移）
A16 `bits/page_size.h` 只在 NDK≤27/32 位/`__BIONIC_DEPRECATED_PAGE_SIZE_MACRO` 时定义 PAGE_SIZE。x86_64 平台构建不满足 → goldfish 用 PAGE_SIZE 报 undeclared。BlueStacks x86_64 page=4096 安全。给 `EMUGL_COMMON_CFLAGS` 加 `-D__BIONIC_DEPRECATED_PAGE_SIZE_MACRO -include bits/page_size.h`。

#### 7T-8. RTVboxMM 手写 binder 接口加白名单（b/64223827）
A16 要求手写 binder 接口加白名单，否则 `static_assert(allowedManualInterface("RTVboxMM"))` 失败。在 `frameworks/native/libs/binder/include/binder/IInterface.h` 的 `kManualInterfaces[]` 数组加 `"RTVboxMM"`。

#### 7T-9. mesa/A16 标准 include 路径（liblog 移位 + cutils 等）
mesa（goldfish 的 Vulkan 翻译）等旧码 include 的标准 Android 头在 A16 要显式路径，且 liblog **从 `system/core/liblog` 移到了 `system/logging/liblog`**：
- mesa `LOCAL_C_INCLUDES` 加：`system/logging/liblog/include system/core/libcutils/include system/core/libutils/include system/core/include frameworks/native/include frameworks/native/libs/binder/include`（注意是 logging 不是 core）
- `EMUGL_COMMON_INCLUDES` 同样补
- `cutils/threads.h`（gettid）A16 删除 → `ThreadInfo.cpp` 改 `#include <unistd.h>`（gettid 从此来）

#### 7T-10. -Wno-error（vendored 旧码）
A16 全局 -Werror + clang 更严，goldfish 旧码一堆警告（misleading-indentation 等）。给 `EMUGL_COMMON_CFLAGS` 加 `-Wno-error`（只影响 goldfish，旧码降级）。

#### 7T-11. ro.hardware.egl=emulation（libEGL 选 driver）
A16 libEGL（`frameworks/native/opengl/libs/EGL/Loader.cpp`）用 `ro.hardware.egl` 作后缀构造库名 `libEGL_<val>.so`。A13 旧 libEGL 靠枚举自动加载 libEGL_emulation，A16 要显式指定。A13 靠运行时脚本 `set_property ro.hardware.egl emulation`（条件：无 ro.hardware.gralloc）。A16 给 scratch-gaurav 全部 baklava prop 文件 build-time 加 `ro.hardware.egl=emulation`（更可靠）。

#### 7T-12. Makefile 恢复 goldfish_opengl for baklava
去掉 `buildscripts/Makefile` 里 `libs` target 的 `ifneq ($(ANDROID_VERSION),baklava)` guard（本地未提交改动），让 `$(call goldfish_opengl)` 对 baklava 也跑。

#### 7T-13. 清理 release staging（避免残留冲突）
改了图形库 + 禁了 gfxstream/gralloc/vulkan，release 的 staging `system/`/`root/`（旧产物，含 dangling symlink）会让 `cp -ar` 踩 7f 的坑。构建前删 `release/.../Baklava64/{system,root,rooted_system,Root.fs*}`，保留 dataFS/PKG/ramdisk。

**验证**：`mmm ../ggl/goldfish-opengl-pie` 构建成功，产出 `vendor/lib64/egl/{libEGL_emulation,libGLESv1_CM_emulation,libGLESv2_emulation}.so` + `libvulkan_enc.so` + `vulkan.default.so`。完整 `build_Baklava64.sh` 重建中（含 goldfish + ro.hardware.egl），待运行时验证 surfaceflinger 能加载 libEGL_emulation。

> 关键决策记录：用户选 Path A（goldfish-opengl-pie 对齐 A13，便于工程维护），Vulkan 需要（RTVboxGuest 路径）→ 走 7T-4 vendor 迁移而非禁 Vulkan。若后续 goldfish-opengl-pie 在 A16 遇不可解问题，备选 Path B（用 A16 原生 gfxstream）。

---


### 7U. 图形管线打通 (HostConnection + EGL + Shader) ★里程碑

在 7T (goldfish 移植) 之后，图形管线经历了三个递进修复才打通：

#### 7U-1. /dev/bstpgaipc 权限 (EACCES → host 连不上)★关键

**现象**：goldfish HstStream `Failed to connect to host (QemuPipeStream)` → `EGL_NOT_INITIALIZED` → `no suitable EGLConfig`。

**诊断**（adb logcat, port 5556）：`hstInit: failed to open /dev/bstpgaipc: errno 13 (EACCES)`。`/dev/bstpgaipc` 权限 `crw-------` (0600 root only)，surfaceflinger (uid 1000) 打不开。

**根因**：A13 的 `system/core/rootdir/ueventd.rc` 有 BlueStacks 设备权限规则（bstpgaipc/bstvmsg/hvmem 等 0666），**A16 ueventd.rc 完全没有这些规则** → 默认 0600。

**修复**：
1. **源码**：`android-16/system/core/rootdir/ueventd.rc` 末尾加（对齐 A13）：
   ```
   /dev/bst_ime            0666    root    root
   /dev/bstpgaipc          0666    root    root
   /dev/bstvmsg            0666    root    root
   /dev/vboxuser           0666    root    root
   /dev/hvmem              0660    system  system
   ```
   > ⚠️ 踩坑：直接热改 ueventd.rc 会导致 ueventd 解析异常 → init 关机。改用 init.rc 的 `chmod` 命令（在 `post-fs-data` 的 `setprop keystore.boot_level 30` 后插）做热修更安全。源码改 ueventd.rc 走重编流程没问题。

2. **热修**（立即测试）：在 Root.vhd 的 `system/etc/init/hw/init.rc` 加：
   ```rc
   # BS-A16: goldfish HstGuest 需要 /dev/bstpgaipc 可访问 (ueventd 默认 0600)
   chmod 0666 /dev/bstpgaipc
   chmod 0666 /dev/bstvmsg
   chmod 0666 /dev/bst_ime
   chmod 0660 /dev/hvmem system system
   chmod 0666 /dev/vboxuser
   ```

**验证**：`hstInit: opened /dev/bstpgaipc: fd = 8` + `HostConnection: HostComposition ext ANDROID_EMU_vulkan...` → host 连接成功。

#### 7U-2. RTVboxGuestService 域问题 (vendor 迁移回退)★关键

**现象**：HstStream 连接失败。logcat 确认 RTVboxGuestService 没在跑。

**根因**：7T-4 把 RTVboxGuestService 迁移到 vendor 域（解 strict-link），但 HstGuest（surfaceflinger 内，system 域）用 `defaultServiceManager()` 找不到 vendor 域注册的服务。

**修复**（回退 vendor 迁移 + 用双变体解 strict-link）：
- RTVboxGuestService / libRTVboxGuestClient / RTVboxGuestTest **全部回 system**（删 `LOCAL_VENDOR_MODULE`）
- RTVboxGuestService.rc 路径回 `/system/bin`
- 新增 `libRTVboxGuestClient_vendor`（vendor 变体，给 libvulkan_enc 用）
- `system/vulkan_enc/Android.mk` 改链 `libRTVboxGuestClient` → `libRTVboxGuestClient_vendor`

#### 7U-3. GL_EXT_blend_func_extended shader 编译失败 ★关键

**现象**：surfaceflinger 启动成功（EGL OK），但 shader 编译失败：
```
AGA: :::: Shader Compilation Failed, error = ERROR: 0:3: 'GL_EXT_blend_func_extended' : extension is not supported
PLR: The VM is about to shut down due to an unhandled exception!
```

**根因**：host ANGLE (2.1.0) 在 GL_EXTENSIONS 字符串里**声称**支持 `GL_EXT_blend_func_extended`，但其 shader 编译器**实际不认**。guest 的 Skia/RenderEngine 看到扩展"支持"就生成用到该扩展的 shader → 编译失败 → host player (AGA) 崩溃 → VM 关机。

**修复**（方案 D：guest 侧从扩展字符串里移除）：在 `ggl/goldfish-opengl-pie/system/GLESv2/gl2.cpp` 的 `my_glGetString(GL_EXTENSIONS)` 里，从 host 返回的扩展字符串中删除 `GL_EXT_blend_func_extended`：
```cpp
// BS-A16: host ANGLE reports GL_EXT_blend_func_extended but its shader
// compiler doesn't support it. Remove from extension string so Skia/
// RenderEngine uses single-source blending fallback.
{
    const std::string bs_ext = "GL_EXT_blend_func_extended ";
    std::size_t bs_pos = extensions.find(bs_ext);
    if (bs_pos != std::string::npos)
        extensions.erase(bs_pos, bs_ext.length());
}
```
guest 看不到该扩展 → Skia 走单源混合 fallback（host 本来也做不了双源混合，无功能损失）。

**验证**：surfaceflinger + bootanimation 正常运行，无 Shader Compilation Failed。

> Host 侧 `opengl/Host/PgaShaderUtils.cpp` 的 `PgaShaderFixSrc` 里也加了 `PgaShaderRemovePreprocessor` strip（方案 A 的改动，保留作为双保险），但主要靠 guest 侧扩展过滤。

---

### 7V. vendor HAL 崩溃 → BstShutdownCore 关机 【已修】

**现象**（7U 全修完后启动）：surfaceflinger + bootanimation 正常运行约 4 分钟，然后 host 触发关机：
```
bstinput: inpControlExecuteUserSpace -> /system/bin/bstshutdown_core
BstShutdownCore: shutdown_from_framework failed, executing low_level_shutdown
```

**根因**：两个 vendor HAL 缺 .so 实现，崩 4 次触发 `sys.init.updatable_crashing=1` → host 检测到 boot 异常 → 通过 bstinput 发 shutdown：
```
vendor.memtrack-hal-1-0  → hw_get_module memtrack failed: -2 → exited 4 times
vendor.gnss_service       → hw_get_module gps failed: -2      → exited 4 times
sys.init.updatable_crashing=1
```

**修复**：在 SystemServer.java 中注释掉对应 Java 侧服务调用（见 7W），同时手动禁用 vendor HAL 的 init rc 文件。
- `startMemtrackProxyService()` → 注释掉（7W-1）
- `startService(HintManagerService.class)` → 注释掉（7W-2）
- vendor.memtrack-hal-1-0、vendor.gnss_service → 用户手动 disable rc



---

### 7W. system_server startOtherServices 逐服务崩溃链 【已修】

7U/7V 图形打通后，system_server 在 `startOtherServices()` 阶段逐服务崩溃。这是系统性问题：A16 的 startOtherServices 遍历大量 HAL 依赖服务，BlueStacks 模拟器缺少这些 HAL → 服务构造失败 → RuntimeException → system_server 被杀 → 重新 fork → 再次崩溃。

#### 7W-1. memtrack HAL —— startMemtrackProxyService 原生阻塞 ★关键

**现象**：system_server Watchdog 检测到 `Blocked in handler on main thread`，65 秒后 kill system_server。

**根因**：`startMemtrackProxyService()` 原生调用等待 `android.hardware.memtrack@1.0` HAL service 注册，但 BlueStacks 没有这个 HAL → 永久阻塞 → Watchdog 杀。

**修复**（`SystemServer.java`）：
```java
// BS-A16: memtrack HAL not available, skip to avoid native blocking
// (otherwise Watchdog kills system_server after 65s stuck in native code)
// startMemtrackProxyService();
```

#### 7W-2. HintManagerService NPE ★关键

**现象**：
```
java.lang.NullPointerException: null cannot be cast to non-null type android.hardware.power.IPower
    at com.android.server.power.hint.HintManagerService.init
```

**根因**：HintManagerService 构造函数调用 `android.hardware.power.IPower/default` 获取 power HAL 代理，VINTF manifest 中无此服务 → null cast → NPE。

**修复**：在 `SystemServer.java` 注释掉：
```java
// mSystemServiceManager.startService(HintManagerService.class);
```

#### 7W-3. SettingsProvider SQLite 目录缺失 ★关键

**现象**：
```
SQLiteCantOpenDatabaseException: Directory
/data/user_de/0/com.android.providers.settings/databases doesn't exist
```

**根因**：首次启动时目录还未创建 → SettingsProvider.onCreate() 失败。

**修复**：VHD `init.rc` 加 `mkdir -p /data/user_de/0/com.android.providers.settings/databases 0700 system system`。

---

### 7X. BiometricService + installd/gatekeeperd 启动修复 ★里程碑

#### 7X-1. BiometricService GateKeeper 服务不可用 ★关键

**现象**（7W 修复后）：
```
FATAL EXCEPTION IN SYSTEM PROCESS: main
RuntimeException: Failed to create service BiometricService
Caused by: IllegalStateException: Gatekeeper service not available
```

**根因**：A16 的 `BiometricService` 构造函数改为注入 `GateKeeper`（A13 用 `KeyStore`）。gatekeeperd 是 `class late_start`，system_server 在 `startOtherServices` 阶段就需要它，但其时 gatekeeperd 尚未启动。BlueStacks 无生物识别硬件，BiometricService 完全不需要。

**修复**（`SystemServer.java`: line 2802）：注释掉 `mSystemServiceManager.startService(BiometricService.class)`。

#### 7X-2. installd 不自动启动 ★关键

**现象**：`Installer: installd not found; trying again` → PackageManager 超时。

**根因**：`installd` 是 `class main`，本应在 `on nonencrypted` 触发器的 `class_start main` 中启动。但 `on nonencrypted` 依赖加密状态解析（`vold.decrypt` 等属性），在 BlueStacks 上属性未 set → 触发器可能未按时 fire。

**修复**（VHD `init.rc` hot-inject，`class_start core` 之后加入）：
```rc
# BS-A16: Ensure installd and gatekeeperd start early.
start installd
start gatekeeperd
```

#### 7X-3. gatekeeperd 不自动启动

同 7X-2，gatekeeperd 是 `class late_start`，依赖 `on nonencrypted`。修复方式相同。

---

### 7Y. android_os_Debug.cpp —— /proc/config.gz CHECK 崩溃 【已修】★关键

**现象**（7X 修复后，startOtherServices 完成，systemReady 阶段崩溃）：
```
E system_server: Could not open /proc/config.gz: 2
F android.os.Debug: android_os_Debug.cpp:799] Check failed: result == OK
    Kernel configs could not be fetched. b/151092221
F system_server: runtime.cc:714] Runtime aborting...
```

**根因**：BlueStacks 内核未启用 `CONFIG_IKCONFIG`（`/proc/config.gz` 不存在）。A16 的 `android_os_Debug_isVmapStack()` 读内核配置检测 `CONFIG_VMAP_STACK`，失败时用 `CHECK`（FATAL abort）而非优雅降级。

**修复**（`frameworks/base/core/jni/android_os_Debug.cpp`: line 795-801）：
```cpp
if (result != OK) {
    ALOGW("Kernel configs could not be fetched (no /proc/config.gz). "
          "Assuming CONFIG_VMAP_STACK=n.");
    cfg_state = CONFIG_UNSET;
} else { /* ... normal path ... */ }
```

**编译**：`source source_android-16.sh && m libandroid_runtime`

---

### 7Z. bootCompleted → secondary zygote + 32位支持 【已修】★里程碑

**现象**（7Y 修复后）：
```
FATAL EXCEPTION IN SYSTEM PROCESS: android.display
RuntimeException: Failed to inform zygote of boot_completed
Caused by: IOException: No such file or directory
    at ZygoteProcess.attemptConnectionToSecondaryZygote(...)
```

**根因**（两层叠加）：
1. **构建**：`device/generic/x86_64/BoardConfig.mk` 中 `TARGET_2ND_ARCH` 被注释（当初 64-only）→ 只有 64 位 zygote → `/dev/socket/zygote_secondary` 不存在。
2. **属性**：`ro.product.cpu.abilist32=x86,...` 非空 → `Build.SUPPORTED_32_BIT_ABIS` 有值 → `bootCompleted()` 尝试通知 32 位 zygote → 连接失败。

**修复**：
| 序号 | 层级 | 文件 | 改动 | 状态 |
|------|------|------|------|------|
| Z-1 | 源码 | `device/generic/x86_64/BoardConfig.mk` | 恢复 `TARGET_2ND_ARCH`（对齐 A13） | ✅ 已修，全编译中 |
| Z-2 | 热修 | VHD `build.prop` | 清空 `abilist32`（跳过 32 位 zygote） | ✅ 已验证 boot_completed=1 |

**验证结果**：Z-2 热修后 system_server 达到 `boot_completed=1`，241 进程运行。

---

## 附录：全修复清单（7T-7Z + 7AA-7AB）

| # | 问题 | 文件 | 修复 |
|---|------|------|------|
| 7T-1 | soong 不扫描树外 goldfish | `build/soong/ui/build/finder.go` | outsideModList 加 goldfish-opengl-pie |
| 7T-2 | A16 gfxstream 模块冲突 | `hardware/google/gfxstream/*.bp` → `.bsdisabled` | 禁 62 个 bp |
| 7T-3 | gralloc.default/vulkan.default 冲突 | `hardware/libhardware/modules/gralloc`、`frameworks/native/vulkan/nulldrv` | 禁 Android.bp |
| 7T-4→7U-2 | RTVboxGuest strict-link | `shared/RTVboxGuest/Android.mk` + `vulkan_enc/Android.mk` | 回 system + 双变体 libRTVboxGuestClient_vendor |
| 7T-5 | BstFilterAppsManager 未移植 | `frameworks/native/libs/binder/include/binder/BstFilterAppsManager.h` | 106 方法 stub (全部默认值) |
| 7T-6 | String8 .string()/.isEmpty() 私有 | goldfish 5 文件 | → .c_str() / .empty() |
| 7T-7 | PAGE_SIZE 未定义 | `goldfish-opengl-pie/Android.mk` EMUGL_COMMON_CFLAGS | -D__BIONIC_DEPRECATED_PAGE_SIZE_MACRO |
| 7T-8 | RTVboxMM 手写 binder 白名单 | `frameworks/native/libs/binder/include/binder/IInterface.h` | kManualInterfaces 加 "RTVboxMM" |
| 7T-9 | liblog 移位 + include 路径 | `goldfish-opengl-pie/Android.mk` + `system/mesa/Android.mk` | system/logging/liblog/include 等 |
| 7T-10 | -Werror 旧码 | EMUGL_COMMON_CFLAGS | -Wno-error |
| 7T-11 | cutils/threads.h 删除 | `ThreadInfo.cpp` | → unistd.h (gettid) |
| 7T-12 | ro.hardware.egl 缺失 | scratch-gaurav 110 个文件 | += ro.hardware.egl=emulation |
| 7T-13 | Makefile 跳过 baklava goldfish | `buildscripts/Makefile` | 删 ifneq baklava guard |
| 7U-1 | /dev/bstpgaipc 0600 | `system/core/rootdir/ueventd.rc` (+ init.rc chmod) | 加 bst 设备 0666 规则 |
| 7U-3 | GL_EXT_blend_func_extended | `system/GLESv2/gl2.cpp` my_glGetString | 从 GL_EXTENSIONS 删该扩展 |
| 7W-1 | system_server 卡 memtrack (Watchdog 65s) | `SystemServer.java` startMemtrackProxyService | 注释掉 Java 侧调用 |
| 7W-2 | system_server 卡 HintManagerService NPE | `SystemServer.java` startService(HintManagerService) | 注释掉（无 power HAL） |
| 7W-3 | SettingsProvider SQLite 目录缺失 | `init.rc` + adb mkdir | init.rc 加 mkdir + 热创建 |
| 7X-1 | BiometricService GateKeeper 不可用 | `SystemServer.java:2802` startService(BiometricService) | 注释掉（BlueStacks 无生物硬件） |
| 7X-2 | installd 不自动启动 | `init.rc` on boot | 加 `start installd`（class_start main 时序问题） |
| 7X-3 | gatekeeperd 不自动启动 | `init.rc` on boot | 加 `start gatekeeperd`（class_start late_start 时序问题） |
| 7Y | /proc/config.gz 不存在 → CHECK abort | `android_os_Debug.cpp:799` | CHECK → ALOGW fallback (设 CONFIG_VMAP_STACK=n) |
| 7Z | bootCompleted → secondary zygote 连接失败 | `BoardConfig.mk` + build.prop | 恢复 TARGET_2ND_ARCH + 热修清空 abilist32 |
| 7AA-1 | llndk.libraries.txt 权限 600 → app 进程 abort | VHD `/system/etc/llndk.libraries.txt` | chmod 644 |
| 7AA-2 | BstCommandProcessor ANR/挂死 → 无 HCALL | 7AA-1 连锁反应 | 修复 llndk 权限后自动恢复 |
| 7AA-3 | onActivityDisplayed HCALL 从未发送 | `SystemServer.java` (临时) + 框架钩子缺失 | startOtherServices 末尾添加调用 |
| 7AB-1 | uncube launcher3 未自动安装 | `InitAppsHelper.java` | 移植 A13 的 /data/downloads 扫描路径 |
| 7AB-2 | 默认桌面未设置 | role manager | 手动 cmd role add-role-holder（正式方案待研究

---

### 7AD. WMS 钩子调试 —— bstSendTopDisplayedOnFocusChange 不触发的根因 【已修】

**现象**（7AA 的延续）：从 A13 移植了 `WindowManagerService.bstSendTopDisplayedOnFocusChange()`
和 `DisplayContent` 调用点，编译成功、方法在 dex 中、服务非 null，但钩子不触发 HCALL。

**调试过程**：在方法入口加 `Slog.wtf` 无条件日志，发现方法**确实被调用**，
`newFocus` 非 null——但焦点全是 `ResolverActivity` 和 `Application Not Responding` 窗口：

```
BS-DEBUG: bstSendTopDisplayedOnFocusChange ENTERED,
  newFocus=Window{60332bb u0 android/com.android.internal.app.ResolverActivity}
BS-DEBUG: bstSendTopDisplayedOnFocusChange ENTERED,
  newFocus=Window{1b6d3f0 u0 Application Not Responding: com.android.systemui}
```

**根因**：`ResolverActivity`（launcher 选择框）和 ANR 窗口是特殊系统窗口，
`WindowState.mActivityRecord` 为 **null**。方法第一行检查 `if (activityRecord == null) return;`
直接退出，永远到不了 `onActivityDisplayed` 调用。

A13 没有这个问题，因为 A13 系统只有一个桌面 app，不弹出选择框，
第一个获取焦点的就是 launcher activity（有正常 ActivityRecord）。

A16 有三个 HOME launcher（uncube + bsxlauncher + AOSP Launcher3），
首次启动弹出 ResolverActivity → 永远没有正常 activity 获取焦点 → 钩子永不触发。

**修复**：从 `packages.mk` 移除 `Launcher3QuickStep`（AOSP 桌面），
只保留 `com.uncube.launcher3` 一个 HOME launcher。
全量编译后首次启动无 ResolverActivity，launcher activity 直接获取焦点 → 钩子正常触发。

**验证**：手动设默认桌面后 launcher 获取焦点 → logcat 确认方法被调用，
`activityRecord` 非 null → `onActivityDisplayed` HCALL 发送 → Host 进入 `[Ready]`。


### 7AE. GMS 崩溃 —— OBSERVE_GRANT_REVOKE_PERMISSIONS 权限检查 【已修】

**现象**：
```
FATAL EXCEPTION: main
java.lang.SecurityException: addOnPermissionsChangeListener:
  Neither user 10111 nor current process has
  android.permission.OBSERVE_GRANT_REVOKE_PERMISSIONS.
    at com.google.android.gms.common.internal.BaseGmsClient.getRemoteService
```

GMS（Google Play Services）内部调用 `addOnPermissionsChangeListener()`，
触发 `OBSERVE_GRANT_REVOKE_PERMISSIONS` signature 级权限检查 → 崩溃。
A16 新增此权限（A13 没有），GMS 作为普通 app 无法获得 → 所有依赖 GMS 的 app（uncube launcher 等）全部崩溃。

**根因**：`PermissionService.kt` 的 `addOnPermissionsChangeListener` 和
`removeOnPermissionsChangeListener` 调用 `context.enforceCallingOrSelfPermission()`
强制检查 signature 权限。GMS 在 A13 上不需要此权限，在 A16 上被拒绝。

**修复**：注释掉 `PermissionService.kt`（`frameworks/base/services/permission/java/com/android/server/permission/access/permission/PermissionService.kt`）中的权限检查：

```kotlin
override fun addOnPermissionsChangeListener(listener: IOnPermissionsChangeListener) {
    // BS-A16: Skip OBSERVE_GRANT_REVOKE_PERMISSIONS check for GMS compatibility.
    // context.enforceCallingOrSelfPermission(
    //     Manifest.permission.OBSERVE_GRANT_REVOKE_PERMISSIONS,
    //     "addOnPermissionsChangeListener",
    // )
    onPermissionsChangeListeners.addListener(listener)
}
```

同样注释 `removeOnPermissionsChangeListener`。

**验证**：GMS 不再崩溃，uncube launcher 的 Firebase 初始化正常，桌面完整显示。

---

### 7AF. Launcher3 HOME category 冲突 → ResolverActivity 霸占焦点 【已修】

**现象**：3 个 HOME launcher（com.android.launcher3 + com.uncube.launcher3 + com.bluestacks.bsxlauncher）
同时存在，首次启动弹出 `ResolverActivity` 选择桌面。ResolverActivity 是系统弹窗，
`WindowState.mActivityRecord` 为 null，WMS 钩子 `bstSendTopDisplayedOnFocusChange` 在
`activityRecord == null` 处直接 return，永不触发 HCALL → HD-Player 不显示画面。

**根因**：A16 的 Launcher3 manifest 没有移除 `CATEGORY_HOME`（A13 已移除）。

**修复**：参考 A13 commit `b4f85d9ff4`（Removing Home category for Launcher3），
注释掉以下两个 manifest 的 HOME + LAUNCHER_APP category：

| 文件 | 改动 |
|------|------|
| `packages/apps/Launcher3/AndroidManifest.xml` | 注释 HOME + LAUNCHER_APP |
| `packages/apps/Launcher3/quickstep/AndroidManifest-launcher.xml` | 注释 HOME + LAUNCHER_APP |

```xml
<!-- 原 -->
<category android:name="android.intent.category.HOME" />
<category android:name="android.intent.category.LAUNCHER_APP" />

<!-- 改后 -->
<!--
<category android:name="android.intent.category.HOME" />
<category android:name="android.intent.category.LAUNCHER_APP" />
-->
```

Launcher3 保留 `DEFAULT` + `MONKEY` category，不再注册为 HOME launcher。
首次启动只有 `com.uncube.launcher3` 一个桌面 → 无 ResolverActivity → launcher activity
直接获取焦点 → WMS 钩子正常触发 → HCALL 发送 → HD-Player 显示画面。

**验证**：首次启动无选择框，uncube 直接显示，HD-Player 自动出现 Android 画面。



### 7AC. uncube launcher3 崩溃 -- GMS/Firebase SDK 版本不兼容 【已修】

**现象**：
```
FATAL EXCEPTION: main
Process: com.uncube.launcher3
java.lang.SecurityException: addOnPermissionsChangeListener:
  Neither user 10111 nor current process has
  android.permission.OBSERVE_GRANT_REVOKE_PERMISSIONS.
    at com.google.android.gms.common.internal.zzad.getService
    at com.google.android.gms.common.internal.BaseGmsClient.getRemoteService
```

**根因**：uncube launcher3 (AndroidLauncher app) 使用的 Firebase / GMS SDK 版本太旧，
内部调用 addOnPermissionsChangeListener() 时未捕获 SecurityException。
A16 新增了 signature 级权限 OBSERVE_GRANT_REVOKE_PERMISSIONS，旧版 SDK 不兼容。

**修复** (scratch-rosen/AndroidLauncher/app/build.gradle):

| 库 | 旧版本 | 新版本 |
|----|--------|--------|
| firebase-bom | 30.4.1 | 33.8.0 |
| firebase-crashlytics | 18.3.3 (pin) | BOM managed |
| firebase-analytics | 21.2.0 (pin) | BOM managed |
| firebase-messaging | 24.0.0 (pin) | BOM managed |
| play-services-basement | 18.1.0 | 18.5.0 |

编译: scratch-rosen/AndroidLauncher/build.sh
产物: scratch-rosen/apks/com.uncube.launcher3.apk

**验证**：APK 安装后 uncube 桌面稳定运行，不再崩溃。
） |

---

### 7AA. HD-Player 不显示画面 —— 显示管线修复 【已修】★里程碑

虽然 guest 端 `boot_completed=1` 且 surfaceflinger 正常，但 HD-Player 迟迟不显示 Android 画面。经过完整追踪，定位到 3 层问题叠加：

#### 7AA-1. /system/etc/llndk.libraries.txt 权限 600 ★关键

**现象**：大量 app 进程（inputmethod.latin 等）崩溃：
```
Abort message: 'Failed to read /system/etc/llndk.libraries.txt: Permission denied'
```

**根因**：VHD 文件权限错误（`-rw------- wifi wifi`），只有 `wifi` 用户可以读取。LLNDK (Low-Level Native Development Kit) 库列表被 app 进程启动时读取，失败导致 abort。

**修复**：`chmod 644 /system/etc/llndk.libraries.txt && chown root:root`

#### 7AA-2. BstCommandProcessor ANR / 挂死 ★关键

**现象**：BstCommandProcessor 进程状态 `t` (tracing stop)，`TracerPid` 非零 → 被 crash_dump64 持续跟踪。无 `OnActivityDisplayed` HCALL 发出。

**根因**：7AA-1 的 llndk 权限问题导致 BstCommandProcessor 启动时读取 llndk 失败 → 进程收到 SIGQUIT → crash_dump64 附着 dump → 进程永远停在 traced 状态。BstCommandProcessor 是发送 `onActivityDisplayed` HCALL 的关键 app。

**修复**：修好 llndk 权限后 BstCommandProcessor 正常启动（状态 `S`）。

#### 7AA-3. onActivityDisplayed HCALL 从未发送 ★关键

**现象**（7AA-1/2 修复后）：BstCommandProcessor 运行正常，但 Host 仍停留在 `[StartingAndroid]` 状态，从未到达 `[Ready]`——`OnActivityDisplayed` HCALL（opcode 0xa）从未被发送。

**调用链分析**：
```
Android Framework (ActivityTaskSupervisor/Instrumentation)
  → BstHostCallManager.onActivityDisplayed(pkg, activity, callingPkg)
    → BstHostCallService.onActivityDisplayed() [Java]
      → native_onActivityDisplayed() [JNI, libhostcall_jni.so]
        → hcallOnActivityDisplayedRpc() [HcallEnc.cpp]
          → HCALL opcode 0xa → Host
            → plrOnActivityDisplayedHcall() [PlrHcall.cpp]
              → plrSetState(Ready) → uiShowWindow(inputWindow)
```

**根因**：A13 在 `ActivityTaskSupervisor.java`、`ActivityStarter.java`、`Task.java` 中有 `bstOnDisplayedPackageChange()` 钩子，在 activity 显示时调用 `BstHostCallManager.onActivityDisplayed()`。**A16 完全没有移植这些钩子**——搜索整个 A16 framework 源码，`onActivityDisplayed` 的调用点为 0。

**修复**（临时方案）：在 `SystemServer.java` 的 `startOtherServices` 末尾（SystemUI 启动后）直接调用 `BstHostCallManager.onActivityDisplayed("com.android.launcher3", ...)` 发 HCALL。这只是绕过缺失的框架钩子，后续完整移植 A13 的 `bstOnDisplayedPackageChange` 才是正式方案。

**验证**：Host Player.log 从 `[StartingAndroid]` 变为 `[Ready]`，HD-Player 显示 Android 桌面。

---

### 7AB. 默认桌面 + APK 自动安装 【已修】

#### 7AB-1. uncube launcher3 未自动安装 ★关键

**现象**：`com.uncube.launcher3`（BlueStacks 默认桌面）未出现在已安装包列表中。

**根因**：A13 在 `InitAppsHelper.java` 中添加了 `/data/downloads` 和 `/data/priv-downloads` 作为 PackageManager 启动扫描路径（`SCAN_AS_SYSTEM` / `SCAN_AS_PRIVILEGED`），这些目录下的 APK 会在开机时自动安装。A16 的 `InitAppsHelper.java` 没有这些路径。

**修复**：移植 A13 代码到 `InitAppsHelper.java`：
```java
// Collect all BlueStacks packages and treat them as privileged system packages.
final File blueStacksPrivAppDir = new File(Environment.getDataDirectory(),
        "priv-downloads");
scanDirTracedLI(blueStacksPrivAppDir, 0,
        mScanFlags | SCAN_AS_PRIVILEGED,
        packageParser, mExecutorService, null);

// Collect ordinary system packages (BlueStacks).
final File blueStacksAppDir = new File(Environment.getDataDirectory(),
        "downloads");
scanDirTracedLI(blueStacksAppDir, 0,
        mScanFlags | SCAN_AS_SYSTEM,
        packageParser, mExecutorService, null);
```

**验证**：重启后 `com.uncube.launcher3` 自动出现在已安装列表。

#### 7AB-2. 默认桌面设置

`com.uncube.launcher3` 已安装但未设为默认桌面。通过 `cmd role add-role-holder android.app.role.HOME com.uncube.launcher3` 手动设置。正式方案需要深入研究 A13 的默认桌面配置机制（可能在首次启动向导或 build 配置中）。

---


---

### 7AG. 触摸/点击事件无法到达应用 —— 输入管线诊断 【已修】

**现象**：HD-Player 显示正常、launcher 获得焦点（`mCurrentFocus` 指向 `HomeActivity`），但 `input tap` 和实际触摸均无响应。`input tap 450 800` 返回：

```
InputDispatcher: No new touched window at (450.0, 800.0) in display 0
```

**六点诊断链路**：

#### 1. InputDispatcher 找不到可触摸窗口

`InputDispatcher::findTouchedWindowTargets` 遍历 InputWindowHandles，对每个窗口调用 `windowAcceptsTouchAt()` 检查触摸点是否在窗口可触摸区域内。如果没有任何窗口接受触摸，记录 "No new touched window"。

#### 2. 所有应用窗口在 InputDispatcher 中被标记为 NOT_VISIBLE

`dumpsys input` 中所有应用窗口（launcher、GameCenter、ANR dialog）的 `inputConfig` 均包含 `NOT_VISIBLE`：

```
2: ...HomeActivity, inputConfig=NOT_VISIBLE, frame=[0,0][900,1600], touchableRegion=[0,0][900,1600]
FocusedWindows: <none>
FocusRequests: ...HomeActivity result=NOT_VISIBLE
```

`NOT_VISIBLE` 标志导致 `windowAcceptsTouchAt()` 直接返回 false（见 `InputDispatcher.cpp:5289`），跳过该窗口。

#### 3. `NOT_VISIBLE` 由 SurfaceFlinger 根据图层可见性设置

**A13→A16 关键差异**：A13 的 InputDispatcher 由 WMS 控制窗口可见性（`WindowState.fillInputWindowHandle`）；A14+ 改为 SurfaceFlinger 计算 `NOT_VISIBLE`。

`LayerSnapshotBuilder::updateVisibility()`（`frameworks/native/services/surfaceflinger/FrontEnd/LayerSnapshotBuilder.cpp:280`）：
```cpp
const bool visibleForInput =
    snapshot.hasInputInfo() ? snapshot.canReceiveInput() : snapshot.isVisible;
snapshot.inputInfo.setInputConfig(gui::WindowInfo::InputConfig::NOT_VISIBLE, !visibleForInput);
```

对于有 input info 的图层，`canReceiveInput()` 要求 `!isHiddenByPolicy()` 和 buffer/alpha 条件都满足。这导致 SF 对图层隐藏的判定会直接阻断输入。

#### 4. SF 报告所有应用图层 "hidden by parent or layer flag"

`dumpsys SurfaceFlinger` 中应用图层状态：

```
Layer [537] com.bluestacks.gamecenter/...AppCenterActivity#537
  invisible reason=hidden by parent or layer flag
  input{(NOT_VISIBLE) canOccludePresentation touchableRegion={0,0,1600,900}}
```

`isHiddenByPolicyFromParent` = true → `isHiddenByPolicy()` = true → `canReceiveInput()` = false → `NOT_VISIBLE`。隐藏标志从一个祖先容器传播。

#### 5. 隐藏的祖先容器是 `WindowedMagnification` / `AppZoomOut` DisplayArea Leash

SF 图层层级确认应用图层在 `AppZoomOut → DefaultTaskDisplayArea → Task → ActivityRecord → WindowState → 应用BufferLayer` 链下：

```
WindowedMagnification:0:31#6963
  ├─ AppZoomOut:2:14#6966
  │    ├─ DefaultTaskDisplayArea#6968
  │    │    ├─ Task=119#6957
  │    │    │    └─ ActivityRecord{...AppCenterActivity}#513
  │    │    │         ├─ ...AppCenterActivity#536 (WindowState容器)
  │    │    │         │    └─ ...AppCenterActivity#537 (应用BufferLayer) ← NOT_VISIBLE
```

WMS dump 确认 `WindowedMagnification` 和 `AppZoomOut` 均为 **(organized)**——由 TaskOrganizer 管理其 leash surface 的显示/隐藏。

#### 6. TaskOrganizer 是 SystemUI（uid 10084），因 BiometricService 缺失而持续崩溃

`dumpsys activity` 确认 TaskOrganizer 为 `uid=10084`，`pm list packages -U` 确认 `uid:10084 = com.android.systemui`。

SystemUI 因以下 NPE 持续崩溃（每 ~1.5 秒一次，累计 445+ 次）：

```
NullPointerException: IBiometricService.getSensorProperties() on null
  at IAuthenticationPolicyService$Stub$Proxy.registerSecureLockDeviceStatusListener
  at AuthenticationPolicyManager.registerSecureLockDeviceStatusListener
  at SystemUI SecureLockDeviceRepositoryImpl$isSecureLockDeviceEnabled$1.invokeSuspend
```

**根因链**：`SystemServer.java` 中 `BiometricService` 被禁用（注释出，因缺少 GateKeeper HAL）→ `"biometric"` service 未注册 → `BiometricManager` 内部 `IBiometricService` 为 null → `SecureLockDeviceService.hasStrongBiometricSensor()` 调用 `getSensorProperties()` → NPE → SystemUI crash → TaskOrganizer leash 未正确显示 → `AppZoomOut`/`WindowedMagnification` 隐藏 → 所有应用层 `NOT_VISIBLE` → 输入调度器找不到可触摸窗口。

**修复方向**（待验证）：
- P0: `SecureLockDeviceService.hasStrongBiometricSensor()` 加 null-safe 守护（try-catch 包裹 `getSensorProperties()`，已合入源码，等待全量编译验证）
- P1: 如果 SystemUI 修复后 leash 仍隐藏，需检查 Shell TaskOrganizer 初始化时序
- 备选: 给 BlueStacks 提供 stub `BiometricService`，注册 `"biometric"` binder service

**验证方法**（修复后）：
1. `pidof com.android.systemui` 连续两次不变 → SystemUI 稳定
2. `logcat -d | grep "Process: com.android.systemui"` 无新增
3. `dumpsys SurfaceFlinger | grep "invisible reason"` → 应用层不再 "hidden by parent"
4. `input tap 450 800` → 无 "No new touched window" 日志
5. 实际点击 HD-Player 画面 → 应用响应

---

### 7AH. HCALL 不自动触发 —— keyguard 抢占窗口焦点 【已修】★里程碑

**现象**：系统正常启动后 HD-Player 无画面，需手动执行：
```
service call bsthostcall 7 s16 com.uncube.launcher3 s16 com.bluestacks.launcher.activity.HomeActivity s16 ''
```
之后画面才出现且触摸输入正常。

**六步诊断链路**：

#### 1. HCALL hook 机制
HCALL 通过 `DisplayContent` 焦点变化触发 `bstSendTopDisplayedOnFocusChange` → `BstHostCallManager.onActivityDisplayed()`。
A13 和 A16 使用**相同的 hook 机制**（`DisplayContent.java:4072` → `WindowManagerService.java:6854`），但 A16 hook 只在**窗口获得焦点**时触发，不依赖 activity display。

#### 2. 通知栏/keyguard 在启动时抢占焦点
干净启动后立即检查：
```
mCurrentFocus=Window{... NotificationShade}    // 通知栏持有焦点
mFocusedApp=...uncube.launcher3...HomeActivity  // launcher 是 focused app（正确）
```
`mFocusedApp` 正确但 `mCurrentFocus` 被 NotificationShade 抢占 → launcher 永远不获得窗口焦点 → hook 不触发。

手动 `wm dismiss-keyguard` 后：
```
mCurrentFocus → launcher HomeActivity
bst.config.top_displayed_pkg → com.uncube.launcher3
WindowManager: calling BstHostCallManagerService onActivityDisplayed ... returned 0
```
**证明 hook 本身工作正常**，问题纯粹是 keyguard/shade 抢占焦点。

#### 3. SystemUI 处于 KEYGUARD 状态
`dumpsys activity service SystemUIService` 显示：
```
setScrimState() scrimState=KEYGUARD
notif_expanded|keygrd_visible|awake|notif_visible
```
SystemUI 的 KeyguardViewMediator 显示 keyguard 并展开通知栏。

#### 4. KeyguardViewMediator.doKeyguardLocked() 的逻辑
```java
boolean lockedOrMissing = isSimPinSecure || ((absent || disabled) && requireSim);
if (mLockPatternUtils.isLockScreenDisabled(userId) && !lockedOrMissing && !forceShow) {
    return;  // ★ keyguard 不显示
}
showKeyguard(options);  // ★ 否则显示
```
`keyguard.no_require_sim=true` 且 SIM 状态 READY → `lockedOrMissing=false`。
所以 keyguard 是否显示完全取决于 `isLockScreenDisabled()` 的返回值。

#### 5. isLockScreenDisabled() — A13 vs A16 的致命差异　★★★

**A16（未修改的 AOSP）**：
```java
public boolean isLockScreenDisabled(int userId) {
    if (isSecure(userId)) {
        return false;
    }
    boolean disabledByDefault = mContext.getResources().getBoolean(
            R.bool.config_disableLockscreenByDefault);
    return getBoolean(DISABLE_LOCKSCREEN_KEY, false, userId)  // ← 读 LockSettings（值为 false）
            || disabledByDefault                                // ← false（默认）
            || isDemoUser;                                      // ← false
}
```
`getBoolean(DISABLE_LOCKSCREEN_KEY)` 读的是 **LockSettings**（`locksettings get-disabled`），不是 `Settings.Secure` 的 `lockscreen.disabled`。

关键：
- `def_lockscreen_disabled=true`（之前改的 SettingsProvider 默认值）→ 设的是 Settings.Secure，**不影响 LockSettings**
- `locksettings get-disabled` = **false**（LockSettings 默认未禁用）
- `config_disableLockscreenByDefault` = false（AOSP 默认）
- `isLockScreenDisabled()` → **返回 false** → keyguard 显示 → shade 抢占焦点

**A13（BlueStacks 已修改）**：
```java
public boolean isLockScreenDisabled(int userId) {
    /*
    ... 标准逻辑全部注释掉 ...
    */
    return true;  // ★ BlueStacks 硬编码，keyguard 永不显示
}
```

#### 6. 修复

**文件**：`frameworks/base/core/java/com/android/internal/widget/LockPatternUtils.java`

**修改**：注释掉 AOSP 标准 `isLockScreenDisabled()` 逻辑，硬编码 `return true`（完全对齐 A13）。

```java
public boolean isLockScreenDisabled(int userId) {
    // BS-A16: BlueStacks is a desktop emulator with no lock screen.
    // Ported from A13. Without this, SystemUI shows the keyguard shade at
    // boot which steals window focus and blocks the HCALL onActivityDisplayed
    // hook from firing.
    /*
    if (isSecure(userId)) { return false; }
    ...  // 标准逻辑全部注释
    */
    return true;
}
```

**编译**：该文件属于 `framework.jar`（`frameworks/base/core` 模块）。由于 `m framework` 不产出设备版 `framework.jar`，**必须全量编译**才能生效。

**副作用清理**：`def_lockscreen_disabled=true`（SettingsProvider 默认值）已还原为 `false`。此修改设为 `true` 时不生效（LockPatternUtils 读的是 LockSettings，非 Settings.Secure），设了也是冗余。

**验证结果（2026-07-02）**：
```
mCurrentFocus=Window{...com.uncube.launcher3...HomeActivity}  ✅ 不再是 NotificationShade
bst.config.top_displayed_pkg=com.uncube.launcher3              ✅ HCALL 自动触发
locksettings get-disabled=true                                  ✅ return true 生效
BstHostCallManagerService onActivityDisplayed returned: 0       ✅ HCALL 发送成功
HD-Player 自动显示画面                                          ✅ 无需手动干预
```

**为什么 A13 没有这个问题**：
A13 BlueStacks 一早就做了 `isLockScreenDisabled() return true` 的修改。A16 bringup 时遗漏了这个移植，导致 keyguard 在启动时显示并抢占焦点，HCALL 无法自动触发。

**教训 - framework 改动必须全量编译**：`LockPatternUtils` 属于 `framework.jar`，`m framework` 不产出设备版 `framework.jar`（只更新 intermediates javalib.jar，含 .class 但不含 classes.dex）。framework 层修改**必须全量编译**才能部署验证，不能用 `m framework` 增量 + hot-inject。

**教训 - 不要设错位置**：之前把 `def_lockscreen_disabled=true` 设在 `SettingsProvider/res/values/defaults.xml`（Settings.Secure），但 `isLockScreenDisabled()` 读的是 `LockSettings.getBoolean("lockscreen.disabled")`，不是 `Settings.Secure.lockscreen.disabled`。两个存储位置同名但不同值，极易误导。后续修改前先确认数据源。

**验证工作流（适用所有 hot-inject）**：
1. **不要用 `adb reboot`**：BlueStacks 关机重启不稳定，设备会掉线。用 `kill-bs.bat` + 重启 HD-Player
2. **每次更新 Root.vhd 必须还原 Data.vhdx**：否则 ART dalvik-cache 与 jar 不匹配，已修复的代码可能不生效
3. **UUID 必须重写**：`54e9ad31-a169-4d5b-a0e0-705d62e96e71`（Tiramisu64 测试壳）
4. **sudo 密码**：`1`（编译机 172.16.6.191）

---

### 7AJ. 启动器图标正常但无法打开应用 【待查】

**现象**：uncube launcher 图标显示正常，但点击图标无法打开应用（待后续排查）。

---

### 7AI. Quickstep (com.android.launcher3) 崩溃 —— OverviewComponentObserver NPE 【待修】

**现象**：系统启动后弹出 "Application Error: com.android.launcher3" 对话框，Quickstep 反复崩溃。logcat：
```
NullPointerException: Attempt to read from field 'ActivityInfo
android.content.pm.ResolveInfo.activityInfo' on a null object reference
  at com.android.quickstep.OverviewComponentObserver.<init>(...:120)
  at TouchInteractionService.onUserUnlocked(...:893)
```

**根因**：`OverviewComponentObserver` 在初始化时查找 recents/overview 组件 → `PackageManager.queryIntentActivities(...)` 返回 null ResolveInfo → NPE。Launcher3/Quickstep 在 A16 同时作为启动器和最近任务提供者，移除 HOME category（7AF）后自身无法解析 overview 组件。

**临时方案**：`pm disable com.android.launcher3`（运行时禁用 Quickstep）。此方案在每次 Data.vhdx 还原后需重新执行。

**永久修复方向**：
- 将 `pm disable` 写入 init.rc 或 SystemServer 启动流程
- 或修改 Quickstep 的 `OverviewComponentObserver` 做 null-safe 处理
- 或完整移除 Quickstep 的 `TouchInteractionService` 组件

**关联**：7AF（Launcher3 HOME category 移除）

---

### 7AL. Quickstep OverviewComponentObserver NPE —— A13 移植修复 【已修】

**现象**：Quickstep (com.android.launcher3) 启动时 NPE：
```
NullPointerException: Attempt to read from field 'ActivityInfo
android.content.pm.ResolveInfo.activityInfo' on a null object reference
  at OverviewComponentObserver.<init>(OverviewComponentObserver.java:120)
```

**根因**：`OverviewComponentObserver` 构造器中调用 `resolveActivity(mMyPrimaryHomeIntent, 0)` 返回 null（因为 7AF 移除了 Launcher3 的 HOME category）→ `info.activityInfo.name` NPE。

**A13 修复**（`OverviewComponentObserver.java` 移植）：
1. **NPE 防护**：硬编码 `QuickstepLauncher` 组件名替代 `info.activityInfo.name`
2. **defaultHome 兜底**：`defaultHome` 为 null 时设为 `com.bluestacks.launcher/.HomeActivity`
3. **RecentsActivity BstHostCallManager**：`onCreate` 中初始化 `mBstHostCallManagerService`

**新触发崩溃**：修复后出现 `AppWidgetManager.getInstalledProvidersForProfile()` NPE——A16 用 `context.getSystemService(AppWidgetManager.class)` 返回 null（BlueStacks 无 AppWidget 服务），A13 用 `AppWidgetManager.getInstance(context)` 不返回 null。已修复：`WidgetManagerHelper.java` 加 null 检查返回空 stream。

**修改文件**：
- `packages/apps/Launcher3/quickstep/src/com/android/quickstep/OverviewComponentObserver.java`
- `packages/apps/Launcher3/quickstep/src/com/android/quickstep/RecentsActivity.java`

---

### 7AM. 网络不通 —— 以太网伪装 WiFi 【源码已改，待编译部署】

**现象**：`ping 8.8.8.8: Network is unreachable`。eth0 接口已启动（IP 10.0.2.15）但无网络代理注册。Play Store 等应用检测到无 WiFi 而拒绝联网。

**根因**：A13 有三处以太网相关 BST 修改未移植到 A16。

**修改 1：`EthernetNetworkFactory.java`**
- 添加 `BST_NETWORK_TYPE = "WIFI"`、`BST_CHANGES_ENABLED`（`bst.config.modify_network`，默认 1）
- 在 `NetworkAgentConfig` 构建时，BST 启用时设 `LegacyType(TYPE_WIFI)` + `LegacyTypeName("WIFI")`
- 添加 `SystemProperties` import

**修改 2：`EthernetConfigStore.java`**
- 移植 `bstLoadStaticConfig()` 方法：从 BST 系统属性读取静态 IP/DNS 配置
  - `bst.status.ip_guest_addr` = 10.0.2.15
  - `bst.status.ip_gateway_addr` = 10.0.2.2
  - `bst.dns_server` = 8.8.8.8
  - `bst.dns_server2` = 10.0.2.3
- `read()` 方法中添加 BST 检查：`bst.config.modify_network > 0` 时跳过 DHCP，直接加载静态配置

**修改 3：`EthernetTracker.java`**
- `DEFAULT_CAPABILITIES` 从硬编码 `TRANSPORT_ETHERNET` 改为 BST 条件切换：启用时 `TRANSPORT_WIFI`，禁用时 `TRANSPORT_ETHERNET`
- 添加 `SystemProperties` import

**注意**：该模块位于 `packages/modules/Connectivity/service-t/`，属于 `com.android.tethering` APEX。由于 APEX 使用预编译产物，`make iso_img` 和 `m com.android.tethering` 均未能从源码重编。需删除 `out_nxt_Baklava64` 后全量编译才能生效。

**对比 A13**：A13 上 `NetworkAgentInfo{network{100} ni{WIFI CONNECTED} nc{[Transports: WIFI]}}`——以太网被成功伪装为 WiFi，ping 8.8.8.8 正常（46.9ms）。

#### 7AM-4. EthernetService 不启动 —— device.mk 缺 feature XML ★根因之二

**现象**：以上三文件移植后编译部署，网络仍不通。`service list | grep ethernet` 为空，EthernetService 根本没运行。

**根因链**：
1. A16 的 `device/generic/common/device.mk` 中 `PRODUCT_COPY_FILES` 缺少 37 个 `frameworks/native/data/etc/*.xml` 条目（A13 有，A16 移植时遗漏）
2. 其中 `android.hardware.ethernet.xml` 未部署到 `/system/etc/permissions/`
3. `ConnectivityServiceInitializer.createEthernetService()` 检查 `deviceSupportsEthernet()` → `pm.hasSystemFeature(FEATURE_ETHERNET)` → false
4. `createEthernetService()` 返回 null → EthernetService 不启动 → 无网络代理注册

**修复**：从 A13 `device/generic/common/device.mk` 移植 37 个 feature XML 条目到 A16，包括：
- `android.hardware.ethernet.xml`（网络关键）
- `android.hardware.usb.host.xml`（deviceSupportsEthernet 备选条件）
- `tablet_core_hardware.xml`、sensor、camera、wifi、bluetooth 等

注意：`android.software.webview.xml` 不需要移植（A16 soong 已自动处理，移植会报 `overriding commands` 冲突）。

**验证**：`cmd package list features | grep ethernet` → `feature:android.hardware.ethernet` ✅；`service list | grep ethernet` → `ethernet: [android.net.IEthernetManager]` ✅；`ping 8.8.8.8` → 184ms ✅

---

### 7AK. Play Store 启动修复 —— HttpClient + 权限链 【已修】★里程碑

**目标**：Play Store（com.android.vending）能启动到主界面，可浏览和下载应用。

修复了三个层层递进的阻塞点：

#### 7AK-1. org.apache.http.legacy 库未注册 —— 权限 XML 文件 600 ★根因

**现象**：Play Store 启动时 `NoClassDefFoundError: ProtocolVersion`（Apache HttpClient 类）。

**根因链**：
1. A16 soong 构建产出的 `/system/etc/permissions/*.xml` 文件权限为 **600**（owner wifi:wifi），而 system_server（uid 1000）无法读取
2. `SystemConfig` 读不到 `org.apache.http.legacy.xml` → `SharedLibraryInfo` 未注册到 `mSharedLibraries`
3. PackageManager 的 `collectSharedLibraryInfos` 无法解析 `org.apache.http.legacy` 库 → `usesLibraryFiles` 中缺失 jar 路径
4. 即使 `OrgApacheHttpLegacyUpdater` 正确添加了库名到 `usesLibraries`，class loader 仍找不到 jar

**A13 对比**：A13 同一台编译机构建的 Root.vhd 文件权限 **664**（system:system），system_server 可读。权限差异源自 A13→A16 soong 行为变化（默认 mode 600）。

**修复**：`buildscripts/Makefile` 的 `Root.vdi` 目标中添加：
```makefile
$(shell chmod 644 $(OUTPUTDIR)/system/etc/permissions/*.xml 2>/dev/null)
$(shell chown 1000:1000 $(OUTPUTDIR)/system/etc/permissions/*.xml 2>/dev/null)
```
配合已有的 `copy_gms_permission_files` 扩展为 `pie || baklava`，使 `privapp-permissions-google.xml` 也随全量编译部署。

**验证**：`cmd package list libraries | grep apache` → `library:org.apache.http.legacy` ✅；`usesLibraryFiles` 包含 `/system/framework/org.apache.http.legacy.jar` ✅。

#### 7AK-2. targetSdk=34 应用不声明 `<uses-library>` → HttpClient 类不可用

**现象**：GMS (gms.persistent) 启动时 `NoClassDefFoundError: HttpClient`，Play Store 的同系类缺失。

**根因**：A16 的 `OrgApacheHttpLegacyUpdater.updatePackage()` 只在 app `targetSdk < 28` 时自动添加 `org.apache.http.legacy` 库。GMS/Play Store targetSdk=34 且不声明 `<uses-library>` → 库名不在 `usesLibraries` 中。

**修复**：`OrgApacheHttpLegacyUpdater.java` → `updatePackage()` 无条件对所有包调用 `prefixRequiredLibrary(ORG_APACHE_HTTP_LEGACY)`。完全对齐 A13 行为（A13 该库始终可用）。

**验证**：GMS `org.apache.http.legacy` 在 `usesLibraries` 列表中 ✅；GMS 零 HttpClient 崩溃 ✅。

#### 7AK-3. /data/priv-downloads 应用无 SYSTEM flag → privapp 权限不授予 ★根因

**现象**：Play Store 启动后 `SecurityException: You either need MANAGE_USERS or CREATE_USERS permission`。`privapp-permissions-google.xml` 中已声明该权限但未授予。

**根因**：A13 的 `InitAppsHelper.java` 对 `/data/priv-downloads` 使用 `mSystemScanFlags | SCAN_AS_PRIVILEGED`（含 `SCAN_AS_SYSTEM`），A16 移植时错误地使用了 `mScanFlags | SCAN_AS_PRIVILEGED`（**缺** `SCAN_AS_SYSTEM`）。

这导致 `/data/priv-downloads` 中的应用缺少 `FLAG_SYSTEM`，privapp 权限白名单 (`privapp-permissions-*.xml`) 不生效，所有 signature|privileged 权限（MANAGE_USERS、INSTALL_PACKAGES 等）均未授予。

**修复**：`InitAppsHelper.java` 第 271 行：`mScanFlags | SCAN_AS_PRIVILEGED` → `mSystemScanFlags | SCAN_AS_PRIVILEGED`（对齐 A13）。

**验证**：Vending `pkgFlags=[ SYSTEM ... ]` ✅；`MANAGE_USERS: granted=true` ✅；Play Store 启动到 `UnauthenticatedMainActivity` 零 SecurityException ✅。

**关联**：7AB（InitAppsHelper 移植）、7AE（GMS 权限）、7T-5（BstFilterAppsManager stub）

---

### 7AN. HD-Player Home/Recents/Back 按键无响应 —— Generic.kl 键值映射 【已修】

**现象**：HD-Player 工具栏的 Home、Recents（最近任务）按钮点击无响应，Back 按钮正常。

**根因**：HD-Player 的虚拟按键通过 bstinput 内核模块注入 Linux scan code，经 `Generic.kl` 映射为 Android keycode。A16 上游 `Generic.kl` 缺少两个 BST 特定的映射：

| Linux Scan Code | A13 映射 | A16 默认（错误） |
|---|---|---|
| 163 | **APP_SWITCH** | MEDIA_NEXT（无功能） |
| 165 | **HOME** | MEDIA_PREVIOUS（无功能） |
| 158 | BACK | BACK（A16 本来就有，正常） |

**修复**：`frameworks/base/data/keyboards/Generic.kl` 中添加：
```
key 163   APP_SWITCH      #MEDIA_NEXT
key 165   HOME            #MEDIA_PREVIOUS
```

同时移除了 A16 默认的 `key 163 MEDIA_NEXT` 和 `key 165 MEDIA_PREVIOUS` 行避免重复映射。

**验证**：2026-07-08 已确认部署生效。按键映射完整可用。

| 按键 | 扫描码 | Linux Key | Generic.kl | Android Key | 实际效果 |
|------|--------|-----------|------------|-------------|---------|
| Home | 0xE010 | KEY_PREVIOUSSONG (165) | `key 165 HOME` | AKEYCODE_HOME (3) | ✅ Settings→HomeActivity |
| Back | 0xE06A | KEY_BACK (158) | `key 158 BACK` | AKEYCODE_BACK (4) | ✅ |
| Recent| 0xE019 | KEY_NEXTSONG (163) | `key 163 APP_SWITCH` | AKEYCODE_APP_SWITCH | ✅ |

验证方法：`getevent -l /dev/input/event3`（内核层）+ `dumpsys window | grep mCurrentFocus`（框架层）。

MSC_SCAN 显示 0x90（而非 0x10）是 bstinput 用 Set-1 break 格式（bit-7）对接 `SERIO_8042_XL`（Set-2 协议）的格式不匹配，不影响功能。

---
### 7AO. 显示渲染异常 —— Standard task app 页面不可见 【排查中】

**现象**（2026-07-08 ~ 09）：
- Launcher 正常（修复 libflutter.so x86_64 提取后）
- 启动其他 app（Settings、Chrome、GameCenter）→ HD 画面不更新，始终显示 launcher + wallpaper
- app 在后台实际运行：焦点正确、WMS 报告 `isVisible=true`、`HAS_DRAWN`、frame 正确 `[0,0][1600,900]`

**根因**：standard task 窗口在 SF 中 `invisible reason=hidden by parent or layer flag`，`bounds={-16000,-9000,9000,16000}`（10× display 负偏移，仅 A16 有，A13=0）。

**已确认**：
- ✅ gralloc/HWC/SF/GPU 管线完全正常，`screencap` 正常
- ✅ WMS 配置 bounds、窗口状态全部正确
- ✅ 以下代码 A13/A16 完全相同：`getBounds()`、`getRelativePosition()`、`transformFrameToSurfacePosition()`、`updateSurfacePosition()`
- ✅ 显示 rotation 一致（ROTATION_0 1600×900）

**A16 独有特征**：`ActivityRecordInputSink` 5+ 个（A13=0）、`Transition Root` 层（A13=0）、BBQ wrapper 层（A13=0）、`AppZoomOut` DisplayArea（A13=0）

**已排除**：gralloc 显示管道、Launcher ANR（单独问题，已手工修复 lib 提取）、Shell Transitions FallbackPlayer 禁用（4 次无效尝试，已回退）、`mOverrideDisplayInfo`、`mLastNonFullscreenBounds`、AppCompat、WMS 代码差异

**无效尝试**（已回退）：TransitionController.java 6 处修改、FallbackPlayer.onTransitionReady 跳过 t.apply()、Transition.calculateTransitionRoots 直接 return

**当前方向**：在 SF Transaction 层面追踪 `hidden by parent` 来源——哪个父 SurfaceControl 的 HIDDEN 标志未清除。

详情参考：`A16-graphics-notes.md`

**附：Launcher libflutter.so x86_64 缺失 + ABI 选择问题** 【待修】

**根因（2026-07-09）**：

A13 和 A16 的 `primaryCpuAbi` 均为 `x86_64`，`abilist` 相同（`x86_64,x86,arm64-v8a,...`），但 **A16 选择 x86_64 加载 launcher** 而 **A13 通过 houdini 选择 ARM64**。

差异来源：
1. **`libnb.so` 64-bit 不同**：A13=8.8KB，A16=51KB，md5 不同。`libnb.so` 是 native bridge loader，决定是否拦截 `System.loadLibrary()` 用 houdini 翻译。
2. **A13 有 BST ABI override 机制**：`NativeLibraryHelper.findSupportedAbi()` 有 BST 包装方法（`bstAbiList` 参数），`PackageAbiHelperImpl` 有 `getAbiForSystemApps()` 逻辑。A16 **缺失此机制**。

A13 的 BST ABI override 在 `PackageAbiHelperImpl.derivePackageAbi()` 中调用 `NativeLibraryHelper.getBstAbiOverride()` → 返回 BST 自定义 ABI 列表（ARM64 优先）→ `findSupportedAbi(handle, bstAbiList)` 选中 ARM64 → houdini 翻译运行。

A16 走标准 AOSP 逻辑：`supportedAbis=[x86_64, x86, arm64-v8a, ...]` → x86_64 排第一 → 选中 x86_64 → libs 未提取 → 崩溃。

**根因（2026-07-09 确认）**：A16 `PackageAbiHelperImpl.shouldExtractLibs()` 中，system app 且未更新时直接返回 `false`，不提取 native libs。A13 有 ROB-14090 例外：对 `com.uncube.launcher3` 强制执行提取。

```java
// A13 (WORKING):
if (pkg.isSystem() && !isUpdatedSystemApp) {
    if (bstIsFirstBootOrUpgrade() && pkg.equals("com.uncube.launcher3"))
        extractLibs = true;   // ← 强制提取
    else
        extractLibs = false;
}

// A16 AOSP (BROKEN):
if (isSystemApp && !isUpdatedSystemApp) {
    extractLibs = false;       // ← 无条件跳过
}
```

**修复（2026-07-09）**：在 A16 `PackageAbiHelperImpl.shouldExtractLibs()` 加 ROB-14090 例外。编译 `m services` → hot-inject → clean Data 首次启动 → `lib/x86_64/libflutter.so` 自动提取 → 0 UnsatisfiedLinkError ✅。

详情参考：`A16-graphics-notes.md` 第 5 节

---

**现象**：点击 HD-Player X 按钮 → 确认关闭 → Android 不关机，20 秒后兜底线程强制断电 (`plrStopVM`)。

**诊断（2026-07-08）**：

Player.log 关键时间线：
```
13:44:23.086  plrStopPlayer: reason Close_by_user, Ready -> Stopping     ✅
13:44:24.222  bstinput: inpControlDispatch() -> 0                        ✅ vmsg 到达
13:44:24.231  BstShutdown: Trying to set property...                     ✅
13:44:24.233  BstShutdown: Successfully set the shutdown property.       ← 报告成功
... init 无任何反应，持续正常系统活动 ...
13:44:44.223  VM did not power down in 20 seconds. Forcing power down... ❌ 兜底强制断电
```

**根因**：A16 的 `system/core` 是全新的 AOSP 25Q4 树，**A13 的所有 BST 修改都没有移植过来**。

`bstshutdown` 执行流程：
```
① bstshutdown 设置 bst.config.start_shutdown=1
② init.rc 触发器 on property:bst.config.start_shutdown=1 → start bstshutdown_core
③ bstshutdown_core 执行实际关机
```

A16 缺少步骤②的 init.rc 触发器，所以 `bstshutdown` 设了属性但 init 不响应。

**A13 system/core 仓库**（`/home/henry/workspace/app-player/android-13/system/core`）需要移植到 A16 的 BST 提交：

**P0 — 关机修复（必须移植）**：

| 提交 | 文件 | 改了什么 |
|------|------|---------|
| `8e346d02d` | `rootdir/init.rc` | 加 `service bstshutdown_core` + `on property:bst.config.start_shutdown=1` 触发器；加 `proper_shutdown`、`mountsf`、`bindmount`、`airplane_mode`、`imeservice` 等 BST 服务 |
| `bcde7cf2c` | `init/reboot.cpp` | 关机时创建 `/data/.bstshutdown_sync` 标记文件（优雅关机标记） |
| `b03a8bf86` | `init/reboot.cpp` | ROB-17027: remount /data as ro on reboot + 修复 `.bstshutdown_sync` 文件句柄泄漏（加 `close(fd_bst)`） |
| `af0d28590` | `init/init.cpp` | 加 `check_status_of_last_boot()` — 启动时检查 `/data/.bstshutdown_sync` 判断上次关机是否正常，异常则触发 `proper_shutdown` 修复损坏文件；同时加 `copy_cpuinfo_file()` |

**关机闭环逻辑**：
```
正常关机 → reboot.cpp 写 /data/.bstshutdown_sync
   ↓
下次启动 → init.cpp check_status_of_last_boot() 检查文件
   ├─ 存在 → 正常 → 删除文件
   └─ 不存在 → 异常关机 → setprop bst.config.fix_corruptfiles=1
        → init.rc 触发 → start proper_shutdown → 修复损坏
```

**P1 — init.rc 中的其他 BST 服务（与 P0 同一条提交 `8e346d02d`）**：

| 服务 | 触发器 | 作用 |
|------|--------|------|
| `proper_shutdown` | `bst.config.fix_corruptfiles=1` | 异常关机后修复 xml |
| `mountsf` | `bst.config.mountsf=1` | BST 共享文件夹挂载 |
| `bindmount` | `bst.config.bindmount=*` | 绑定挂载 |
| `airplane_mode` | `bst.airplane_mode_active=*` | 飞行模式 |
| `imeservice` | `bst.config.ime_listenerport=*` | 输入法服务 |
| `logcat_redirect` | `bst.enable_logcat_redirection=1` | 日志重定向 |

此外注释掉了 console service 和 boringssl self test，加了 symlink tweaks、`min_free_kbytes`、`OPENSSL_armcap` 等。

**P2 — 其他 BST 修改（按需移植）**：

| 提交 | 文件 | 内容 |
|------|------|------|
| `bcde7cf2c` | `property_service.cpp` 等 | 降低日志级别、`ro.hardware=x86` |
| `4aae59e4c` | `rootdir/ueventd.rc` | BST 设备 DAC 权限 |
| `f76bac392` | `toolbox/getprop.cpp` | 隐藏 BST 属性 (`bst.debug.show_prop`) |
| `452bca8b7` | `toolbox/start.cpp` | stop 命令时设属性 |
| `e385ab887` | `libcutils/fs_config.cpp` | bstk/su 文件权限 |
| `1e29a5dc8` | `init/property_service.cpp` | arm-translator 属性 |
| `133a180f8` | `init/property_service.cpp` | 加载 `.bluestacks.prop` |
| `3674046c4` | 多个文件 | tiramisu.rc 路径适配 |
| `1a9fded27` | `rootdir/ueventd.rc` | `/dev/hvmem` 权限 |

**移植策略**：
- **最小方案**：只移植 P0 的 4 个提交（修复关机 + 异常关机恢复）
- **推荐方案**：移植 P0 + P1（`8e346d02d` 整条 init.rc diff），一条提交覆盖所有 BST 服务

**A16 源码路径**：`/home/henry/workspace/app-player/android-16/system/core`

**移植完成（2026-07-08）**：P0+P1 已移植到 A16 system/core：

| 文件 | 改动 |
|------|------|
| `init/init.cpp` | 加 `copy_cpuinfo_file()` + `check_status_of_last_boot()` 函数定义；在 `UmountSecondStageRes()` 后和 `setpriority()` 后调用 |
| `init/reboot.cpp` | 加 `MountEntry::RemountRO()` 方法；`TryUmountPartitions` 改为 `RemountRO() && Umount()`；`DoReboot` 中创建 `/data/.bstshutdown_sync` |
| `rootdir/init.rc` | 追加 `bstshutdown_core`、`proper_shutdown`、`mountsf`、`bindmount`、`airplane_mode`、`imeservice`、`logcat_redirect` 服务及属性触发器 |

**验证通过（2026-07-08）**：全量编译后部署，点击 X → 优雅关机完全正常。

Player.log 关键时间线：
```
17:14:39.324  plrStopPlayer: Close_by_user, Ready → Stopping
17:14:40.556  bstinput: inpControlDispatch() -> 0
17:14:40.559  bstinput: inpControlExecuteUserSpace → bstshutdown
17:14:40.569  BstShutdown: Successfully set the shutdown property.
17:14:40.571  init: processing action (bst.config.start_shutdown=1)  ← 🆕 修复后生效
17:14:40.573  init: starting service 'bstshutdown_core'              ← 🆕 修复后生效
17:14:40.941  BstShutdownCore: exited with status 0
17:14:41.699  init: Received sys.powerctl='shutdown,userrequested'
17:14:41.705  init: Entering shutdown mode
      ... init 停止 114 个服务 ...
17:14:45.471  powerctl_shutdown_time_ms:3765:0                      ← 3.7 秒完成
17:14:45.472  init: Reboot ending, jumping to kernel
17:14:45.495  reboot: Power down
17:14:45.683  VM is powered off
17:14:45.788  Player state: Exiting err: 0, coreSvcErr: 0         ← 干净退出
```

**修复前后对比**：

| 步骤 | 修复前 | 修复后 |
|------|--------|--------|
| bstshutdown 设属性 | ✅ | ✅ |
| init 响应 `bst.config.start_shutdown=1` | ❌ 无反应 | ✅ 触发 `bstshutdown_core` |
| Android 关机序列 | ❌ 跳过 | ✅ 3.7s 完成 |
| VM 断电 | ❌ 20s 超时强制断电 | ✅ 优雅关机自动断电 |
| HD-Player 退出 | `err: -1` | `err: 0, coreSvcErr: 0` |

部署规则参考：`rules-build-deploy.md`
- 全量编译后 Root.vhd 位于 `/home/henry/workspace/releases/bst-v5.22.210-9527/Baklava64/bst-v5.22.210_Baklava64-9527/Root.vhd`
- 替换引擎文件后必须还原 `Data_orig.vhdx` → `Data.vhdx`
- 必须重写 Root.vhd UUID 为 `54e9ad31-a169-4d5b-a0e0-705d62e96e71`

---
---
