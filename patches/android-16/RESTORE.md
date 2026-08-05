# Android-16 (Baklava) 代码树存档 + 恢复清单（RESTORE）

> 目的：在**干净的代码树**上，仅凭本目录即可把 A16 guest 恢复到**可成功运行**状态（boot 到 launcher + 优雅关机）。
> 问题原理与逐条踩坑见 [`../../progress/android-16-boot-guide.md`](../../progress/android-16-boot-guide.md)。
> 权威 diff 抓取时间：2026-07-14，来源远程 guest 构建机 `markxu@172.16.6.191`。

---

## 1. 存档内容清单

| 目录/文件 | 内容 |
|---|---|
| `patches/aosp16__<project>.patch` | AOSP 树 16 个 dirty project 的 `git diff HEAD`（tracked 改动） |
| `patches/aosp16__<project>.base` | 各 project 抓取时的 HEAD commit（apply 基线） |
| `patches/aosp16__<project>.status` | 各 project `git status --porcelain`（含新增/删除标记） |
| `patches/aosp16__frameworks_base__r262-temp-disable-shell-transitions.patch` | **TEMP** boot 基线：关 Shell Transitions（Settings EXITING / BLAST commit）；BLAST 修好后删除（见 guide 阶段 11） |
| `patches/app-player_buildscripts.patch` | `app-player/buildscripts/` 改动（Makefile/build.sh/create_vdi.sh 等） |
| `patches/hd-guest.patch` | `app-player/hd/guest/` 改动（BootImage 构建/init 脚本） |
| `patches/goldfish-opengl-pie.patch` | goldfish-opengl-pie 树内 `git diff HEAD`（与 `../goldfish-opengl-pie-a16-fixes.patch` 互为佐证） |
| `untracked-src/` | 92 个**新增源文件**（BST 定制：BstUtils.java、AIDL、HAL manifest、device 配置、init.x86.rc、bst_bins 等），按 `<project>/<相对路径>` 组织 |
| `bootimage/hd/guest/BootImage/` | first/second-stage 脚本快照：`init.sh`、`stage2.sh`、`bstsetup.env`、`bstsetconf.sh`、`Makefile` |
| `kernel/config` | kernel-a16 `.config`（含 ext4 + squashfs + BS 钩子） |
| `kernel/git.txt` | kernel-a16 HEAD + diff stat |
| `meta/base.txt` | repo manifest revision |
| `meta/binary-untracked-manifest.txt` | 95 个 BST **二进制预置**（libndk_baklava64/、busybox 等）的 md5+size+路径——**不入库**，恢复时须从 BST 源重新提供（见 §5） |
| `meta/*-untracked.txt` | 各处未跟踪文件清单 |

> `.patch` 只含 tracked 改动；新增文件在 `untracked-src/`；被删除/改名（如 gfxstream disable）见 §4。

---

## 2. Base 状态（apply 基线）

| 组件 | 基线 |
|---|---|
| AOSP manifest | `repo init -u <manifest> -b refs/tags/android-16.0.0_r4` 后 `repo sync` |
| 各 AOSP project HEAD | 见 `patches/aosp16__<project>.base`（apply 前 `git checkout <base>` 对齐） |
| app-player | commit `8ed098751ed028c30665b4ce968137d5aba34554`（tag `bst-v5.22.210-5.22.210.1033` 附近） |
| app-player/hd（submodule） | commit `45ee6ffb7b7e6ff0f2a468d36a0907243f9d194b`（branch `bst-v5.22.210`） |
| goldfish-opengl-pie | commit `2834e90ad3443b0d348fab68204688369974f985` |
| kernel-a16 | HEAD `686f860abf3a5c7117d6a784ef0360ac99bfcef0`（放 `~/aosp16/kernel-a16`，独立含 `.git`） |

**远程路径**（本次抓取环境，供参照）：`~/aosp16`（= `/home/clouddev/bst/workspace/markxu/aosp16`）、`~/app-player`、`~/ggl/goldfish-opengl-pie`。

---

## 3. Apply 顺序（在干净树上恢复）

