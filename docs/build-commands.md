# 构建命令（Build Commands）

> 当前 mainline 构建根为 `~/android-16`。`~/aosp16` 命令仅用于历史
> development 记录，不能作为当前 build/stage/pack 产物来源。

## AOSP16 开发树（历史基线）

- `~/aosp16` 从 `android-16.0.0_r4` 建立，承载 G1/P2/cont.101
  开发、打包和启动验证。
- 历史命令与产物身份见
  [`development-history/aosp16/`](development-history/aosp16/)；不要把这里
  的命令复制成当前 mainline 构建。
- **lunch 目标（统一板方案，已采纳）**：两端共用 BlueStacks 板 `device/bst/qvirt`，仅 arch 不同：
  - **mac** → `lunch bst_arm64-userdebug`（arm64；板源 `android-mac/device/bst/qvirt`）。
  - **win** → `lunch bst_x86_64-userdebug`（x86_64；新增 product 变体；win 不再用 cuttlefish/generic）。
  - 依据：两端虚拟化均实现 qvirt 设备（mac `qvm`、win `hd/Source/{vmsg,hst,gr}`）+ `hardware/bst/*` HAL 两端都有。Phase 1 = port 单一 `device/bst/qvirt` 到 android-16（arm64+x86_64 双 product）。详见 architecture.md。

## Android-16 mainline（当前）

```bash
# 只读身份/依赖检查；不启动构建
ssh markxu@172.16.6.191 \
  'bash ~/bst-aosp/scripts/g1_build_android16.sh --check'

# 全流程前预检（同样不 build/pack/deploy）
bash scripts/g1_build_pack.sh --check

# build + pack + deploy + boot oracle
bash scripts/g1_build_pack.sh
```

Preflight 必须显示 resolved tree=`~/android-16`、branch、完整 HEAD、
OUT_DIR 和 `bst_x86_64`。命中 `~/aosp16` 即失败。

## Android-16 `bst_x86_64` build+pack+deploy+verify

> 当前活跃流程。单一入口 `scripts/g1_build_pack.sh`（win Git Bash 跑）。
> G1-RESTORE 是 AOSP16 历史恢复基线；当前 target-only gate 见
> [`development-workflow/promotion.md`](development-workflow/promotion.md)。
> 调试约束：**禁 `m clean`（用 installclean）+ 禁 apk 重编**（apk 用 prebuilt，g1_copy_bst_apks 从 apks_Baklava64 拷）。

```bash
# 全流程（远程 build/pack → win deploy → win boot verify）
bash scripts/g1_build_pack.sh
# 调试提速：跳过 m droid（用现有 OUT），只 pack+deploy+verify
bash scripts/g1_build_pack.sh --no-build
# 只重 pack（stage+copy_apks+r228），不 build/deploy/verify
bash scripts/g1_build_pack.sh --pack-only
```

**流程分解**（g1_build_pack.sh 内部，每步 readback）：
1. 远程 `g1_build_android16.sh`：身份 preflight +
   `lunch bst_x86_64-trunk_staging-eng` + `m droid -j24` + 一次
   goldfish EGL/gralloc/hwc2 mmm，生成 `g1_android16_build.identity`。
2. 远程 `g1_build_libs.sh`：hd guest 必需模块；可选模块失败告警，
   hostcall/gcall/server/tool 失败则中止。
3. 远程 `g1_pack_root.sh`：从同一 Android-16 HEAD stage OUT fold、
   复核 build identity、只 stage 已编译图形、复制 APK、应用
   overlays/HAL 策略、调用 r228 pack，并生成 `Root.vhd.identity`。
4. `g1_copy_bst_apks.sh`：append `ro.hardware.gralloc=bst`+`egl=emulation`
   到 staged build.prop（抗 rsync --delete）+ BST apk
   （launcher/gamecenter/bsxlauncher）预装 priv-app（含 unzip native lib）。
5. win `g1_win_deploy.ps1`：同时 scp Root.vhd 和 identity，用 SHA-256
   比对后备份替换。
7. win 干净首启：`Data_orig.vhdx → Data.vhdx`（**copy，勿删**）。
8. win `g1_boot_verify.ps1`：读部署 identity，Layer2 7 个 oracle 任一
   缺失即返回非零。

