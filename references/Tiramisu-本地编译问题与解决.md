# Tiramisu64 本地编译：问题与解决方法

> AOSP 树：`app-player/android-13`（Android 13 / Tiramisu）  
> 构建机：Ubuntu 22.04（与 Jenkins Tiramisu 节点一致）  
> 工作目录：`/home/henry/workspace/app-player`  
> 输出：`/home/henry/workspace/releases/<android-13分支>-<BUILD_NUMBER>/Tiramisu64/`  
> 入口：`buildscripts/build_Tiramisu64.sh`  
> Jenkins 参考：`BS5-AppPlayerBuild-Tiramisu64.txt`（#1375）

---

## 一、正确做法（已验证可编出）

1. **对齐 Jenkins 主流程**：`build_Tiramisu64.sh` → `build_Tiramisu_common.sh` → **`build.sh`** → `make vbox` → **`make iso_img` + `make ramdisk`** → `create_zips.sh`；
2. 默认 **不跑** `sync.sh`（`SYNC_SOURCE_CODE=false`）；
3. 仅在 **buildscripts 层** 做少量本地适配（见第三节）；**不改 AOSP 源码**；
4. 在**可交互终端**执行（打包阶段需要 `sudo`，与 Jenkins 免密 sudo 等效）。

全量冷启动约 **11 小时**（本次 10:57:27），`out_nxt_Tiramisu64` 体积大（Jenkins 约 80GB+），需预留磁盘。

### 成功构建记录（2026-06-12）

| 项 | 值 |
|----|-----|
| 日志 | `out-app-player-Tiramisu/logs/build_Tiramisu64-260611-23-49.log` |
| 分支 / BUILD_NUMBER | `bst-v5.22.210` / **9527** |
| 耗时 | 23:49 → 10:47，**10:57:27** |
| 产物 | `Tiramisu64.exe`（787MB）、`Tiramisu64-RootVdiDebug.7z`（1.6GB）等 |
| 发布目录 | `/home/henry/workspace/releases/bst-v5.22.210-9527/Tiramisu64/` |

---

## 二、与 Jenkins 对齐

| 项 | Jenkins #1375 | 本地 `build_Tiramisu64.sh` |
|----|---------------|---------------------------|
| 入口 | `build.sh` | 同左 |
| `OEM` | `nxt` | 默认 `nxt` |
| `ANDROID_IMAGES` | `Tiramisu64` | `Tiramisu64` |
| `FORCE_CLEAN` | `false` | 默认 `false` |
| `ENABLE_DEXOPT` | `true` | 默认 `true` |
| `ANDROID_BUILD_NUMBER` | 1375 | `BUILD_NUMBER`（默认 **9527**） |
| `BRANCH` | `bst-v5.22.210-hybrid` | 从 `android-13` git 分支读取 |
| `SYNC` | `sync.sh` | 默认 **`SYNC_SOURCE_CODE=false`** |
| `JAVA_HOME` | `java-8-openjdk-amd64` | 同左 |
| android | `make iso_img` + `make ramdisk` | 同 Jenkins |
| `OUT_DIR` | `out_nxt_Tiramisu64` | 同左 |
| `lunch` | `android_x86_64-eng` | 同左 |

### 本地路径默认值

| 变量 | 值 |
|------|-----|
| `OUTPUTDIR_PREFIX` | `/home/henry/workspace/releases` |
| `CCACHE_BASE` | `/home/henry/.ccache` |
| `ANDROID_SDK_PATH` | `/home/henry/workspace/android-sdk/sdk` |
| `FLUTTER_ROOT` | `/home/henry/flutter` |

### 启动编译

```bash
cd /home/henry/workspace/app-player/buildscripts
./build_Tiramisu64.sh
# 日志：../out-app-player-Tiramisu/logs/build_Tiramisu64-*.log
```

可选对齐 Jenkins 并行度：

```bash
export PARALLEL_NX_PROCESSORS_MAKEFILE=1/4
export PARALLEL_NX_PROCESSORS_BUILD_SH=1/2
./build_Tiramisu64.sh
```

---

## 三、buildscripts 层预处理（保留）

| 项 | 文件 | 说明 |
|----|------|------|
| `LC_ALL=C` / `LANG=C` | `build_Tiramisu_common.sh` | 避免 host 工具 locale 问题 |
| `fix_tiramisu64_vboxguest_module_param` | 同上 | amd64 vboxguest `CONST_4_15=const`（与 Pie64/Nougat64 相同思路） |
| `fix_android_sdk_local_properties` | 同上 | 将 scratch-rosen 各模块 `local.properties` 指向本地 SDK |
| `cleanup_stale_rootfs_artifacts` | 同上 | 重试前清理 Root.fs / VDI 残留（需 `sudo`） |
| `dataFS` 先 `mkdir` 再 `chown` | `buildscripts/Makefile` | 冷启动打包必需（见 4.1） |

与 Pie 不同：**无** `wrap_build_sepolicy_py3`（android-13 sepolicy 走 Soong，Jenkins 未单独包装）。

### 构建入口文件

| 文件 | 说明 |
|------|------|
| `buildscripts/build_Tiramisu64.sh` | 设置 Jenkins 参数，调用 `tiramisu_build` |
| `buildscripts/build_Tiramisu_common.sh` | 本地路径、预处理，再调 `build.sh` |
| `buildscripts/build.sh` | 与 Jenkins 相同，最终 `make vbox` + `create_zips.sh` |

---

## 四、遇到的问题与解决