```bash
# 约定：AOSP=~/aosp16, APP=~/app-player, ARC=<本目录绝对路径>

# (a) AOSP 树：逐 project apply tracked 改动 + 铺新增文件
cd $AOSP
for p in $(ls $ARC/patches/aosp16__*.patch); do
  # 跳过 TEMP 附加 patch（`__r262`），避免误解析成错误 project 路径
  case "$(basename "$p")" in
    *__r262*) continue ;;
  esac
  name=$(basename "$p" .patch); proj=$(echo "${name#aosp16__}" | tr '_' '/')
  # 注意：project 路径含下划线的需人工核对（如 device/generic/x86_64）
  ( cd "$proj" && git checkout "$(cat "$ARC/patches/$name.base")" 2>/dev/null; git apply "$p" )
done
# **TEMP** boot 基线（guide 阶段 11）：在 frameworks/base 主 patch 之后追加
# BLAST/SF commit callback 修好后删除本 patch 并恢复 ENABLE_SHELL_TRANSITIONS=true
( cd frameworks/base && git apply "$ARC/patches/aosp16__frameworks_base__r262-temp-disable-shell-transitions.patch" )
# 新增源文件（untracked-src 下按 aosp16__<proj>/<相对路径>）
#   将 untracked-src/aosp16__<proj>/* 拷回 $AOSP/<proj>/（保持相对路径）

# (b) app-player buildscripts + hd/guest
cd $APP && git apply $ARC/patches/app-player_buildscripts.patch
( cd $APP/hd && git apply $ARC/patches/hd-guest.patch )
# BootImage 脚本以 bootimage/ 快照为准（init.sh/stage2.sh/bstsetup.env/Makefile）

# (c) goldfish-opengl-pie
cd ~/ggl/goldfish-opengl-pie && git checkout 2834e90a && git apply $ARC/patches/goldfish-opengl-pie.patch
#   或直接 apply ../goldfish-opengl-pie-a16-fixes.patch（叙事版 A16 修复，12 文件 371 行）

# (d) kernel-a16：用 kernel/config，开 CONFIG_SQUASHFS/ext4，clang/LLVM=1 编 bzImage
```

> project 名映射：`aosp16__device_generic_x86_64` → `device/generic/x86_64`（下划线还原成 `/` 时对多级路径需核对 `.status` 头）。逐条 apply 后跑 §6 校验。

---

## 4. 需要手工处理的非-diff 改动

这些是文件**改名/删除/目录级**操作，不体现在 `git diff` 里，恢复时须手工执行：

- **禁用内置 gfxstream**（避免与 goldfish 模块名冲突，见 guide 阶段 9）：
  ```bash
  mv $AOSP/hardware/google/gfxstream $AOSP/hardware/google/gfxstream.disabled
  ```
  （`build/make` patch 里的 `BUILD_EMULATOR := false` 与此配合。）
- **产品目录软连**（A16 product 名 `generic_x86_64`，Makefile 期望 `x86_64`）：
  ```bash
  ln -s generic_x86_64 $AOSP/out_nxt_Baklava64/target/product/x86_64
  ```
- `untracked-src/` 里带 `.disabled` 后缀的 `Android.bp`（hwcomposer/gralloc/nulldrv 等）表示对应模块被禁用（原文件改名）。

---

## 5. 二进制预置（不入库，须另行提供）

`meta/binary-untracked-manifest.txt` 列出 95 个 BST 二进制（`device/generic/common/libndk_baklava64/*.so`、`busybox`、apksigner keystore 等），是 arm64 NDK 翻译层 + busybox 等**预置二进制**，体积大、非本项目源码产物，**未纳入本存档**。恢复时从 BST 官方 prebuilts / A13 对应目录取同名文件，用 manifest 的 md5 校验一致性。

---

## 6. 构建 / 打包 / 部署

### 6.1 构建（远程 guest 构建机）
```bash
cd ~/aosp16
export ALLOW_MISSING_DEPENDENCIES=true          # 只此一个！勿设 WITHOUT_CHECK_API / BUILD_FROM_SOURCE_STUB
export OUT_DIR=out_nxt_Baklava64 APP_PLAYER_DIR=~/app-player BST_BUILD_WITH_DEXPREOPT=true
source build/envsetup.sh
lunch android_x86_64-trunk_staging-eng          # 不是 generic aosp_x86_64
m droid -j24
# → system.img (~1.99GB)
```
goldfish 图形 + hwc2 + hostcall/gcall JNI 用 `mmm`（见 guide 阶段 9/10）：
`mmm ~/ggl/goldfish-opengl-pie` · `mmm ~/ggl/goldfish-opengl-pie/system/hwc2` · `mmm ~/app-player/hd/Source/{xpl,vmsg/guest,hcall/guest,gcall/guest}` · `mmm frameworks/base/services/java/com/bluestacks/server/native`。