**fastboot.vdi 重建**（kernel-a16 + 修复版 bs_bootlog initrd；非每次，仅 kernel/bs_bootlog 变时）：
```bash
ssh markxu@172.16.6.191 'cd ~/app-player/hd/guest/BootImage && KDIR=~/android-16/kernel-a16 make build_fastboot'
# → fastboot/fastboot.vdi；sethduuid 91b80c95；scp 到 Engine\Tiramisu64\fastboot.vdi
```

**⚠️ gotchas（必读，见 G1.md「踩坑速查」）**：
- **Data.vhdx 勿删**：干净首启 `Data_orig.vhdx → Data.vhdx`（copy）。删了 → VBox `Could not open medium Data.vhdx` → 卡 [Initializing]。
- **UUID 验 footer 不信 showhdinfo**：`showhdinfo` 显示注册表缓存值；文件实际 UUID 看 hexdump footer offset 64。r228 远程 sethduuid 曾报成功但没真改 footer。
- **fastboot build_fastboot 须设 `KDIR=~/android-16/kernel-a16`**；Makefile
  必须在 kernel 产物和已验证 prebuilt 均不存在时硬失败。
- **create_vdi「挂起」= chown read-only abort**：r228 开头清 nbd + 重建干净 Root.fs 即解。
- **launcher 在 Priv-Downloads 段**：buildscripts `copy_system_apks` 遇 Data: 就 break，不拷 launcher（它在 Priv-Downloads）→ G1 删 dataFS 后缺 → FallbackHome。故 `g1_copy_bst_apks.sh` **硬编码 APK 列表 force 预装 priv-app**（不读 APPCONFFILE）。历史：早期版本读 APPCONFFILE 须 `tr -d '\r'`（CRLF）。

## guest kernel（已 checkout）

- **win**：`~/kernel-common-a13/`（remote `bluestacks/kernel-common-a13.git`，分支 `aosp13-sync`）。
- **mac**：`~/kernel-mac/`（remote `bluestacks/kernel-mac.git`，分支 `bst-v5.0.0-nxt_mac2`）。
- 内核构建命令（`build.config.*` + `build.sh`）待确认（按 Android GKI/common kernel 流程）。

## host 使用的镜像产出（guest 构建）

详见 [build-flow.md](build-flow.md)：guest 镜像由 **`app-player/buildscripts/Makefile`**（Linux 构建机）编排——AOSP `make iso_img`/`ramdisk` + hd guest 内核模块（`mmm hd/Source/{vmsg,hcall,gcall,xpl}/guest`）+ 注入 `hd/guest/BootImage/initrd`（`init.sh` mknod `/dev/bstvmsg`）+ 装配 `Root.vdi`（vbox/hyperv）。**升级杠杆 = `ANDROIDHOME` 改指 android-16 树**（树须携带 BlueStacks 定制 + hd 集成 + kernel64-hyperv）。

## host 构建（本地）

- **win**：`C:\workspace\app-player`（完整）/ `app-player-dev`（最小）—— `build.bat` / `build_simple.bat`。
- **mac**：`C:\workspace\qvm`（QEMU fork）——【Phase 2 填构建命令】。

## 验证 gate（见 ../.claude/rules/validation-gate.md）

- Layer 1：readback exit code + `ls -la out/target/product/<device>/*.img`。
- Layer 2：见 [boot-oracles.md](boot-oracles.md)（需虚拟化就位）。

## guest 基线构建调用（android-13，buildscripts）

入口 `app-player/buildscripts/build.sh`（Jenkins 用）或直接 make。需环境变量 **`BRANCH`/`OEM`/`ANDROID_IMAGES`**（Jenkins 传入，本地无默认）。

