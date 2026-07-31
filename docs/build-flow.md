# 端到端构建流程（Build Flow）

> 源自 app-player（win tag `bst-v5.22.210-5.22.210.1033`）+ hd（同 tag）的构建脚本梳理。这是「AOSP 产物 → host 使用的镜像」的权威流程，也是 android-13→16 升级的核心枢纽。

## 三条构建轨道

| 轨道 | 入口 | 平台 | 产出 |
|---|---|---|---|
| **host 应用** | `app-player/build.bat`（win）/ `build.sh`（mac） | Windows / macOS | `HD-Player.exe` + Qt UI + BlueAI/Electron |
| **host 框架 hd** | `hd/Source/Makefile` + `CMakeLists.txt` + `setenv.bat` | win: VS2019/2022+Qt6.7.2+vcpkg+cmake/msbuild；mac: clang | hd 全组件（gr/hst/vmsg/vmmgr/cam/aud/ipc…）→ `Source/Output/` |
| **guest 镜像** | `app-player/buildscripts/Makefile`（849 行，编排器） | **Linux**（AOSP 构建机） | `Root.vdi` / `fastboot.vdi`（含 system + hd 内核模块） |

## guest 镜像构建（核心，buildscripts/Makefile）

1. **ANDROIDHOME 杠杆**（line 11-23）：`ANDROIDHOME := $(BASEPATH)/android-13`（按版本选 android/android-9/11/13）。**升级 = 改指 android-16 树**。
2. **AOSP 构建**（`android` target, line 320-322）：`cd $(ANDROIDHOME) && make iso_img -jN && make ramdisk`。
3. **hd 内核模块**（`libs` target, line 465-469）：用 AOSP `mmm ../hd/Source/{xpl, vmsg/guest, hcall/guest, gcall/guest}` 构建——即 **hd 的 guest 模块集成进 AOSP 树**（Android.mk）。另有独立 `Kbuild`/`Makefile`（`hd/Source/vmsg/guest/driver/`，`obj-m := bstvmsg.o`）。
4. **kernel**：`$(ANDROIDHOME)/kernel64-hyperv` → `bzImage` + modules（BootImage 目录）。
5. **注入 + 设备**：`hd/guest/BootImage/Makefile` 把 `bstvmsg.ko`/`bstpgaipc.ko`/`bstaudio.ko`/`bstcamera.ko`/`bstinput.ko` 拷进 `initrd/boot/bstmods/`；`hd/guest/BootImage/init.sh` `load_module` + `mknod /dev/bstvmsg`（/dev/bstpgaipc 等）。
6. **装配**：`Root.vdi: android libs apks`（line 133）→ 打包 system+modules+apks 为 VDI（win vbox 7.0.8 / hyperv；mac VBox 5.2.20）。`Package/`+`Sfx/`+`Installer/` 产出可分发安装包。

## win vs mac

- `OEM_$(OEM)_MACHOST` 检测（line 113）：mac `VBOX_VERSION=5.2.20`，win `7.0.8`。
- 虚拟化：win = vbox（`hd/Source/vmmgr/vbox`）+ hyperv；mac = qvm(QEMU)。
- 构建：win `build.bat`(MSBuild+CMake)；mac `build.sh`+`buildscripts/mac_build.sh`。

## clouddev 现状 vs buildscripts 期望

| buildscripts 需要 | clouddev 现状 |
|---|---|
| `android-13` 树（含 external/bluestacks、hardware/bst、kernel） | ✅ `~/android-13`（有 external/bluestacks/{bstfolder,bstgps,bstshutdown,bstsyncfs,sensors} + hardware/bst） |
| `kernel64-hyperv` | ❌ 只有 `kernel`（路径/名不一致） |
| `hd/` 兄弟（`mmm ../hd/Source/vmsg/guest`） | ❌ clouddev 无 hd |
| buildscripts 本身 | ❌ clouddev 无（在 app-player 仓库） |
| Android-16 mainline | ✅ `~/android-16`，promotion 后的 BlueStacks 集成树 |

## 升级影响点（android-13→16）

1. **ANDROIDHOME → `~/android-16`**：树携带 promotion 后的 BlueStacks
   定制、qvirt、hd guest 集成和 kernel；不得指回 `~/aosp16`。
2. **hd guest 模块 API 兼容**：VmsgDrv.c / bstpgaipc / hcall / gcall 需适配 android-16 内核 API。
3. **kernel**：kernel64-hyperv 路径 + android-16 内核配置。
4. **init.sh**：android-16 启动流程适配（init/fstab/dm-verity 变化）。
5. **buildscripts/Makefile**：可能需小改（路径、kernel 名、模块列表）。

## 已决策的升级构建架构

- AOSP16 先完成完整 development/验证，再 promotion 到
  `~/android-16` 25Q4-evolved mainline。
- hd 来源为 `~/app-player/hd`，活动脚本统一导出 `HD_SOURCE_TOP`。
- Linux guest 构建沿用 source build + OUT fold + buildscripts-compatible
  Root pack；每阶段携带 source/artifact identity。