### 6.2 打包 Root.vhd（system.sfs 内嵌 raw ext4 system.img）
```bash
bash scripts/r228-pack-root.sh        # make-baklava-system-sfs.sh → system.sfs → Root.fs → create_vdi → Root.vhd
# UUID 回写: VBoxManage internalcommands sethduuid Root.vhd 54e9ad31-a169-4d5b-a0e0-705d62e96e71
```
fastboot.vdi（kernel-a16 bzImage + initrd）：`bash scripts/r245-rebuild-fastboot.sh`，UUID 回写 `91b80c95-...`。

### 6.3 部署（Windows）
```powershell
# scp Root.vhd + fastboot.vdi 到 Engine\Tiramisu64\
# 每次换盘都要回写 UUID（见上），否则 GlueStartVM failed
scripts\win-replace-tiramisu64.ps1
# 洁净首启：从 cont.31 已验证 wipe snapshot 恢复 Data.vhdx
scripts\g1_reset_data_wipe.ps1
HD-Player.exe --instance Tiramisu64
```

`Data_orig.vhdx` 已在 cont.24/31 被禁用；它是不可用的空盘基线，不得用于
当前 Android-16 Layer2 验证。

---

## 7. 产物身份 + boot 校验 oracle

| 项 | 值 |
|---|---|
| Root.vhd UUID | `54e9ad31-a169-4d5b-a0e0-705d62e96e71` |
| fastboot.vdi UUID | `91b80c95-...` |
| 最终验证态 Root.vhd md5（TEMP R262b） | `7a55ef636b0961c87bd0815cfc5c8cde` |
| SystemUI.apk md5（TEMP R262b，关 shell transitions） | `b1e647bc36ad53db430f705e21f14b7d` |
| 首个可 boot system.img md5 | `f3228328307e3105d24276a711d806ac` |
| R261 Root（auth 恢复、Settings 仍可能 EXITING） | `a05a270129dbb91f5fdcf252036ae364`（被 R262b 取代） |

**boot readback oracle（独立回读，不信"命令成功"）**：
1. `A16DBG: system mounted from sfs` — first-stage 挂载 OK
2. `init second stage started!` — init 进 second stage
3. `odsign.key.done` + `odrefresh ... returned 80` + `Unable to open boot.art`=0 — ART/boot.art 链
4. bootanim exit 0 + `sys.boot_completed=1`（guest ~178s）
5. `hcallOnActivityDisplayed com.uncube.launcher3` → **`Player state: ready`** → `fUiHideBootProgressBar`（HD overlay 撤掉）
6. `service check auth` → found（Settings 可启动）
7. Settings **可见**：SF `Transition Root` = 0；Settings layer visible + Output Layer（**TEMP** R262+R262b；BLAST 修好后应收口）
8. 点 HD X → `bst.config.start_shutdown=1` → `Exiting err: 0`，**无 20s `Forcing power down`**

日志来源：guest 串口 / `bs_bootlog`；host `C:\ProgramData\BlueStacks_nxt\Logs\{Player.log,BstkCore.log}`。

---

## 8. 完整性说明

- 本存档为**只读抓取**（`git diff HEAD` + 文件拷贝），未改动远程树。
- tracked 改动 100% 可由 `.patch` 复现；新增源文件在 `untracked-src/`；二进制预置见 §5 manifest（须另配）。
- apply 后自检：每 project `git apply --check <patch>` 应通过；`untracked-src` 铺回后与远程 `git status` 文件集一致。
- **完整性验证（2026-07-14）**：对远程工作树做 `git apply --check --reverse` 回读——16/16 AOSP project + app-player buildscripts + hd-guest + goldfish-opengl-pie 全部通过，确认 `.patch` 与当时可运行树逐字节一致。