```bash
cd ~/app-player/buildscripts
make -j$(nproc) -f Makefile vbox OEM=<oem> IMAGE=<image> IS_HYPERV_BUILD=0
# Makefile 内部: cd ANDROIDHOME(=~/app-player/android-13 -> ~/android-13) && source build/envsetup.sh && lunch android_x86_64-eng && make iso_img && make ramdisk
# hd 内核模块: mmm $(BASEPATH)/hd/Source/{xpl,vmsg/guest,hcall/guest,gcall/guest}; 注入 hd/guest/BootImage/initrd
# 产: Root.vdi + fastboot.vdi（vbox）; hyperv 走 IS_HYPERV_BUILD=1 target=kernel_and_initrd, lunch android_x86_64-eng_hyperv
```

- **ANDROIDHOME** = `~/app-player/android-13`（symlink → `~/android-13`，根目录已 populate 的树，免重 init）。
- **hd** = `~/app-player/hd`（submodule re-init 到对应 tag）。
- **OEM**：nxt（默认）/ bgp64 / msi64 / cn …。
- **IMAGE**：Jenkins 参数（合法取值本地 `bst/apks/tiramisu/` 为空，未确认）→ **需人类提供**。
- 需 Java8 + ccache + 充足磁盘（out_ 目录巨大）。
- 布局就绪核实（2026-06-18）：app-player @ `.1033`、app-player-mac @ `.7526`、android symlink、hd populate 均 ✅。

### ⚠️ Root.vdi 重打包：用 `make -o` 跳过 android 重编（重要，省 4h）

**坑**：`make Root.vdi`（完整）的 android target recipe 是 `rm -f *.img && make iso_img && make ramdisk`。一旦 soong 检测到 `make_vars-*.mk` 需 regenerate（**任何**环境变量/配置漂移都会触发，即使内容相同），ninja 会把**整个 101364-target 图标记为脏 → 全量重编 ~4h**（2026-06-24 实测：env 漂移后 `[0% 251/101364]` 全量重编）。android 重编对「只改了 apk/配置」的变更是**纯浪费**——system 镜像未变，只需重新注入 apk + 重打包。

**解法**（仅 apk/配置/buildscripts 变更，system 未变时）：用 `make -o`（`--assume-old`）把 4 个 phony 依赖标记为已最新，**只跑 Root.vdi recipe body**（copy_android_files_to_outputdir → copy_data_apks 注入 apk → create_rootfs → make_vdi_file），复用已编译的 system：

```bash
cd ~/app-player/buildscripts
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 LC_ALL=C LANG=C PATH=$JAVA_HOME/bin:$PATH
export ANDROID_SDK_PATH=/home/henry/workspace/android-sdk/sdk ANDROID_HOME=$ANDROID_SDK_PATH
export FLUTTER_ROOT=$HOME/flutter PATH=$FLUTTER_ROOT/bin:$PATH
export ANDROIDOUTPUTLOC=$HOME/releases PKG=bst-v5.22.210_Tiramisu64-local
# -o 跳过 android/libs/apks/datafs 四个 phony 依赖 → 只重打包，不重编 android（~10-30min vs 4h+）
make -o android -o libs -o apks -o datafs -f Makefile Root.vdi OEM=nxt IMAGE=Tiramisu64 ANDROID_SDK_PATH=$ANDROID_SDK_PATH
```

- **何时用完整 `make Root.vdi`**：android/iso_img 源码确实变了（AOSP 树改动）。此时 4h 重编不可避免。
- **何时用 `make -o ...` 重打包**：只改了 apk（scratch-rosen 重建）、APPCONFFILE、buildscripts、device overlay、bst/apks 配置等——system 不变，只需重新装配镜像。
- dry-run 验证依赖确实被跳过（不应出现 `make iso_img`）：`make -n -o android -o libs -o apks -o datafs Root.vdi OEM=nxt IMAGE=Tiramisu64 ...`
- 前提：`ANDROIDOUT`（android-13/out_nxt_Tiramisu64）system 完整（上次完整 build 产物未被 `m clean`）。
- **apk 注入位置**：`copy_data_apks` 读 APPCONFFILE（`bst/apks/tiramisu/tiramisu_appPlayerApksToInstall_nxt_tiramisu64`）从 APKFOLDER（`bst/apks_Tiramisu64`）拷 apk；GMS 由 datafs 的 `copy_g_p_all` 从 `scratch-gaurav/gapps_tiramisu64` 注入。改 apk 后确保它在 APKFOLDER + APPCONFFILE 引用。