按实际构建顺序整理。除 4.1 外均未改 AOSP 源码。

### 4.1 `Root.vdi`：`dataFS` 不存在导致 `chown` 失败（已修复，阻断首次构建）

**现象**（`build_Tiramisu64-260611-18-32.log`，AOSP 已编完，打包阶段失败）：

```text
In create_dataFS_dir_structure function
sudo chown -R .../Tiramisu64/dataFS || exit 1
chown: cannot access '.../Tiramisu64/dataFS': No such file or directory
make: *** [Makefile:153: Root.vdi] Error 1
```

**原因**：`create_dataFS_dir_structure` 在创建 `dataFS/app/` 等子目录之前先 `chown`；冷启动时目录不存在。Jenkins 增量构建时 `dataFS` 可能已存在，不易复现。

**修复**（`buildscripts/Makefile`）：

```makefile
mkdir -p $(OUTPUTDIR)/$(1) || exit 1
sudo chown -R $$(id -u):$$(id -g) $(OUTPUTDIR)/$(1) || exit 1
```

修复后第二次全量构建（`build_Tiramisu64-260611-23-49.log`）打包阶段正常通过。

---

### 4.2 本地需交互式 `sudo`（操作注意）

`cleanup_stale_rootfs_artifacts` 与 `Root.vdi` 打包（挂载 rootfs、`chown`、VDI 转换等）均依赖 `sudo`。Jenkins `build` 用户为免密 sudo。

**做法**：在可输入密码的终端执行 `./build_Tiramisu64.sh`；勿用 `nohup`/无 TTY 后台方式，否则清理或打包阶段会因 `sudo` 失败。

---

### 4.3 续编误触全量重编（操作注意）

`android`、`apks`、`libs` 在 Makefile 中为 `.PHONY`。不带 `-o` 单独跑 `make vbox` / `make Root.vdi` 会：

- 重跑 `apks`（Gradle 全量）
- 重跑 `android`（`iso_img` + `ramdisk`）
- 执行 `force-kernel-clean`，**删除** `out_nxt_Tiramisu64/.../obj/kernel/`

若中途中断，后续 `fastboot.vdi` 可能报 `obj/kernel: No such file or directory`。

**仅续编打包**（AOSP 已完成时）示例：

```bash
cd /home/henry/workspace/app-player/buildscripts
export BUILD_NUMBER=9527 BRANCH=bst-v5.22.210
export ANDROIDOUTPUTLOC=/home/henry/workspace/releases/bst-v5.22.210-9527
export ANDROID_SDK_PATH=/home/henry/workspace/android-sdk/sdk
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export LC_ALL=C LANG=C PATH="$PWD/bin:$JAVA_HOME/bin:$PATH"
PKG="${BRANCH}_Tiramisu64-${BUILD_NUMBER}"

make -j$(nproc) -f Makefile \
  -o android -o libs -o apks -o datafs \
  -o force-aidl-check -o force-kernel-clean \
  -o fastboot.vdi \
  Root.vdi \
  OEM=nxt IMAGE=Tiramisu64 ANDROIDOUTPUTLOC="$ANDROIDOUTPUTLOC" \
  PKG="$PKG" ENABLE_DEXOPT=true IS_HYPERV_BUILD=0 \
  ANDROID_SDK_PATH="$ANDROID_SDK_PATH"

bash -x create_zips.sh --branch "$BRANCH" --build-number "$BUILD_NUMBER" \
  --images Tiramisu64 --oem nxt
```

---

### 4.4 PlayOnCloud：Crashlytics 上传 503（自动重试后通过）

**现象**（`build_Tiramisu64-260611-23-49.log`，apks 阶段）：

```text
> Task :app:uploadCrashlyticsMappingFileRelease FAILED
java.io.IOException: ... response: 503 HTTP/1.1 503 Service Unavailable
```

**处理**：`build_bluestacks_apks.sh` 对失败 job 使用 `parallel --resume-failed` 自动重试；第二次 PlayOnCloud 构建成功并产出 APK。**无需改源码**，属 Firebase/Crashlytics 服务瞬时不可用。

---

### 4.5 APK lint：`target API level 31`（非阻断）

**现象**：`BstFakeGps`、`BS-Services` 的 `lintVitalRelease` 报：

```text
Error: Google Play requires that apps target API level 31 or higher.
```

**结果**：`failed_jobs=0`（lint 为 warning 级别），整体 apks 目标继续，**未导致构建失败**。若需上架 Play 再改各模块 `targetSdk`。

---

### 4.6 AOSP 构建提示（可忽略）

| 提示 | 说明 |
|------|------|
| `showcommands is no longer supported` | Makefile 仍传 `showcommands`；android-13 已废弃该参数，详细日志在 `out_nxt_Tiramisu64/verbose.log.gz` |
| `BOARD_PLAT_*_SEPOLICY_DIR has been deprecated` | Soong 弃用警告，不影响构建 |
| `environment variables changed: USE_CCACHE` | `lunch` 后 ccache 环境变化提示，可忽略 |

---

## 五、未采用的路径

与 Pie 本地经验一致，以下方向**未使用**：

- 从 Jenkins 拷贝 `out/` 热缓存
- 修改 AOSP sepolicy / adb / fastboot 等源码
- Pie 专用的 `wrap_build_sepolicy_py3`、`fix_pie_*` ninja 恢复脚本

Tiramisu（android-13）在 Ubuntu 22.04 上走 Jenkins 同款 Soong 流程即可编通，buildscripts 层补丁最少。
