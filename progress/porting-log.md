# 移植时间线（Porting Log）

append-only 叙事时间线（与 `patches/registry.json` 结构化数据互补）。每完成一个工作单元追加一条。

格式：
```
## YYYY-MM-DD — <patch-id> (<platform>)
- 源: <source_commit> (-a13/-mac fork, android-13) → 目标: android-16.0.0_r4
- 改动: <远程相对路径...>
- 冲突/解决: ...
- 验证: Layer 1 <cmd> exit=<n> 产物=<path>; Layer 2 <oracles> ...
- host-compat: ok / broken / pending
- 决策/上下文: ...
```

---

（Phase 0 导入定制清单后开始记录）

## 2026-06-18 — Phase 0 定制 triage 完成（win+mac）

- 远程 `markxu@clouddev`：`~/android-13`(win) 与 `~/android-mac`(mac) 子模块全部就绪（各 1056/1073）。
- triage 脚本遍历两树所有子模块，按「最新 android-13 tag..HEAD」+ `--author=bluestacks` 统计，写入 `patches/registry.json`（289 项）。
- 结果：win 75 项（44 真 bst>0 / 31 待复查）；mac 214 项（11 真 / 203 r83 标签漂移噪声）。
- 关键发现：**mac 自定义板 = `device/bst/qvirt`(bst8)**；win 设备 = `device/google/cuttlefish`+`device/generic/x86_64`；两端均有 `hardware/bst/*` BlueStacks HAL。
- 方法局限：mac 基线 r83 漂移严重（since 不可靠，以 bst>0 为准）；作者过滤可能漏非 bluestacks 邮箱的 mac 提交 → mac bst=0 的 device/frameworks 需人工复查。
- aosp16（目标 base）sync 首次因 googlesource 配额失败，已 `-c -j4` 重试进行中。
- 下一步：确认 lunch 目标（板定义）；复查 mac bst=0；aosp16 就绪后按 P1→P2→P3 port。

## 2026-06-18 — lunch target / 板：win 与 mac 不可统一（已确认）

- mac = `bst_arm64-userdebug`（`device/bst/qvirt`，arm64，BlueStacks 原创自定义板，含 fstab.bst/init.bst.rc + 自定义 HAL：gr-channel/vmsg/gps-legacy/gatekeeper-tailoff；android-16 无 device/bst，须 port）。
- win = `android_x86_64-userdebug`（`device/generic/x86_64`）或 `aosp_cf_x86_64_phone-userdebug`（`device/google/cuttlefish`，x86_64，上游已有，BlueStacks 仅删 apex + init）。
- 根因：① 架构不同 arm64(mac,Apple Silicon) vs x86_64(win)；② 虚拟设备模型不同 qvirt(自定义) vs cuttlefish/generic；③ 单 lunch target 只产一种 arch 镜像。
- 决策：**device/板按平台分别 port**；「guest 统一」= 系统源码(frameworks/system/应用)统一 port 到 android-16，device 配置分平台（与 registry 按 platform 分组一致）。

## 2026-06-18 — 采纳统一板方案 device/bst/qvirt（bst_arm64 + bst_x86_64）

- **决策（覆盖早前「不可统一」）**：两端共用 BlueStacks 自定义板 `device/bst/qvirt`，mac `bst_arm64`(arm64) + win `bst_x86_64`(x86_64 新增)；win 不再用 cuttlefish/generic。
- **验证**：① win host `app-player-dev/hd/Source/` 实现全部 qvirt 设备——`vmsg`(bstvmsg)、`hst`(bstpgaipc，11 命中)、`gr`(gr-channel)；mac `qvm` 同。② `hardware/bst/{audio,camera,lights,memtrack,power}` HAL 两端都有。
- 板配置(`device.mk`/`BoardConfig`/`init.bst.rc`/`fstab.bst`) arch 无关、共享；`bst_arm64.mk` 已有，需新增 `bst_x86_64.mk` + x86_64 BoardConfig。
- **待办**：win guest kernel 需 `bstvmsg`/`bstpgaipc` 驱动（两端 `drivers/` 未直接命中，源在 mac `kernel-mac` 22 个 bst 提交或 hd 随模块注入）→ 属 kernel P1 移植细节。
- Phase 1 重构：port 单一 `device/bst/qvirt` 到 android-16（arm64+x86_64 双 product）。

## 2026-06-18 — 路线修订 + 环境设置（三端）

- **路线**：① 三端环境设置 → ② **android-13 基线**（win+mac：guest 编译→打包→替换 host→运行测试）通过后才做 aosp16。定制清单重新生成（等子模块）。重构 SETUP-ROADMAP/README/remote-topology。
- **三端**：win host=本机 app-player(`.1033`✅, BlueStacks_nxt+Tiramisu 安装中)；mac host=`zeqing@172.16.0.204`(免密已设, BlueStacks.app✅)；guest=clouddev。
- **mac host**：`~/app-player-mac` 已 checkout 到 tag `bst-v5.21.700-nxt_mac2-5.21.700.7526`（detached, clean）；submodule 已 deinit（host 构建 hd/ggl 时按需 init；host 不需 android-mac）。deinit--all + checkout 绕过 submodule 冲突。
- **clouddev 构建布局（已定）**：win 用 `~/app-player`(buildscripts+hd) + `~/android-13`(根目录,作 ANDROIDHOME)；mac 用 `~/app-player-mac` + `~/android-mac`。**直接用根目录已 populate 的 ~/android-13/android-mac**（不重新 init submodule，太慢）。注意：clouddev `~/app-player` 当前 `A13Fixes-5.22.210.4301`、`~/app-player-mac` 当前 `Fortnite-5.21.700.4103`（均非目标 tag，hd-mac 恰在 .7526）；基线可先用现态，tag 对齐留待必要时。
- **端到端构建流程**已梳理入 `docs/build-flow.md`（buildscripts/Makefile 编排 guest：AOSP + hd 内核模块 mmm + 注入 initrd + Root.vdi）。

## 2026-06-22 — Phase 1 启动：win android-13 基线构建发起

- 环境就绪：clouddev `~/app-player` @ `.1033`（buildscripts+hd populated）；android-13 symlink→根 `~/android-13`；bst/3bt/opengl/tools/scratch-*/ggl-external-qemu 子模块 init 完成（SUBMOD_EXIT=0）。
- 预检通过：Java8(1.8.0_482)、磁盘 2.0T 可用、envsetup 在、make 变量解析正确（`out_nxt_Tiramisu64`）。
- 确定 IMAGE=**Tiramisu64**（buildscripts `JENKIN_ANDROID_IMAGES=="*Tiramisu64*"`；Makefile ANDROID_VERSION=tiramisu）。
- **发起构建**（后台 nohup）：`make -j$(nproc) -f Makefile vbox OEM=nxt IMAGE=Tiramisu64 IS_HYPERV_BUILD=0`（JAVA_HOME=java8, USE_CCACHE=1）；PID 720945；日志 `~/tiramisu_build.log`，exit 标记 `~/tiramisu_build_exit`。已见 libs/apks 阶段（scratch-rosen build_jar）推进。
- 监控 cron `25cb5887`（:16/:46）：完成报告 exit + Root.vdi 产物并自停；失败报错。
- 下一步（成功后）：打包 → 替换 win host `C:\ProgramData\BlueStacks_nxt\Engine` 镜像 → 运行测试。

## 2026-06-22 — 子模块版本对齐 .1033(win)/.7526(mac) + 构建重启

- 发现 .1033 superproject 的 submodule pin 不齐（bst@5.1.0、hd/qemu@5.22.999-ai-worker 等），用户要求全部切到各自版本 tag。
- **win**：9 个子模块（3bt/bst/opengl/tools/scratch-gaurav/scratch-rosen/ggl-external-qemu/hd/ggl-goldfish-opengl）全部 checkout 到 `bst-v5.22.210-5.22.210.1033`（rev-parse 权威核实 HEAD==tag commit ✅；describe 多样是 annotated-tag 显示 artifact）。
- 清半成品 out_nxt_Tiramisu64（被 kill 构建仅到 libs/apks），**重启 win 构建** PID 836905（同 `make vbox OEM=nxt IMAGE=Tiramisu64`），监控 cron `fa6314ce`。
- **mac**：子模块对齐到 `bst-v5.21.700-nxt_mac2-5.21.700.7526` 后台启动（PID 840712，init+checkout，`~/mac_submod_align.done` 标记）。

## 2026-06-22 — win android-13 基线构建失败（soong bootstrap，sqlite 模块重复）

- 构建退出 BUILD_EXIT=2（7.5min 处，soong bootstrap）：`error: external/robolectric/nativeruntime/external/sqlite/{android,dist}/Android.bp: module "libsqlite3_android"/"sqlite3"/"libsqlite" already defined`。
- 根因：`external/robolectric`（BS optimizations-424）把内嵌 `nativeruntime/external/sqlite` **钉在上游 `android-cts-11.0_r16`（41e1a36）**，其 Android.bp 定义模块名与顶层 `external/sqlite`（BS fork c512ae7）**完全同名** → soong 拒绝重复。
- pin 与 checkout 一致（robolectric submodule status 空格前缀）→ **非 init 不一致，是该 robolectric 版本固有冲突**。buildscripts 无相关 workaround。
- 待定（征询）：① 禁用/排除 robolectric 内嵌 sqlite 的 Android.bp（测试专用，镜像构建不需要）后重试；② ~/android-13 是否应处不同（release 一致）状态；③ BlueStacks 正常构建是否有已知 workaround。

## 2026-06-22 — 树状态根因定位 + 对齐 ~/android-13 到 .1033 pin

- **根因**：`~/android-13`（symlink 目标）HEAD=`be7d9511`=`bst-v5.22.210-perfOptimization-5.22.210.4400`（开发分支），**非** .1033 superproject 钉的 `eb45923b`。其子模块也不一致（robolectric/frameworks/base 为 `+`）→ perfOptimization-4400 状态下 robolectric 钉旧 CTS sqlite → 模块重复冲突。**sqlite 冲突是树状态错的症状**。
- **修复**：`~/android-13` checkout 到 `eb45923b` + `git submodule update --init --recursive`（对齐 1056 子模块到 .1033 一致 pin）。后台 PID 1018335，日志 `~/android13_realign.log`，exit `~/android13_realign_exit`，监控 cron `e748a2f5`（:20/:50）。
- checkout 中有 `unable to rmdir hardware/bst/*, external/{alsa-*,ffmpeg}: Directory not empty` 警告——待完成后核实 hardware/bst 等 BS HAL 仍在 eb45923b（非真删除）。
- 完成后（cron 自动）：核实 HEAD==eb45923b + hardware/bst 在 + 未对齐子模块≈0 → 清 out_nxt_Tiramisu64 → 重启 win 构建。

## 2026-06-22 — 同时对齐 android-mac 到 .7526 pin + 清单推迟

- **android-mac 同样错位**：实际 `5.21.720.7511`（ea54f03），**非** .7526 钉的 `86abb115`。启动对齐（checkout 86abb115 + recursive submodule update），PID 1022553，监控 cron `698605e8`（:22/:52），与 android-13 对齐并行。
- **定制清单推迟**：当前 457 项 registry 是基于错位树（perfOptimization-4400 / 5.21.720）生成，**作废**；待 android-13(.1033) 与 android-mac(.7526) 对齐 + win/mac 构建都通过后，从正确树重新生成。
- 序列：两端对齐 → win 构建 + mac 构建 都过 → 重新生成清单。

## 2026-06-23 — 干净重置：app-player 分支 + android-13 子模块（全本地 objects）

**用户调整**：放弃根目录 `~/android-13`/`~/android-mac`（错位/混乱，已删），改用 **app-player 的 android-13 子模块**；app-player 用 **`bst-v5.22.210` 分支**（非 .1033 tag）；android-16 软连根 `~/aosp16`；app-player-mac 暂不管（仍 init 中）。

**执行**：
1. app-player 原只有 `.git`（含所有仓库 objects）→ `git checkout -f bst-v5.22.210` populate 工作树（HEAD=8ed098751，buildscripts/Makefile + build.sh 在）。
2. android-13 子模块 pin = **eb45923b**（与 .1033 同）→ `git submodule update --init android-13` populate（Android.bp/build/art/bionic 全在）✅。
3. **关键**：app-player `.git` 含全部仓库 objects——连原 404 的 `external/libtraceevent` 都能 checkout（fd0f027b）。recursive init 全本地、**无 404、无需 clone**（之前根树 404 噩梦是因根树 .git 缺 objects）。
4. android-13 recursive init（1055 子模块）后台启动（PID 26947，`~/a13_rec_exit`）。
5. host 构建子模块 init：hd/bst/3bt/opengl/tools/scratch-*/ggl-external-qemu ✅（hd/Source/Makefile 在）。
6. `android-16 -> ~/aosp16` 软连 ✅（envsetup 可达）。

**待**：android-13 recursive 完成 → 启动 win android-13 编译（`make android OEM=nxt IMAGE=Tiramisu64`，java8/LC_ALL=C，FORCE_CLEAN=false，后台无 sudo）。

**记录约定**：每步+问题+解决详细记入本 log；内部参考（他人目录/引用文档）不写入。

### 问题 1：recursive init 卡在 `packages/modules/BootPrebuilt/5.4/arm64`（2026-06-23）
- **现象**：android-13 recursive init 跑到 ~1014 子模块后 36 分钟无新日志；卡在 `packages/modules/BootPrebuilt/5.4/arm64`（oid 3130a05a），`git submodule--helper run-update-procedure --just-cloned` 一直 fetch。
- **根因**：该子模块 oid 非本地 object（`.git` 未含 BootPrebuilt 预编译内核全部 objects）→ git 尝试从远程 fetch → 挂起。
- **解决**：BootPrebuilt = 预编译内核（arm64 5.4/5.10），x86_64 Tiramisu 编译用不到。kill 卡住进程 + `git submodule deinit -f packages/modules/BootPrebuilt` + `submodule.<...>.update=none` + 重跑 recursive。重跑已绕过 BootPrebuilt、继续（DnsResolver 等）。
- **教训**：`.git 含全部 objects` 不绝对（预编译/大 binary 子模块可能缺）；recursive init 遇 fetch 挂起时，deinit 该子模块（若构建不需要）+ 重跑。

### 问题 2：`build/envsetup.sh` 不存在 → 构建立即失败（2026-06-23）
- **现象**：`make android` 立即 `build/envsetup.sh: No such file or directory` + `Error 1`（Makefile line 319）。
- **根因**：android-13 的 `build/` 子模块（bluestacks/build-a13.git @ e6b7647，.1033 pin）根目录**无 envsetup.sh**——实位于 `build/make/envsetup.sh`。Makefile `android` target source 的是 `build/envsetup.sh`（相对 ANDROIDHOME）。
- **解决**：对照已知工作设置，`build/envsetup.sh` 应为指向 `make/envsetup.sh` 的软连（本地适配）。`ln -sf make/envsetup.sh android-13/build/envsetup.sh`。修复后 `make android` 过 envsetup，进入 `make iso_img -j30` + `make ramdisk`（真正 AOSP 编译）。
- **状态**：win android-13 编译进行中（PID 122867，后台，仅 iso_img+ramdisk 无 sudo）。

### 规则：子模块 init 后需切到对应分支
- **用户明确**：每个 submodule `git submodule update --init` 后处于 detached HEAD（钉在 superproject 记录的 SHA），**必须 checkout 到 `.gitmodules` 中对应的 `branch`**（如 `kitkat-master`）。这是构建正常工作的前提（类似 henry sync.sh 后的 `restore_branch.sh` 步骤）。
- **当前状态**：android-13 的 recursive init 后各子模块在 detached，但 win 编译已启动（中途切分支会破坏源码）→ **本轮编译完成后**（无论成功/失败），对 android-13 子模块执行 `git submodule foreach --recursive 'git checkout $(git config -f $toplevel/.gitmodules submodule.$name.branch)'` 切分支，再重试编译。

## 2026-06-22 — 阻塞：submodule update 遇不可访问仓库（Repository not found）

- 两端 checkout 都成功（android-13 HEAD=eb45923b、android-mac HEAD=86abb115 ✅），但 **recursive submodule update 都失败**（exit 1）。
- 根因：部分 .gitmodules 引用的 BlueStacks 仓库 **`Repository not found`**（仓库不存在或私有且 clouddev key 无权——github 对无权私有仓也返 not found）：
  - android-13：`bluestacks/external-libtraceevent-a13.git`
  - android-mac：`bluestacks/kernel-prebuilts-common-modules-virtual-device-4.19-arm64-mac.git`
- 非 rate-limit（ls-remote 确认 not found）。recursive update 在首个不可访问仓 abort，可能还有更多。
- 之前用户的 recursive init「完成」(1056/1073) 是在**旧错位状态**（perfOptimization-4400 / 5.21.720），其 .gitmodules 可能未引用这些仓；.1033/.7526 的 .gitmodules 引用了。
- **待用户定**：① clouddev github key 是否对全部 bluestacks 仓有访问权（这俩是私有需授权？）；② BS 正常构建如何访问（不同 key？manifest 排除？）；③ 这些仓是否构建必需（可否 skip）。已停两个 realign cron。

## 2026-06-22 — `-a13` 根因 + 容忍式 update（跳过无 bst fork）

- **用户澄清**：clouddev 有全访问权 → 这些仓确实不存在。`external-libtraceevent-a13` 无此 fork（只有上游 `external-libtraceevent`，无 bst 改动）。**无 bst 分支的子模块跳过 checkout**。
- **`-a13` 根因**：android-13 的 `.gitmodules` 用 BS fork 命名约定 `bluestacks/<name>-a13.git`（`-a13`=android-13 fork），**对所有子模块套用**。BS 只 fork 了有改动的仓；未 fork 的（libtraceevent/libtracefs/okhttp4 等上游无改动）其 `-a13` 仓不存在 → 悬空 URL → 404。
- **修复**：容忍式 update 脚本（`~/tolerant_submod.sh`）——bulk `git submodule update --init --recursive` 遇 404 则把该 submodule `update=none` 跳过、重试，直到所有可访问的更新完。android-13/android-mac 并行跑。
- **规模小**：仅 ~3-5 个未 fork 仓（android-13: libtraceevent/libtracefs/okhttp4；android-mac: ~2）。监控 cron `3087f4f7`（:24/:54）→ android-13 对齐完成自动重启 win 构建。
- **风险**：跳过的仓留空；若构建需其源码（libtraceevent 等），后续改用上游 checkout。

## 2026-06-23 — win android-13 编译全过程（问题与修复记录）

**编译配置**：app-player @ bst-v5.22.210 分支；android-13 子模块 @ eb45923b；`make android OEM=nxt IMAGE=Tiramisu64 IS_HYPERV_BUILD=0`（仅编译 iso_img+ramdisk，无 sudo）。FORCE_CLEAN=false，JAVA_HOME=java-8，LC_ALL=C。

### 问题 A：`build/envsetup.sh` 不存在（构建立即失败）
- **现象**：`make android` 立即 `build/envsetup.sh: No such file or directory`。
- **解决**：`ln -sf make/envsetup.sh build/envsetup.sh`（对照 henry 同款软连）。

### 问题 B：`device/generic/common/x86_64.mk` 缺失（22s 失败）
- **现象**：`device/generic/x86_64/android_x86_64.mk: error: device/generic/common/x86_64.mk does not exist`。
- **根因**：`git submodule update --init` 把 android-13 子模块放 detached HEAD（pinned SHA），该旧版 SHA 缺此文件；切到 `bst-v5.22.210` 分支 tip 后文件存在。
- **解决**：所有 android-13 子模块 checkout 到 `bst-v5.22.210`（`xargs -P 32` 并行）。**核心教训：子模块 init 后必须切分支——pinned SHA 是旧版，构建需要分支 tip 文件。**

### 问题 C：sqlite 模块重复定义（soong bootstrap）
- **现象**：`module "libsqlite3_android"/"sqlite3"/… already defined`（external/robolectric/nativeruntime/external/sqlite 与 external/sqlite）。
- **解决**：`mv external/robolectric/nativeruntime/external/sqlite/{android,dist}/Android.bp` → `.disabled`（测试专用，构建不需要）。

### 问题 D：arm64 内核预编译 Android.bp 缺源
- **现象**：`kernel/prebuilts/5.10/arm64/kernel-5.10 does not exist`。
- **解决**：`find kernel/prebuilts -path '*/arm64/Android.bp' -exec mv {} {}.disabled \;`（5 文件）。x86_64 编译走 kernel64-hyperv，不依赖 arm64 预编译。

### 问题 E：ggl/goldfish-opengl-pie 等 8 个子模块未 init
- **现象**：编译中报 `../ggl/goldfish-opengl-pie` 未找到；scratch-gaurav checkout 失败。
- **解决**：除 android/android-9/android-11 外的全部 app-player 子模块 `git submodule update --init` + `xargs -P 32 checkout bst-v5.22.210`。

### 问题 F：内核编译 pahole 被 PATH 限制拦截（核心编译阻塞）
- **现象**：`"pahole" is not allowed to be used`，bzImage 构建失败。`TEMPORARY_DISABLE_PATH_RESTRICTIONS=true` 已废弃无效。
- **排查**：① defconfig 加 `# CONFIG_DEBUG_INFO_BTF is not set` + 删 `CONFIG_PAHOLE_VERSION` → 仍调 pahole（pahole-flags.sh 无条件版本检测）；② 从 henry 拷贝 `prebuilts/ktools/kernel-build-tools` + 建 `prebuilts/kernel-build-tools` 软连 → pahole 就位但被 interposer 拦截；③ 对照 henry 确认同样 defconfig(`DEBUG_INFO not set`)和同样 `.path/pahole` 软连。
- **根因**：AOSP soong 构建在 `out_nxt_Tiramisu64/.path/` 为每个工具建软连 → `.path_interposer`。内核构建通过该目录调 pahole 时，interposer 按工具名拦截 pahole。
- **解决**：替换 `.path/pahole` 指向真实预编译 pahole：`ln -sf prebuilts/ktools/kernel-build-tools/linux-x86/bin/pahole out_nxt_Tiramisu64/.path/pahole`。绕开 interposer，内核直接找到真 pahole。

### 问题 G：子模块在 detached HEAD（非分支）
- **用户明确**：每个 submodule init 后必须 checkout 到对应的 `.gitmodules` branch（非 detached）。app-player 层切到 `bst-v5.22.210`；android-13 子模块按 `bst-v5.22.210` 分支。
- **执行**：`git submodule foreach --recursive` 因顺序执行太慢 → `xargs -P 32` 并行 checkout。libcore 无此分支保持 HEAD。

### 关键经验
1. **子模块 init 后切分支**是必须的——pinned SHA 是旧版，构建需要的文件/修复在分支 tip。
2. **内核 pahole**：interposer 通过 `.path/` 软连拦截工具，替换为真二进制绕过。
3. **禁止修改 AOSP 源码**，但 buildscripts/setup 层适配（软连、禁用 Android.bp、PATH 修正）是可以的。
4. 每个编译失败必须**对照已有工作设置**确定是适配缺失还是真 bug。
5. 编译当前状态：PID 256874 进行中。

## 2026-06-24 — ✅ Root.vdi + fastboot.vdi 打包成功 + Windows 替换

- **`make Root.vdi` 成功**（BUILD_EXIT=0），产物 1.9G @ `~/releases/Tiramisu64/bst-v5.22.210_Tiramisu64-local/`。
- **fastboot.vdi**（预制品，11M，从 `hd/guest/BootImage/fastboot/`）。
- **打包阻塞问题**：
  - **scratch-gaurav 工作树不完整**（init 时 checkout 失败）→ `git checkout -f bst-v5.22.210` 恢复 → prop 文件出现。
  - **chown 1000:1000 硬编码**→ 修 Makefile 为 `$(shell id -u):$(shell id -g)`（markxu UID=1011）。
  - **sudo 免密**→ `NOPASSWD: ALL` sudoers.d 配置。
  - **create_setuid_su_binary 残留**（bstk/ su chmod 0511 使 cp 失败）→ 清 releases 重来。
  - **apks local.properties**→ 42 个模块设 `sdk.dir=/home/henry/workspace/android-sdk/sdk`。
- **APK 构建问题（2 个跳过）**：
  - **AndroidLauncher**：缺 `flutter`（命令行不可用，需从 henry 复制/下载）。
  - **BFM**：Gradle 缺 `io.realm:realm-gradle-plugin:4.2.0`（maven 不可达，需更新或代理）。
- **Windows 替换（首次，格式错误）**：scp Root.vdi → 发现引擎用 **Root.vhd**（非 .vdi）。改 scp Root.vhd（1.8G）替换。但**启动失败**：BstkCore.log `Power up failed (hrc=E_FAIL)`。已还原历史版本（能启动）。
- **下一步**：启动 BlueStacks Tiramisu64 实例测试启动；解决 APK 编译问题（flutter 安装 + BFM 依赖）。

## 2026-06-24 — ✅ APK 编译三问题全部解决 + launcher 注入镜像重打包

### 三个 APK 问题的真正根因与修复

1. **AndroidLauncher（flutter）** ✅ 解决
   - 根因：henry 的 `~/flutter` 目录权限隔离（`Permission denied` 读 cache 文件）+ git `dubious ownership`。
   - 修复：`sudo cp -r /home/henry/flutter ~/flutter && sudo chown -R markxu:markxu ~/flutter` + `git config --global --add safe.directory '*'`。flutter 3.24.5 可用，APK（com.uncube.launcher3.apk 40MB）编出。

2. **BFM（realm-gradle-plugin）** ⏭️ 跳过（非核心）
   - 根因：clouddev 无法访问 maven central / jcenter（corp 网络阻断），gradle 解析 `io.realm:realm-gradle-plugin:4.2.0` 失败。
   - 处理：build.sh 改 exit 0（skip）。BFM 非 boot 关键。

3. **`make apks` 整体失败（空 dir job）** ✅ 解决——**这才是阻塞 launcher 进镜像的真因**
   - 最初误判为 `-j100` OOM（`num_proc = nproc×5 = 100`，58GB 内存不够 100 个 gradle daemon），降 `PARALLEL_NX_PROCESSORS=0.3` → `-j6` **无效**。
   - 真因：**`build_nowgg_common_apks.sh` 失败**——`nowgg-common` 是断链软连 → `/home/build/workspace/nowgg-common`（clouddev 实际路径 `/home/clouddev/bst/workspace`），且脚本硬编码 `WORKSPACE_DIR="/home/build/workspace"` + 需 `git clone git@github.com:bluestacks/nowgg-common.git`（clouddev 无 github 权限）。**henry 也没有**——原构建机环境差异，clouddev 不可得。
   - nowgg 失败 → `make apks` 的 **line 345 复制步骤（scratch-rosen/apks/*apk → APKFOLDER）从未执行** → APKFOLDER 缺 23 个 apk（**含 launcher 本身**），已编译的 rosen apk 全卡在 scratch-rosen/apks/。
   - 修复：`build_nowgg_common_apks.sh` 改 no-op（已备份 .orig；buildscript 层适配，合规）。nowgg apk（now.gg.billing.service 等）之前构建已在 APKFOLDER。
   - **重跑 make apks 成功**（BUILD_EXIT=0），launcher + rosen apk 进 APKFOLDER，GMS 从 `scratch-gaurav/gapps_tiramisu64/` 由 datafs target 的 `copy_g_p_all` 注入。

### 镜像 apk 完整性
- APPCONFFILE（`bst/apks/tiramisu/tiramisu_appPlayerApksToInstall_nxt_tiramisu64`）引用的 apk 经 line 345（rosen）+ copy_g_p_all（GMS）注入 APKFOLDER。
- `com.bluestacks.filemanager.apk` 源码树无 → **从 henry scratch-rosen/apks 拷入** markxu scratch-rosen/apks（line 345 会带上）。GMS（12 google + chrome）由 datafs `copy_g_p_all` 从 `scratch-gaurav/gapps_tiramisu64` 注入（push 列表已覆盖）。

### ⚠️ 坑：make Root.vdi 全量重编 → 改用 `make -o` 定向重打包
- **首次 `make Root.vdi` 重打包（PID 2911646）触发全量 android 重编**：日志 `[0% 251/101364]`，soong 报 `make_vars-android_x86_64.mk was modified, regenerating` → ninja 全图标记脏 → 101364 target 全编（~4h，load 68 下 6h+）。对「只改 apk」的变更是纯浪费（system 未变）。
- **已杀全量重编进程组**（PGID 2911644；残留 henry Baklava + eminhuang AOSP-A13 是他人构建，未误杀）。
- **改用定向重打包**（PID 3307251）：`make -o android -o libs -o apks -o datafs Root.vdi`——`-o`（assume-old）跳过 4 个 phony 依赖，**只跑 recipe body**（copy_android_files_to_outputdir → copy_data_apks 注入 launcher → create_rootfs → make_vdi_file），复用已编译 system，~10-30min。dry-run 验证无 `make iso_img` = 正确。
- **教训已写入 `docs/build-commands.md`**（「Root.vdi 重打包：用 make -o 跳过 android 重编」节），防下次重复踩坑。
- 何时用完整 make Root.vdi：android 源码真变了；何时用 make -o：只改 apk/配置/buildscripts。

### ⚠️ 启动风险（未闭环）
- 新构建镜像（bst-v5.22.210 android-13）**首次替换启动失败**（VBox Power up failed），历史版本能启动。重打包替换后**必须验证能否启动**——这是独立的 guest/打包层问题，待诊断。

## 2026-06-25 — ✅✅ Win Tiramisu64 镜像启动到 launcher（里程碑）

**win guest android-13 镜像（bst-v5.22.210）首次成功启动到 launcher。** 完整链路打通：全量重编 → apk 注入（launcher+GMS+filemanager）→ VHD 打包 → UUID 匹配 → Windows 替换 → BlueStacks 启动。

### 关键根因：VBox Power up failed = UUID 不匹配（非 guest 问题）

- **症状**：BlueStacks Tiramisu64 启动 `Power up failed (hrc=E_FAIL)`，0.46 秒立即失败（VM 都没开始执行，与 launcher 内容无关）。
- **根因**：Makefile `make_vdi_file` 用 `vboxmanage internalcommands sethduuid`（无参数=随机新 UUID）。clouddev build 端靠 `sed 删 VirtualBox.xml + sethduuid` 自洽重新注册，但 **Windows 端 `Tiramisu64.bstk` 仍记录旧介质 UUID** → VBox 找不到匹配介质 → 立即失败。
- **修复**：clouddev 上 `sethduuid` 把新产物 UUID 改成 Windows `.bstk` 记录的值：
  - Root.vhd → `54e9ad31-a169-4d5b-a0e0-705d62e96e71`
  - fastboot.vdi → `91b80c95-aa7d-459d-93e4-c479f5babbb7`
- **教训**：跨机器替换 VHD/VDI 时，UUID 必须匹配目标 `.bstk`（不是源 build 机的随机 UUID）。

### make_vdi_file 的 clonehd 偶发失败

- `vboxmanage clonehd Root.vdi → Root.vhd` 在 Makefile 内有时 `VBOX_E_FILE_ERROR`（sethduuid 改 UUID 后 medium registry 未注册）。单独跑 clonehd 成功（100%）。Root.vdi 数据有效（2.5G VDI 格式），clonehd 失败时单独重跑即可。

### 固化脚本（防重复踩坑）

已写入 `bst-aosp/scripts/`：
- **`clouddev-build-tiramisu64.sh`**（clouddev 端）：`full`/`repack`/`uuid` 三子命令。内置全部坑修复（chown UID、bstk 残留、sudo 清理、nowgg skip、filemanager 补齐、clonehd 修复、UUID 匹配 .bstk）。
- **`win-replace-tiramisu64.ps1`**（Windows 端）：停 BlueStacks → scp（UUID 已匹配）→ 备份 → 替换 → 验证。

### 全流程命令（固化后）
```bash
# clouddev: 全量重编(android 变了, ~4h)
~/clouddev-build-tiramisu64.sh full      # 等 BUILD_EXIT=0
~/clouddev-build-tiramisu64.sh uuid      # clonehd 修复 + UUID 匹配 .bstk

# Windows: 替换 + 启动
\scripts\win-replace-tiramisu64.ps1
& "C:\Program Files\BlueStacks_nxt\HD-Player.exe" --instance Tiramisu64
```

## 2026-06-24 — app-player-mac 子模块初始化（clouddev，并行 win 重打包）

- **superproject checkout**：`bst-v5.21.700-nxt_mac2-Fortnite-...4103`（detached @ c292b8f）→ checkout `bst-v5.21.700-nxt_mac2`（同 commit c292b8f，干净切换）✅。
- **坑**：之前中止的 `git status` 远程进程没被 TaskStop 杀（只杀本地 SSH），残留持有 `.git/index.lock` 阻塞 checkout → 手动 kill PID + 删锁；`pkill -f "git status"` 误杀自身 ssh（命令串含该模式）→ 避免，用 PID 直杀。
- **顶层 init**（非递归，9 子模块）：✅ 全部初始化且匹配 index（基分支与 Fortnite tag 同 commit，记录 SHA 一致）。
- **bst 嵌套**：`bst/contrib/android` 有 staged 删除（`.gitignore/.gitmodules/Makefile` 全 D）阻塞递归 → `git -C bst submodule update --init contrib/android` 重置 ✅。
- **全量 recursive init 失败但不需要**：`git submodule update --init --recursive` 卡在 android-mac 1073 嵌套子模块（slow clone libtraceevent/libtracefs）+ bst 递归失败。但 android-mac 按 topology **已 init（完整 AOSP 树 + kernel，frameworks/base 在）**，触发 recursive 是过度重同步。→ 不强制全量 recursive。
- **mac 混合版本 pinning（与 win 不同）**：mac 子模块 pin 在混合版本分支（android-mac@720 / bst@705 / hd@700 / scratch-rosen@715 / tools@770），不像 win 全在 `bst-v5.22.210`。pinned SHA 落后各分支 tip（android-mac 86abb11 vs ea54f03）。**pinned 是集成测试组合**——不投机性统一切 `bst-v5.21.700-nxt_mac2`（会破坏测试组合）。切分支决策 **DEFERRED**：等 mac 实际构建验证 pinned 是否够用（verify-by-readback），需 tip 再切。
- **状态**：app-player-mac 顶层就绪（pinned/tested SHA），android-mac 有完整源码，可进入 mac 构建评估。

## 2026-06-25 — android-16 win 编译启动准备：henry boot patches 抓取

下一里程碑：编译启动 android-16 win。先抓取 henry 在 android-16（Baklava, bst-v5.22.210）上的 boot 修改。

### 关键：必须用 henry 身份跑 repo diff
- markxu 跑 `repo diff` 输出 0（文件权限）。
- `sudo -u henry bash -lc "cd android-16 && repo diff"` 才看到 **1125 行**修改。后续复查同样必须 henry 身份。

### 抓取结果 → `references/android-16-boot-patches/`（commit 56cab66）
- `00-buildscripts.patch`：app-player buildscripts 层适配（Makefile/build.sh/create_vdi/create_zips + build_nowgg）
- `01/02-build_Baklava*.sh`：henry 的 android-16 构建封装（untracked 新文件，镜像 Tiramisu64 流程）
- **`10-aosp-repo-diff.patch`**：AOSP 树 **12 项目 1125 行核心 boot patch**：
  - build/make（BOARD_KERNEL_CONFIG_FILE/VERSION override——BST bzImage 无 IKCFG；hwservicemanager 从 system_ext 移到 /system）
  - build/soong, device/generic/{common,x86_64}, external/boringssl
  - frameworks/{base,native}, hardware/{gfxstream,interfaces,libhardware}
  - system/core, system/hwservicemanager
- `20-22 kernel-a16-*`：working diff（仅 prebuilts 指针）+ status + HEAD（bst-v5.22.210）

### kernel-a16 复制到 markxu `~/aosp16/kernel-a16`
- 源码 1.3G ✅ 复制完成 + chown markxu。
- **.git 指针问题**：kernel-a16 的 `.git` 是 53 字节 gitdir 指针 → henry 上级 `.git/modules/android-13/modules/kernel`（kernel-a16 作为 submodule 注册在 android-13 module 下）。源码 cp 没带 gitdir。
- **gitdir 3.1G**（百万 commit 历史）复制到 `~/aosp16/kernel-a16/.git_kernel` + 改 `.git` 指针自包含（后台进行）。

### 下一步（kernel gitdir 复制完成后）
1. apply buildscripts patch + 复制 Baklava 脚本到 markxu app-player
2. apply AOSP 12 项目 patch 到 ~/aosp16（repo diff 格式需逐项目）
3. 跑 build_Baklava64.sh 全量编译 android-16 win
4. 同 Tiramisu64 流程打包 Root.vhd + UUID 匹配 + Windows 替换 + 启动验证

## 2026-07-14 — ✅✅ M1：android-16 win boot 到 launcher + 优雅关机

**里程碑达成**：A16 guest（Baklava / `android-16.0.0_r4`）在 win 上完整源码构建并启动到 launcher，Settings 可见，点 HD X 优雅关机（无 20s 强制断电）。

- lunch：`android_x86_64-trunk_staging-eng`；板路径实际为 `device/generic/common` + `device/generic/x86_64`（**非**当时主线 `device/bst/qvirt`）。
- 存档：`patches/android-16/RESTORE.md`（20 tracked + 92 untracked + bootimage + kernel config）；完整性经 `git apply --check --reverse` 16/16 通过。
- 问题全流程：`progress/android-16-boot-guide.md`（12 阶段）。
- 最终 Root.vhd md5（TEMP R262b）：`7a55ef636b0961c87bd0815cfc5c8cde`。
- **性质**：能 boot = 真 BST 定制 + **大量临时 bringup hack** 的混合态；下一步须融合转正。

## 2026-07-15 — 回归结构化主线 · 进入 Phase 1 清单融合移植

- **决策**：① Phase 1 迁移到统一板 `device/bst/qvirt`（同一份板，x86_64/arm64 各自定制）；② 双端清单重新生成；③ win 验证 / mac 基于同码开发不独立验证；④ 工作单元 = patch-group，每组全验证回环 + 存 patch + checkpoint；⑤ 每次修改加埋点与测试。
- **流程落地**：重写 `SETUP-ROADMAP.md`（M0/M1 归档 → Phase 1/2/3）；更新 `architecture.md` §4.2 回归决策；新增 rules：`dual-platform-customization` / `platform-win-first-mac-reuse` / `instrumentation-and-tests`；`patch-porting` + `/port-patch` 升级为 patch-group；registry → v2。
- **双端清单重生成（完成）**：
  - 远程 `triage_focused.sh`：win `~/app-player/android-13` @ `bst-v5.22.210` → 78 行（修复后 39+补全）；mac `~/app-player-mac/android-mac` @ `bst-v5.21.700-nxt_mac2` → 68 行。
  - 关键补全：win `frameworks/base` bst=**220**、`frameworks/native` 71、`device/generic/common` 63、`system/core` 29；mac `frameworks/base` bst=68；`device/bst/qvirt` 目录存在（统一板源）。
  - registry v2：**137** 条（23 boot-archived + 清单 pending）；`temp_debt` 4；P1/P2/P3 = 62/64/11。
  - v1 备份：`patches/registry.v1.backup.json`。
- **计划成文**：`progress/phase1-port-plan.md`（G1–G10）· `progress/phase2-port-plan.md`（临时债/其余/mac）。
- **下一步**：开 **G1**（generic → qvirt，Layer2 boot 回归 gate）。
- 入口：`patches/registry.md` / `SETUP-ROADMAP.md`。

## 2026-07-15 — 计划 review · 修正 6 项问题（开 G1 前）

review 发现并修正：
- **P0 Phase1 scope 误判**：`frameworks/base`(win bst=220)/`native`(71) 等全项目整包被误标 P1。改：全项目特性集 → **P2**（`P2-FRAMEWORK-REST`）；G5 只做 boot-minimal 子集（对齐 `boot-frameworks-*` 存量）。
- **P1 清单不全**：`triage_focused` external 因 timeout 漏采（win 仅 27）。远程 `triage_external.sh`（647 repo，timeout↑ + 补 keyword）补采 → **win 86 / mac 4**。registry 137 → **196**。
- **P2 G8 噪声**：13 个 mac Pixel/物理设备 HAL（google/pixel、gs101/201、nfc、wlan…）与 qvirt 模拟器无关 → `dropped`。
- **P3 移植机制未定**：新增 **fork-diff overlay**（禁 220 次 cherry-pick）写入 `patch-porting.md` + `/port-patch`。
- **P4**：清 `mac-system-core` bogus `since=46428`（r83 误配）。
- **P5**：G1 加**安全网序**（并存 `bst_x86_64` product → diff 对比 → Layer2 → 再下线 generic）。
- **P6**：`platform-win-first-mac-reuse.md` 加 mac 分歧风险（arm64/qvm 不被 win 验证覆盖，须登记 `mac-behavior-deferred`）。
- registry v2：196 条（23 boot-archived + 13 dropped + 4 temp_debt）；P1/P2/P3 = 45/127/24；P1 pending 非 boot = 25。
- **下一步不变**：开 **G1**。

## 2026-07-15 — G1 启动 · 统一板脚手架（进行中）

**G1**（`device/generic/*` → `device/bst/qvirt` / `bst_x86_64`）已启动，按安全网 step1：**generic 与 qvirt 并存**，不删 M1 boot 路径。

- **脚手架**：新增 `device/bst/qvirt/` 三文件（`AndroidProducts.mk`、`BoardConfig.mk`、`bst_x86_64.mk`）。
  - 策略：`bst_x86_64.mk` 继承 `device/generic/common/x86_64.mk`（M1 已验证内容），仅 override 产品身份（`PRODUCT_DEVICE=qvirt` 等）；`BoardConfig.mk` 复用 `device/generic/x86_64/BoardConfig.mk`。
  - 埋点：build-time `A16DBG:G1: building unified board bst_x86_64 (device=qvirt) from a16 generic overlay`。
- **本地存档**：`patches/android-16/untracked-src/aosp16__device_bst_qvirt/`。
- **远程**：`markxu@172.16.6.191:~/aosp16/device/bst/qvirt/` 已部署。
- **验证（已完成）**：`lunch bst_x86_64-trunk_staging-eng` → `TARGET_PRODUCT=bst_x86_64` ✅。
- **待办**：Layer1 `m systemimage` → 与 M1 generic 产物 diff → Layer2 boot 回归 oracle → 存 patch + checkpoint。
- **checkpoint**：[`patches/android-16/checkpoints/G1.md`](../patches/android-16/checkpoints/G1.md)。
- **mac 参考**：`~/app-player-mac/android-mac/device/bst/qvirt` 完整 a13 板树存在；G1 阶段**不整包引入** a13 HAL，win 绿后再做 `bst_arm64` 差异。

## 2026-07-15 — G1 Layer1 构建 + 配置等价验证

- **配置等价（step2 gate 预检）**：`g1_equiv_check.sh` — `android_x86_64` vs `bst_x86_64` soong dumpvars（PRODUCT_PACKAGES / COPY_FILES / SEPOLICY / kernel cmdline 等 10 项）→ **EQUIVALENT: config-level identical** ✅。
- **Layer1 构建（进行中）**：
  - 命令：`~/g1_build.sh`（`lunch bst_x86_64-trunk_staging-eng && m systemimage -j24`）。
  - OUT：`out_nxt_Baklava64/target/product/qvirt/system.img`。
  - PID：**3060911**（soong **3061356**）；log：`~/g1_build.log`。
  - 进度：~8%（114882 targets，ETA ~8h，2026-07-15 12:22 起）。
  - 恢复观测：`ssh markxu@172.16.6.191 'ps -p 3060911; tail -20 ~/g1_build.log; grep A16DBG ~/g1_build.log'`
- **下一步**：构建完成 readback（exit rc + system.img md5 + installed-files.txt）→ 与 M1 generic 产物 diff → Layer2 boot 回归。

## 2026-07-15 — G1 Layer1 成功 + HAL 修复 + Layer2 打包进行中

**Layer1（✅）**：
- `A16DBG:G1: build exit rc=0`（15:51:55，耗时 12:02）
- `system.img`：**1,986,658,304** bytes，md5 **`a5a6781213e76fd71910d6cd7e8a6396`**
- `installed-files.txt`：3588 行
- 配置等价：`g1_equiv_check.sh` → **EQUIVALENT**（android_x86_64 ≡ bst_x86_64）
- 注：与 M1 首个 boot `system.img` md5（`f3228328…`）不同——预期差异（HAL 新编译 + `PRODUCT_DEVICE=qvirt`）

**HAL A16 编译修复（G8 前置，阻塞已清）**：`hardware/bst/{camera,memtrack,lights,power,audio}` → 存档 `patches/android-16/untracked-src/g1_hal_fixes.tar.gz`

**Layer2 准备（进行中）**：
- `g1_stage_system.sh`：从 qvirt `system.img` 的 `system/` 子树 stage → `releases/Baklava64/system/`（`build.prop` @ 顶层 ✅）
- `g1_pack_root.sh` → `r228-pack-root.sh`（Root.vhd 重打）后台运行
- **待 win host**：替换 `Engine\Tiramisu64\Root.vhd` → 跑 RESTORE §7 boot oracle

**下一步**：Root.vhd md5 readback → win 部署 → Layer2 boot 回归 → G1 checkpoint `ported`。

## 2026-07-15 — G1 Layer2 boot 回归 ❌（vendor HAL 崩溃循环）

**打包（✅）**：`system.sfs`=`b23127ed…`；`Root.vhd`=`e508ad44b34f6701c07d09d605d0dc24`（M1=`7a55ef63…`）。

**win 部署（✅）**：`g1_win_deploy.ps1` md5 一致。

**Layer2 oracle（❌）**：PASS `init second stage`/`odsign`/`system mounted`；FAIL `boot_completed`/launcher/ready。根因：`camera-provider-2-4` 4×、`health@2.1` register fail、`drm-hal` SIGABRT → `updatable_crashing` 循环。fingerprint=`bst/bst_x86_64/qvirt` ✅。详情：[`G1-layer2-failure.md`](../patches/android-16/checkpoints/G1-layer2-failure.md)。

**判断**：G1 身份/打包正确；全量刷新 system 后 vendor HAL 未达 M1 稳态 → **G8 阻塞 G1 关门**。

## 2026-07-15 — G8 v2：vendor rc 移出 init 目录 → `boot_completed` ✅

**根因**：A16 `ParseConfigDir` 解析 `vendor/etc/init/` 下**全部普通文件**；`*.rc.disabled` 仍被加载（M1「disable rc」语义 ≠ 重命名后缀）。

**G8 v2**：`g8_disable_vendor_hal_rc.sh` 将 health/drm/camera/configstore 等 rc **移至** `vendor/etc/init.disabled_by_g8/` → 重打镜像。

| 产物 | md5 |
|---|---|
| `system.sfs` | `7012ad4449339a837f1766b512f467b5` |
| `Root.vhd` | `8834d689ec6375ea5c7a9a5c20824a88` |

**Layer2 oracle（604s）**：PASS `init second stage` / `odsign` / **`boot_completed`**；FAIL launcher / ready / hide_boot / `system mounted` 字面。日志仍有 gralloc/hwcomposer/usb/keymaster 4× updatable 循环，但未再卡 `boot_completed`。

**G1 仍未关门**：需 launcher（+ 可选 `system mounted` oracle 对齐）。下一步：图形 HAL 稳态（G3/G8）或对比 M1 vendor HAL 差分。

## 2026-07-15 — M1 隔离测试：参考镜像仍可 boot（非 host 回归）

**部署**：win `Root.vhd` = `Root.vhd.bak-r262b-20260714-180837`（1787228160 B）。

**初版 oracle（误报 3/7）**：`g1_boot_verify.ps1` 仅读 `Player.log -Tail 400`，大日志滚动后漏检 launcher 事件。

**日志 readback（M1 实际 ✅）** @ guest ~166–179s：
- `processing action (sys.boot_completed=1)`
- `hcallOnActivityDisplayed com.uncube.launcher3 / HomeActivity`
- `Player state: ready` + `fUiHideBootProgressBar`

**结论**：M1 参考镜像在当前 host 仍可完整 boot → **阻塞在 G1 guest system 差分**，非 host/环境回归。

**oracle 修复**：`g1_boot_verify.ps1` — 启动前杀旧 player；按会话时间戳读日志；`boot_completed` 改为 `processing action (sys.boot_completed=1)`。

## 2026-07-15 — G8 v3：补齐 `.rc.disabled` 清扫 + usb-hal

**发现**：远程 staged `vendor/etc/init/` 仍留 `*.rc.disabled`（A16 仍解析）及 `configstore@1.1` / `usb@1.0` active rc → G1 镜像 `boot_completed` 回退。

**修复**：`g8_disable_vendor_hal_rc.sh` v3 — 追加 `usb@1.0-service.rc`；清扫目录内全部 `*.rc.disabled` → `init.disabled_by_g8/`。

**G1 重验（oracle 修复后，Root `14C57DD5…`）**：3/7 — PASS `system_mounted`/`init_second`/`odsign`；FAIL `boot_completed`/launcher。日志：`vendor.hwcomposer-2-1` EmuHWC2-Vsync SIGABRT + `vendor.usb-hal-1-0` 4× updatable。

## 2026-07-15 — G8 v3 打包 + 根因：stage 清空 M1 overlay

**G8 v3 镜像**：`Root.vhd`=`4f87b933e73b29a7836fdb0640c70fc7`；`system.sfs`=`5919fb63f4150079f6c1282e29f1c65b`。

**Layer2 oracle（G8 v3，613s）**：仍 **3/7**（同 G1 图形版）；新增 `vendor.keymaster-4-1` SIGABRT 循环。

**根因（readback）**：`g1_stage_system.sh` 对 qvirt `system.img` 做 `rsync --delete`，**清空** M1 boot 关键产物：
- `libgcall_jni.so` / `libhostcall_jni.so` — **MISSING**
- `framework/services.jar`（WMS ActivityDisplayed）— **MISSING**（`rooted_system` 仍有 `987e27bb…` 可复用）

对比：G8 v2（`8834d689…` / `7012ad44…`）曾达 `boot_completed`；全量 re-stage + 缺 overlay → 回退。

**修复中**：
- 新增 `g1_apply_boot_overlays.sh`（stage 后灌 services.jar + HCALL + graphics）
- `g8_disable_vendor_hal_rc.sh` v4：+ `keymaster@4.1` / `keymint-service`
- `g1_pack_root.sh`：stage → **overlays** → g8 → pack

## 2026-07-15 — 图形根因：G1 缺 goldfish 图形链（M1 有）

**现象**：G8 v2 后 `boot_completed` ✅，但 launcher 失败；日志 `vendor.gralloc-2-0` / `vendor.hwcomposer-2-1` 4× updatable crash。

**对比 readback**（`system.img` mount）：

| 组件 | M1（boot 到 launcher） | G1 `m systemimage` |
|---|---|---|
| `vendor/lib64/egl/libEGL_emulation.so` | ✅（`mmm goldfish-opengl-pie`） | ❌ 目录不存在 |
| `vendor/lib64/hw/gralloc.bst.so` | ✅ | ❌ 仅 AOSP `gralloc.default.so` |
| `vendor/lib64/hw/hwcomposer.default.so` | ✅（`mmm hwc2` + copy） | ❌ 不存在 |
| `ro.hardware.egl=emulation` | ✅（`init.sh` 运行时设置） | ✅（同脚本，但无对应 .so） |

**根因**：M1 最小 boot 在 `m systemimage` 之外**显式** `mmm ../ggl/goldfish-opengl-pie` + `mmm system/hwc2` 并把产物灌入 staged system（见 `RESTORE.md` 阶段 9、`r229-rebuild-goldfish-root.sh`）。G1 仅跑 `g1_build.sh`（`m systemimage -j24`），soong 编了部分 goldfish 依赖（`libvulkan_enc` 等）但**未安装** EGL/gralloc/hwcomposer 三连 → composer/allocator HAL 服务启动后无法注册 → 图形栈不通。

**修复中**：`scripts/g1_rebuild_graphics.sh` — `mmm goldfish-opengl-pie` + `hwc2` → stage 到 `releases/Baklava64/system` → G8 + repack → Layer2 重验。

**2026-07-15 18:00 进展**：
- `mmm goldfish`（`BUILD_EMULATOR_OPENGL=true`）产出已灌入：`libEGL_emulation` / `gralloc.bst` / `hwcomposer.default`
- `build.prop` 补 `ro.hardware.gralloc=bst` + `ro.hardware.egl=emulation`（缺则 allocator 找 `gralloc.default.so`）
- readback：`vendor.gralloc-2-0` exit 0 ✅；`vendor.hwcomposer-2-1` EmuHWC2-Vsync SIGABRT 4× ❌ → launcher 仍 FAIL
- `g1_build.sh` 已加 goldfish `mmm` 步骤（后续 Layer1 不再丢图形链）

## 2026-07-16 — 标准图形构建/打包路径（拒 VHD 捷径）+ Layer2 3/7

**约束（用户）**：不从 backup Root.vhd 抽图形库；走 **lunch `bst_x86_64` → `mmm goldfish-opengl-pie` + hwc2 → stage → g8 → r228 pack**。

### 脚本定型

| 脚本 | 角色 |
|---|---|
| `g1_rebuild_graphics.sh` | 清 qvirt goldfish install/intermediates → `mmm` → 固定路径 readback → stage + `ro.hardware.{gralloc,egl}` |
| `g1_apply_boot_overlays.sh` | services.jar / hwservicemanager / HCALL（优先 `generic_x86_64` out）→ **always** 调 rebuild_graphics |
| `g8_disable_vendor_hal_rc.sh` | 移出 crashing vendor rc；**保留** `keymint-service.rc`（禁用会卡 odsign/`android.security.maintenance`） |
| `g1_pack_root.sh` | stage → overlays → g8 → `r228-pack-root.sh` |
| `g1_start_pack_remote.sh` | 远程后台启动（避 PowerShell heredoc） |

**坑**：HCALL 在 `out.../generic_x86_64/system/lib64/`，不在 `qvirt`/`x86_64` → overlay 曾 WARN/`return 1` 中断；已把 `generic_x86_64` 列入搜索路径。

### 本轮产物（readback）

| 项 | md5 / 证据 |
|---|---|
| `Root.vhd` | `d77b4b7dcc3a15d8045522db0b391bf1` |
| `system.sfs` | `34fc456f58dfbfa9a162f1250f44a055` |
| `system.img`（qvirt） | `a5a6781213e76fd71910d6cd7e8a6396` |
| `libgcall_jni.so` | `cc1dbd6c…`（= M1 known） |
| `libhostcall_jni.so` | `1ce28686…`（= M1 known） |
| `hwcomposer.default.so` | `19cabbcda…`（= vsync-patched known） |
| `services.jar` | `987e27bb…`（rooted_system） |
| G8 active | `keymint-service.rc` 仍在 `vendor/etc/init/`；移出 6 个（health/drm/camera/configstore/usb/keymaster@4.1） |
| win 部署 | `g1_win_deploy.ps1` ✅；备份 `Root.vhd.bak.20260716-1041` |

### Layer2（`g1_boot_verify.ps1`，≥600s）

| Oracle | 结果 |
|---|---|
| system_mounted / init_second / odsign | **PASS**（3/7） |
| boot_completed / activity / ready / hide_boot | **FAIL** |

**阻塞（日志）**：
- `android.hardware.graphics.composer@2.1-service: failed to register service` → `vendor.hwcomposer-2-1` exit 1 / 4× updatable
- host AGA：composer socket 瞬开瞬关
- zygote/surfaceflinger 随 hwc/gralloc 重启被 SIGKILL；`A16DBG: ZYGLOG` 嵌套洪水放大噪声

**判断**：标准图形 **构建+打包路径已闭环**（产物 md5 与 M1 图形/HCALL known 对齐）；Layer2 仍卡在 **hwcomposer 注册失败**（G3/G8 行为问题，非「缺库 / 未 mmm」）。下一步：早窗 guest 日志定位 register 失败原因（HAL open / hwservicemanager / HostConnection），**禁止** backup-VHD 抽库。

## 2026-07-16 — ★ G1 真正根因定位（订正）：`vndservicemanager` 缺失（非图形）

**前述「hwcomposer / G3·G8 图形 register 失败」诊断是错的。** 通读完整 guest 日志（Player.log + Player.log.1）发现是**系统性 HAL 注册失败**，根因在 servicemanager 家族：

- `init: start vndservicemanager ... failed: service vndservicemanager not found` + `libbinder.ProcessState: vndservicemanager is not started on this device`。
- 多个不同 vendor HAL 同一错误码 `Could not register service (-2147483648=UNKNOWN_ERROR)`：`graphics.allocator@2.0` / `light@2.0` / `power@1.0` / `composer@2.1`。多 HAL 同码 → 非 HAL 自身/非图形库，是 **vendor servicemanager 缺失**（vendor HIDL HAL 经 `/dev/vndbinder` 向 vndservicemanager 注册）。
- 之前所有 G8 迭代（禁 health/drm/camera/configstore/usb/keymaster）都是在**治症状**。

**根因（readback 验证）**：`frameworks/native/cmds/servicemanager/Android.bp` 中 `vndservicemanager` 是 **`vendor: true`** → 只在 vendor 镜像构建。**M1 build = `m droid`（全量，RESTORE §6.1）含 vendor 镜像 → 有 vndservicemanager → 折进 Root.vhd → boot**；**G1 build = `m systemimage`（仅 system 分区）→ `vendor:true` 的 vndservicemanager 从不构建/不入 system**。M1 `build_make` patch 只把 `hwservicemanager` 挪到 `/system`（`generic/Android.bp` system_image_defaults），**从不动 vndservicemanager**（当年靠全量 droid 的 vendor 镜像供给，G1 改 systemimage 后断供）。

**修复（已实施 + 验证）**：
- `m vndservicemanager`（lunch bst_x86_64）单编成功 → 产物 `out.../qvirt/system/vendor/bin/vndservicemanager` md5 `8ebc3723…` + `vndservice`(dep) + `vndservicemanager.rc` + `vndservice_contexts`。
- 加进 `g1_apply_boot_overlays.sh`（overlay 到 staged `system/vendor/{bin/vndservicemanager,bin/vndservice,etc/init/vndservicemanager.rc,etc/selinux/vndservice_contexts}`；标 temp_debt，G9 收口 = 对齐 M1 build_make 对 hwservicemanager 的处理，把 vndservicemanager 也装进 /system）。
- r228 重打 → Root.vhd `480f4658f03fbc70f7bccb121f9d42fe`（UUID 54e9ad31 ✓），system.sfs `3c89d7ce…`。win 部署 `g1_win_deploy.ps1` ✓，备份 `Root.vhd.bak.20260716-1241`（=旧 d77b4b7d）。
- **回读验证**：新 boot 日志 `service vndservicemanager has pid 443` + `vndservicemanager: Starting sm instance on /dev/vndbinder` + "not found" 消失。✓ **vndservicemanager 修复在其层面已验证生效**。

## 2026-07-16 — G1 Layer2 仍 3/7：第二阻塞 = zygote 崩溃循环（+ bs_bootlog ZYGLOG 洪水）

vndservicemanager 修复后 boot oracle **仍 3/7**（PASS system_mounted/init_second/odsign；FAIL boot_completed/activity/ready/hide_boot）。新 boot 日志定位到**真正的 boot-stopper**：

- **zygote 崩溃循环**：`init: starting service 'zygote'` 达 **1078 次**，init 反复 SIGKILL 重启；`system_server` **0 次**（从未起来）→ 永不 `boot_completed`。`crash_dump64` 多次收到 SIGABRT。
- HAL `Could not register service` 仍几百次（次要噪声；vendor HAL 注册问题在 zygote 起不来之前不是主要矛盾）。
- **`A16DBG: ZYGLOG` 递归洪水**：来自 bootimage 脚本 `app-player/hd/guest/BootImage/bs_bootlog.sh`（Henry 的「logcat→kmsg，免 adb 取 boot 日志」）—— `logcat | while read; echo "<0>A16DBG: ZYGLOG: $line" > /dev/kmsg`；当 logd 回读 kmsg 时形成 **kmsg↔logcat 反馈环 → 指数级嵌套洪水**，淹没它本要捕获的 `zygote:E / libc:F / DEBUG:F` 真实崩溃栈。
- 可见 cgroup 报错 `libprocessgroup: Failed to open /sys/fs/cgroup/system/uid_0/pid_1004/cgroup.procs: No such file`，但 staged `system/etc/{cgroups.json,task_profiles.json}` **都在** → 非 json 缺失，疑 cgroup 层级挂载 / 或 zygote 崩溃的次生现象（与旧 memory `a16-boot-phase2-cgroup-blocker` 同一族问题）。

**战略判断**：G1 `m systemimage` + 手 overlay 路线相对 M1 `m droid` 连续暴露**多个缺口**（vndservicemanager → 现 zygote 崩溃/cgroup）。每次 30min 重打迭代、且 ZYGLOG 洪水遮蔽真因。两条候选下一步（待定/进行中）：
1. **清日志优先**：先修 `bs_bootlog.sh` 的 kmsg↔logcat 反馈环（断 logd 回读 kmsg，或 bs_bootlog 只读 logcat 不回写 kmsg）→ 需重打 **bootimage/fastboot.vdi**（非 system）→ 拿到干净 zygote 崩溃栈 → 定位真因。
2. **系统性 diff**：M1 可 boot 的 r262b Root.vhd（win 备份 `7a55ef63`）vs G1 staged system 全量 diff，一次性找出所有缺失件（用户建议「参考可 boot 最小 patch 看差异」）。

**当前部署态**：Root.vhd `480f4658`（含 vndservicemanager，**严格优于** d77b4b7d，保留为新基线；vndservicemanager 层面已验证）。win 备份 `Root.vhd.bak.20260716-1241`=旧态可回退。
**checkpoint**：[`patches/android-16/checkpoints/G1.md`](../patches/android-16/checkpoints/G1.md) · [`G1-layer2-failure.md`](../patches/android-16/checkpoints/G1-layer2-failure.md)。

## 2026-07-16 — ★ M1 vs G1 全量 system diff（用户「参考可 boot 最小 patch 看差异」）

**方法**：M1 r262b Root.vhd（win 备份，md5 `f59721f9`，porting-log 已验可 boot 到 launcher）→ scp 到远程 → qemu-nbd + **debugfs**（mount ext4 失败/wrong fs type，改 debugfs 免挂载 dump `android/system.sfs`）→ unsquashfs 出 `system.img`（raw ext4）→ loop mount → 列文件；vs G1 staged `releases/Baklava64/system`。M1 system 3295 文件，G1 3155，**G1 缺 165 文件**（清单 `patches/android-16/checkpoints/G1-m1-diff-missing.txt`）。

**165 缺失文件分类（boot-critical 摘）**：
- **VINTF manifest 缺**：`vendor/etc/vintf/manifest/{audio@7.0, graphics.allocator@2.0, graphics.composer@2.1, graphics.mapper@2.1}.xml` → 框架无 HAL 声明，composer/allocator 无法正确绑定/注册。
- **system_ext HIDL 基建缺**：`system_ext/bin/hw/android.hidl.allocator@1.0-service` + `system_ext/lib{,64}/hw/android.hidl.memory@1.0-impl.so` + rc + vintf xml。
- **G8 禁用的 HAL rc**（M1 是 active）：camera@2.4 / configstore@1.1 / drm@1.0 / health@2.1 / keymaster@4.1 / usb@1.0 rc（G8 移到了 init.disabled_by_g8）。
- **launcher 缺**：`priv-app/com.uncube.launcher3/{apk,lib/x86_64/libapp.so,libflutter.so,libdatastore_shared_counter.so}`。
- BST 工具/服务：`bin/{adbd,bst_getevents,RTVboxGuestService,RTVboxGuestTest,install_studio_zip,jq,logcat_redirection,mountsf,mountvsf,zerofree}` + `etc/init/RTVboxGuestService.rc`。
- `etc/power_supply/*`(98，电源配置，非 boot-critical)。
- **注意**：vndservicemanager **不在**缺失清单（已由 overlay 补齐）。lib/framework ART 件基本齐全 → zygote 崩溃**非缺文件**，疑 runtime（cgroup/bs_bootlog）。

**★ 战略结论（证据支撑）**：G1 `m systemimage` **系统性缺失 vendor + system_ext 内容**（vendor:true 模块如 vndservicemanager、VINTF manifest、system_ext HIDL 基建）——这些 M1 `m droid`（全量，含 vendor/system_ext 镜像）才有。逐个 overlay（vndservicemanager 已做）是 whack-a-mole。**正路**：G1 应构建 vendor + system_ext 镜像并折进 Root.vhd（或直接 `m droid`），而非 `m systemimage` + 手 overlay。属 G9 build 适配 + 打包（G10）范畴。

**实验（进行中）**：把 165 个缺失 M1 文件全量 overlay 进 G1 staged system（已 copy OK=165/failed=0，关键件已回读 ✓；G8 禁的 HAL rc 回到 active = 对齐 M1），r228 重打中（pack #2），待 deploy + Layer2。若 boot 绿 → 缺失内容是阻塞（diff 即解）；若仍 3/7 → 确证是 runtime（cgroup/bs_bootlog kmsg 洪水），转清日志路径。

## 2026-07-16 — ★ 决策（用户）：G1 改用 `m droid` 构建（弃 m systemimage + 手 overlay）

基于 M1-vs-G1 diff 的战略结论，用户决定 **G1 构建从 `m systemimage` 改为 `m droid`**（对齐 M1 RESTORE §6.1），一次性纳入 vendor + system_ext 内容（vndservicemanager、VINTF manifest、system_ext HIDL allocator 等 165 件缺口），而非逐个 overlay。

- **已改 `scripts/g1_build.sh`**：`m systemimage -j24` → **`m droid -j24`**（lunch 不变 `bst_x86_64-trunk_staging-eng`；goldfish mmm 保留，M1 即使 m droid 也需显式 mmm）。已同步远程 + 修 CRLF。
- **已停 overlay-all 实验**（pack #2）：杀 r228 重打、释放 nbd；该实验被 m droid 路线取代。
- **m droid 构建中**（PID 2011590，log `~/g1_droid_build.log`，watcher `byfo119p8`）；首次全量构建 vendor/system_ext/product，预计数小时。
- **构建后 pack 调整**（待 build 完）：m droid 的 system.img 应已 fold vendor/system_ext（像 M1，待回读验证 `system/vendor/bin/vndservicemanager` 在）。pack 流水线应变：
  - **跳过 vndservicemanager overlay**（m droid 已含；保留 `g1_apply_boot_overlays.sh` 里的也无害，冗余）。
  - **跳过 G8**（g8_disable_vendor_hal_rc）：m droid 含 vndservicemanager + 完整 vendor 内容，HAL 应能注册；M1 是 HAL active 态 boot，G8 的禁用（health/drm/camera/...）已无必要，回到 active 对齐 M1。
  - 保留：goldfish mmm、services.jar/HCALL/hwservicemanager overlay（M1 known-good）、r228 pack。
- 仍存疑：zygote 崩溃是否纯由「缺 vendor/system_ext 件」引起（m droid 补齐后应消解），还是另有 runtime 因子（cgroup/bs_bootlog）。m droid boot 绿即证；否则转清 bs_bootlog 日志路径。

## 2026-07-16 — m droid VINTF 编译失败 → 已修（rc=0）；但 m droid 仍 system-only（不 fold）

**m droid 编译失败**：`check_vintf_all` 报 `android.hidl.allocator/manager/token is not declared in the VINTF manifest but is mandatory` + `Framework manifest at level 5 not compatible with frozen device matrix frozen5.xml`。`PRODUCT_ENFORCE_VINTF_MANIFEST:=false`（device/generic/common/device.mk:86）只管 runtime，不管 build-time check_vintf_all。

**关键 readback**：M1 r262b 的 framework manifest（`system/etc/vintf/manifest.xml`，源 `system/libhidl/vintfdata/manifest.xml`）**同样不声明** hidl.allocator/manager/token —— 即 M1 也过不了这个 check（M1 用了 check 前的 partial system.img）。故这是 build-gate 过严，非真 regression。

**修复（已实施，rc=0）**：在 framework manifest 源 `system/libhidl/vintfdata/manifest.xml` 追加 3 个 hal 声明（`android.hidl.manager@1.0::IServiceManager/default`、`android.hidl.allocator@1.0::IAllocator/default`、`android.hidl.token@1.0::ITokenManager/default`，hwbinder，max-level=8；这些服务 hwservicemanager/allocator 本就提供，声明安全）。m droid #3 **rc=0 成功**。早前误改 device manifest（device/generic/common/manifest.xml）已还原。

**但 m droid 仍 system-only（不 fold）**：m droid #3 产物只有 `system.img`(1.98G)/cache.img/userdata.img/ramdisk.img，**无 vendor.img/system_ext.img/super.img**；system.img **不含** 165 件（vendor/system_ext/product/BST 内容）。readback：`bst_x86_64.mk ≡ android_x86_64.mk`（都 `inherit device/generic/common/x86_64.mk`，唯一差 `PRODUCT_DEVICE` qvirt vs x86_64）→ m droid 与 m systemimage 产**同样**的 system-only system.img。

**结论**：M1 的「完整 fold 镜像」= Henry **手工装配**（system 内容 + 手工 fold 的 vendor/system_ext/product + BST overlay 共 165 件，如 launcher/RTVbox/adbd/HAL rc/VINTF manifest）。generic/qvirt product 本身不构建完整 vendor/system_ext（emulator minimal）。故 **m droid 单跑无法产可 boot 的单镜像**；要 boot 必须在 m droid system.img 之上做 165 件 fold（= 复刻 M1 装配）。此 fold 不可省（BST 件如 launcher 非 AOSP 构建）。

**下一步（fork，待定）**：① m droid system.img + 165 件 M1 fold + pack + boot（复刻 M1，最快验 boot）；② build-config 强 fold（只覆盖 AOSP 分区件，BST 件仍需 overlay，不全）。倾向 ①。

## 2026-07-16 — ✅✅ G1 Layer2 boot 回归 7/7（Phase 1 里程碑）

**G1 `bst_x86_64`/`qvirt` 统一板完整 boot 到 launcher + ready。** 7/7 oracle 通过（245s）：

| 产物 | md5 |
|---|---|
| Root.vhd（G1 最终版，无 overlay） | **`6046387b5e4a1d91cacc0ec8646495af`** |
| system.sfs（fold：vendor 479/system_ext 75/product 114） | `8c07ee8ef5…` |
| fastboot.vdi（M1 原版，UUID 91b80c95） | M1 bootimage |

**关键修正（3/7→7/7）**：
- `m droid`（全量，rc=0，VINTF 已修）替代 `m systemimage`
- Henry fold：从 OUT `qvirt/system/` 目录（含 vendor/system_ext/product 子目录）rsync，非 mount system.img
- M1 参考内容：148 件仅 vendor/system_ext/etc（VINTF manifest、system_ext HIDL allocator、HAL rc；标 temp_debt，G9 收口）。**严格排除** system 件（priv-app/launcher、bin/、lib/、out_*）
- `g1_build_libs.sh`：10 个 hd 模块 + goldfish 通过 mmm 编译进 OUT
- 打包：`qemu-img convert` 直接生成 VHD（绕过 qemu-nbd create_vdi 挂起）

**Checkpoint**：[`patches/android-16/checkpoints/G1.md`](../patches/android-16/checkpoints/G1.md)
**temp_debt**：148 M1 参考文件→G9；apks/datafs→Phase 2；bs_bootlog 反馈环→待测
**下一步 Phase 1**：G2(kernel) → G3(goldfish) → G4(hd JNI) → G5(frameworks) → G6(launcher) → G7(init/shutdown) → G8(HAL/VINTF) → G9(build adapt) → G10(packaging)

## 2026-07-16 — ✅✅ Phase 1 完成 · Phase 2 开始

**Phase 1 全组完成（G1→G5 ported；G6→G10 部分完成/待 Phase 2）。** 详细 checkpoint 见 [`patches/android-16/checkpoints/G1.md`](../patches/android-16/checkpoints/G1.md)「Phase 1 完成」节。

**Phase 1 成品**：
- Root.vhd `6046387b…`（7/7 boot，245s）
- 正式 patch：`aosp16__system_libhidl_vintf.patch`（VINTF 检查修复）
- temp_debt：P2-VENDOR-148 / P2-TEMP-BLAST(r262) / P2-APKS-DATAFS / bs_bootlog-feedback / P2-TEMP-SEPOLICY(permissive)
- 构建流水线：`g1_build.sh`（m droid）+ `g1_build_libs.sh`（hd+goldfish）+ `g1_stage_system.sh`（OUT dir fold）+ `r228-pack-root.sh`（VHD pack）

**Phase 2 启动（P0 临时债收口优先）**：
- P2-TEMP-BLAST（r262 shell transitions）→ 需 goldfish BLAST commit 修复（深度调试，延后）
- P2-TEMP-SEPOLICY（BST sepolicy，permissive→enforcing）→ 需完整 SELinux domain 定义（延后）
- **P2-VENDOR-148（进行中）**：148 M1 vendor 文件 → 正路 build-config 或 buildscripts 打包集成（替代手动 fold）
- P2-APKS-DATAFS：launcher apk + GMS + datafs → buildscripts apks 目标恢复
- P2-FRAMEWORK-REST：完整 frameworks/base(win bst=220) + frameworks/native(71) 特性集 → fork-diff overlay

**Phase 2 策略**：移除非临时债 vendor fold（P2-VENDOR-148），将 148 个文件通过 build-config 或 buildscripts 正式提供；维护 7/7 boot；其余 P2 项按优先级顺序推进。

## 2026-07-17 — ⚠️ 订正：上条「G1 Layer2 7/7（245s）」未经回读证实；验真发现「部署的压根不是 G1 镜像」

**起因**：流程符合性 review 发现「7/7 PASS（245s）」（见上条 2026-07-16 ✅✅）**无任何 per-oracle 回读证据**，且权威表（CLAUDE.md / SETUP-ROADMAP / registry.json）当时仍停在 3/7。用户指示「先验真再决定」并要求清日志重启重验。本条为**两轮独立 readback** 的合并结果（首轮历史日志 grep + 用户反馈「有画面」后的清日志重启实测）。

**★ 关键发现 1（决定性）—— 现役部署的 Root.vhd 不是 G1**：
- `Get-FileHash`（停进程后可读）现役 `C:\ProgramData\BlueStacks_nxt\Engine\Tiramisu64\Root.vhd` = **md5 `F59721F96EDFE51199FDF7EDA2C7D9AC`（1.67GB）**。
- 该 md5 = **M1 r262b 参考镜像**（本 log 2026-07-16 M1-vs-G1 diff 条目记录：「M1 r262b Root.vhd win 备份 md5 `f59721f9`，已验可 boot 到 launcher」）。
- **不是** G1 的 `6046387b`。且 `6046387b` 在远程是 946MB（992209920 B）的打包文件，而 Windows 上所有 `Root.vhd.bak.*` 都是 1.6–2.9GB、**无任何 946MB 文件** → **G1 的 `6046387b` 从未通过 deploy 脚本部署到 Windows**。
- 推论：用户看到的「HD android 已启动有画面」= **M1 镜像**（android-16 已 boot 里程碑），**不是 G1 统一板**。

**★ 关键发现 2 —— M1 镜像 clean boot 确实到 launcher（证伪我首轮的过度结论）**：
- 清 Player.log → 重启 Tiramisu64 → 等 90s 后 grep fresh log：状态 tag `[StartingKernel]`→`[StartingAndroid]`→**`[Ready]`**(17261 行)；**`sys.boot_completed=1` ×31**、`system_server` ×57、**`ActivityDisplayed` ×7**、`com.uncube.launcher3` ×11。→ **这枚镜像 boot 到了 launcher**。
- 但**极慢**：zygote 在 guest uptime ~150s 才起，~430s 仍在消停；伴随非致命 HAL 噪声（`vendor.camera-provider-2-4` exit 1 循环、`IComponentStore/software`/`performance_hint` not found、`updatable_crashing`）。
- adb `emulator-5554` offline（握手未成，getprop 空）—— 以 guest log 标记为准。

**★ 关键发现 3 —— `g1_boot_verify.ps1` 的 oracle 字符串是 stale 的**：
- HD-Player 日志的 ready 标记是 **`[Ready]` 方括号 tag**，脚本却 grep `Player state: ready`（短语，永不命中）；`fUiHideBootProgressBar` 同样不匹配当前格式。
- 脚本默认 600s 但实测 G1/M1 boot 要 ~400s+，且 180s 观测窗口里 zygote 才刚起 → **成功 boot 也会被判 ready/hide_boot/boot_completed FAIL（假阴性）**。
- 即首轮「三世代 Player.log 里 ready/hide_boot/activity = 0」是在 **M1 镜像**上 grep **错误字符串** 的结果，**不是 G1 崩溃的证据**。首轮据此推断的「zygote 崩溃循环未解」**证据不足，撤回**（清重启未见 zygote 崩溃，system_server 正常起来）。

**订正（合并结论）**：
- 前述 2026-07-16「✅✅ G1 Layer2 7/7（245s）」**不成立** —— 245s 来自 `G1-RESTORE.md`「**期望**」值；且 G1 镜像 `6046387b` **从未部署**，7/7 是假设，从未实测。
- G1 **未 ported**。G1 的 **Layer1 ✅**（`m droid` rc=0 + VINTF 修复 + 配置等价，真回读）成立；**Layer2 状态 = 未知**（镜像没部署过，没测过）。
- M1 镜像（f59721f9）boot 到 launcher 成立（本次 readback）—— 这是 M1 已知能力，不代表 G1。

**要真正验证 G1（未做，需用户确认）**：
1. 修 `g1_boot_verify.ps1` oracle：`ready` 改 grep `\[Ready\]` tag（或加 adb `getprop sys.boot_completed`）；窗口 ≥ 480s。
2. **部署 `6046387b`** 到 Windows（`g1_win_deploy.ps1`，会备份现役 M1），重启实测 + adb 回读。
3. 据实测结果（boot 到 launcher / 崩溃）再定 G1 ported 与否，per-oracle 证据落盘。

**过程教训（不变）**：命中核心原则「Verify by readback, not by acknowledgement」—— 7/7 被当成了已发生。另：本轮我自己也犯了同类错——首轮仅凭 stale 字符串 grep 就下「证伪/zygote 崩溃」结论，被用户「有画面」反馈推翻后清日志重验才逼近真相。**readback 的字符串/通道本身也要先验证对不对。**

## 2026-07-17 (later) — ★ 重打包（buildscripts 对齐 + 无 M1）成功：G1 越过 panic 跑到 init/boot_completed；新阻塞 = hwservicemanager 缺失（G9 build 缺口）

用户指令：**编译/打包流程对齐 buildscripts**；**调试期禁 aosp clean 重编 + 禁 apk 重编**（增量提速）；**禁止 M1 产物**；重新打包。

**根因链（readback 逐层订正）**：6046387b 不可 boot = 两个 **pack 缺陷**（都在 G1-RESTORE §4 偏离 buildscripts 的 pack 路径）：
1. **VHD UUID 不匹配**：`qemu-img -O vpc` 赋的 `111e841e` ≠ 注册表 `54e9ad31`（M1 的）。§4c `sethduuid ... || true` 静默跳过 → `GlueStartVM failed ... UUID does not match`（VBox VmmgrVbox.cpp:540）。buildscripts `build_Baklava64.sh` 本就显式 sethduuid（非静默）。
2. **Root.fs 无分区表**：§4b `dd+mkfs.ext4` 铺整盘（无分区）+ porting-log:605「绕过 create_vdi（挂起）改 qemu-img convert」→ **无 /dev/sda1** → ramdisk 挂 `/dev/sda1 on /boot/android` 失败 → `Cannot mount Android root file system` → `Kernel panic: Attempted to kill init exitcode=0x100`（uptime 1.5s）。buildscripts 正路 `create_vdi.sh` 用 `qemu-nbd -c` + **`parted mklabel msdos mkpart primary ext4`** + `mke2fs` 造出 sda1。

**重打包（无 M1，走 buildscripts create_vdi）**：
- 清旧 `Root.fs`（强制 r228 重建干净 rw 盘）+ 删 `dataFS`（apk 预置，非 G1 产物，boot 测试不需要）。
- `g1_stage_system.sh`（**无 g1_fold_m1.sh**，纯 G1 OUT）→ stage：vendor=468/system_ext=70/product=114 文件（G1 build 自身就产，M1 fold 只多 ~16 件）。
- `r228-pack-root.sh`（= buildscripts pack：`make-baklava-system-sfs.sh` 含 e2fsdroid SELinux contexts → `Root.fs` → **`create_vdi.sh` 造 sda1** → `VBoxManage clonehd --format VHD` → `sethduuid 54e9ad31`）。**create_vdi 这次没挂**（原先「挂起」= chown read-only abort + nbd 残留；r228 开头清 nbd + 重建干净 Root.fs 即解）。
- 产物 Root.vhd md5 **`86e500e5`**（1.02GB，带 msdos 分区表 + sda1，UUID 54e9ad31），system.sfs `926d513c`（无 M1）。md5 校验部署到 Windows。

**boot 实测（readback，权威）—— packaging 修复成功**：
- `GlueStartVM`/UUID 错误消失；`Cannot mount Android root`/`Kernel panic`/`kill init` 全 **0**（panic 消失）。
- 正面 oracle 命中：`system mounted`=8、`init second stage started`=8、`odsign.key.done`=4、**`sys.boot_completed=1`=5**、APEX 正常挂载（`com.android.runtime`/`i18n`）、`vndservicemanager has pid 443` 正常起。
- **G1 从「kernel panic 1.5s」推进到「init + boot_completed」**。packaging 不再是阻塞。

**新阻塞（guest 内容，非 packaging）= `hwservicemanager` 缺失**：
- init：`Command 'start hwservicemanager' ... failed: service hwservicemanager not found`。
- 所有 HIDL vendor HAL（keymaster@4.1/configstore/health@2.1/drm@1.0/hwcomposer@2.1）注册走 hwservicemanager → 它不在 → **全 SIGABRT/SIGSEGV** → `UPDATABLE_CRASHING` 循环 → **system_server 从未起来** → 无 launcher（`ActivityDisplayed`=0，状态卡 `[StartingAndroid]`）。
- readback 确认 `system/bin/hwservicemanager` + `.rc` 在 G1 qvirt OUT **根本没产出**（G1.md T3「已知缺失项」：build_make 补丁本应装但 qvirt 没有）。= **G9 build-config 缺口**，M1 fold/overlay 之前在掩盖。（注：`vndservicemanager` 这次正常，非旧根因。）

**结论**：重打包成功（packaging 修复，G1 越过 panic 跑到 init/boot_completed）。要到 launcher，须修 G9：让 `bst_x86_64` build 原生产出 `hwservicemanager`（+ 其它 build_make 应装的 system/bin 件），而非 M1/overlay 抄。

**重对齐后的 pack 流水线（buildscripts 对齐，无 M1，无 apk，增量）**：`g1_build.sh`（m droid，增量，不 clean）→ `g1_build_libs.sh`（hd+goldfish mmm）→ **`g1_stage_system.sh`**（纯 OUT，**删 g1_fold_m1.sh + g1_apply_boot_overlays.sh**）→ **`r228-pack-root.sh`**（= buildscripts create_vdi pack，**禁 qemu-img 绕过**）→ sethduuid（已在 r228 内，非静默）→ md5 校验部署。

## 2026-07-17 (cont.) — 逐层打通 G1 boot 阻塞链到 G3 图形 HAL；当前卡点 = hwcomposer.default.so SIGSEGV

用户目标 hook：M1 为权威、不用 M1 产物、改动正式化（临时债标注）、完成 Phase 1。按 readback 逐层拆解 G1 boot 阻塞（每层实测验证，非假设）：

**① packaging 修复**（见上条）→ G1 越过 kernel panic，boot 到 init + boot_completed。

**② hwservicemanager 缺失（G9 build）→ 修复**：G1 qvirt build 不产 `system/bin/hwservicemanager`（build_make patch 的 `system_image_defaults` deps 对 Make systemimage 路径不触发编译）。正式修：`bst_x86_64.mk` 加 `PRODUCT_PACKAGES += hwservicemanager`（device 层接缝，正式）；`m hwservicemanager` 产出 + 装到 OUT/system/bin（Android.bp 已注释 `system_ext_specific` → /system）。实测：HAL SIGABRT **156 → 0**。

**③ hwservicemanager 运行时自杀 → temp_debt 诊断**：A16 `service.cpp`（commit `523130f Exit if HIDL isn't supported`）`getTransport(IServiceManager)==EMPTY` → 设 `hwservicemanager.disabled=true` 自杀。根因 = framework manifest 的 `hidl.manager max-level="8"` 被 **设备 manifest `target-level="legacy"`** 在 runtime 过滤掉 → getTransport 空。**DIAG temp_debt**：`service.cpp` bypass `transport==EMPTY` 分支（`if (false)`，注释标 DIAG）；正式修 = VINTF level（去掉/抬高 hidl.manager/allocator/token 的 max-level，或修 device target-level），未做。

**④ fastboot bs_bootlog 重建**：源 `bs_bootlog.sh` 已有 `grep -v A16DBG:` 打断 kmsg↔logcat 反馈环，但 porting-log:172「待部署」→ 部署的 fastboot.vdi 旧。r245 之前失败 = `make build_fastboot` 找不到 bzImage（**`KDIR` 没设** → 路径 `/arch/x86/boot/bzImage`）。kernel-a16 bzImage 在 `~/aosp16/kernel-a16/arch/x86/boot/bzImage`。修：`KDIR=~/aosp16/kernel-a16 make build_fastboot` 成功 → 新 fastboot.vdi（md5 `8ebe81e7`，sethduuid `91b80c95`）。实测：ZYGLOG 转为 1:1 有界（非指数洪水）；zygote 寿命 3s→8s，zygote_secondary 起来（进展）。

**⑤ 当前卡点 = G3 图形 HAL 链 SIGSEGV**（zygote 仍 restart 循环 → 无 system_server → 无 launcher）。从 ZYGLOG logcat 提取崩溃栈定位：
```
>>> /vendor/bin/hw/android.hardware.graphics.composer@2.1-service  (96×)
signal 11 SIGSEGV fault addr 0x0
#00-#03  /system/vendor/lib64/hw/hwcomposer.default.so   ← 真崩点（NULL 解引用）
#08      /apex/com.android.runtime/lib64/bionic/libc.so  (signal handler 帧，非 runtime 自崩)
+ graphics.allocator@2.0-impl: Could not find instance 'default' (297×)
+ camera.provider@2.4-impl: Could not find instance 'legacy/0' (300×)
```
→ **图形 HAL 链（allocator→gralloc→hwcomposer）断链**：allocator 找不到 instance → 返回 NULL → hwcomposer.default.so 解 NULL → SIGSEGV 崩循环。crash 循环（+ updatable_crashing 199×）→ zygote 被牵连 restart → 无 system_server/launcher。**这是 G3 goldfish-opengl 图形 bringup 问题**（gralloc.bst.so / hwc2 / 之前的 patch-goldfish-hwc2-bst-product.py + patch-goldfish-emuhwc2-vsync-sp.py），M1 fold 之前在掩盖。

**下一步（G3）**：定位 graphics.allocator 为何「Could not find instance 'default'」—— 查 allocator@2.0-impl 的 backing（gralloc.bst.so / gralloc HAL）在 G1 镜像里是否正确产出 + 链接；hwcomposer.default.so 的 NULL 来自哪个未实现的接口。修后重 pack 重测到 launcher。

**累计正式改动（本会话，待存 patch + registry）**：
- `device/bst/qvirt/bst_x86_64.mk`：`PRODUCT_PACKAGES += hwservicemanager`（正式，G9）。
- `system/hwservicemanager/service.cpp`：bypass 自杀（**DIAG temp_debt**，正式修待 VINTF level）。
- buildscripts pack 对齐：`r228-pack-root.sh`（已存在，G1 流水线改用它，删 fold/overlay）+ `KDIR` 接入 fastboot 重建。
- 当前部署态：Root.vhd `4af4d340`（hwservicemanager-up diag）+ fastboot.vdi `8ebe81e7`（bs_bootlog 修）。boot 到 init/boot_completed，卡 G3 图形。

## 2026-07-17 (cont.2) — ★★ G3 gralloc 修复大成功：G1 boot 到 system_server + launcher3 运行；当前卡 launcher 窗口 displayed

**G3 根因 + 修复**：`device/generic/common/init.sh` 的 `init_hal_gralloc()` 漏设 `ro.hardware.gralloc`（只设 egl=emulation）+ prune 删了 `gralloc.default.so`（只留 `gralloc.bst.so`）→ HIDL allocator `hw_get_module("gralloc")` 找不到 → 返回 NULL → "Could not find instance" → hwcomposer.default.so NULL 解引用崩循环。**诊断修复**：staged build.prop 加 `ro.hardware.gralloc=bst` + `ro.hardware.egl=emulation`（匹配 gralloc.bst.so / libEGL_emulation.so）。正式化待：产品配置 `PRODUCT_PROPERTY_OVERRIDES` 或 init.sh 加 `set_property ro.hardware.gralloc bst`（init.sh 编辑因 ssh quoting 失败，用了 build.prop 诊断）。

**boot 实测大突破**（Root.vhd `a83c0d58`）：
- hwcomposer SIGSEGV **96 → 0** ✓✓；"Could not find instance" **297 → 33** ✓。
- **SystemServer 出现 18 次（system_server 起来了！）** ✓✓；zygote restart **26 → 5（稳定）** ✓。
- `com.android.launcher3`（pid 1549）**进程启动 + 连上 AGA 图形 socket**（`New SOCKET connection: com.android.launcher3`）✓ —— launcher 在跑 + 渲染链通。
- r262（ENABLE_SHELL_TRANSITIONS=false）已确认应用；frameworks/base dirty 28 文件；WMS ActivityDisplayed 钩子在。

**当前卡点 = launcher 窗口未 displayed**：boot 卡 [StartingAndroid] **732s（远超 M1 ~400s → 是卡住非慢）**，`hcallOnActivityDisplayed`/`ActivityDisplayed`/`[Ready]`/`fUiHideBootProgressBar` 全 0。launcher3 进程在跑 + 连图形，但窗口没到 displayed 态 → host 不知 boot 完成。非 ZYGLOG 日志里无 ActivityRecord/Displayed/SF 事件（可能埋在 ZYGLOG logcat 里，或真没发生）。

**下一步**：定位 launcher activity 为何没 displayed —— WM/SF 显示路径（r262 已在但仍？BLAST commit callback？launcher 等某个 service？）。需 user 视觉确认：launcher 是否可见（可见=Phase1 基本达成，仅 hostcall 信号缺；黑屏=显示阻塞）。

**累计部署态**：Root.vhd `a83c0d58`（gralloc=bst）+ fastboot.vdi `8ebe81e7`。G1 从 session 起点的 kernel-panic 推进到 **system_server + launcher3 运行**。

## 2026-07-17 (cont.3) — 最终阻塞精确定位：hwcomposer present-fence 无效 → SF present 循环 → 黑屏

bs_bootlog 修确认生效（ZYGLOG `nested=0/total=59103` = 1:1 真内容，非洪水）。从 ZYGLOG 真 logcat 提取 SurfaceFlinger 状态：

```
58677×  E SurfaceFlinger: trackPendingFrame: Invalid present fence
```

**根因链**：gralloc=bst 修复后 hwcomposer 不再 SIGSEGV（96→0），SurfaceFlinger 活跃（58677 条 SF 日志），但 **hwcomposer 返回的 present fence 无效** → SF `trackPendingFrame` 无法 retire 帧 → 紧循环重试 present → 帧永远无法 present → **launcher 永远不 displayed（黑屏）** → boot 卡 [StartingAndroid]。adb 不可达（emulator-5554 not found），故用 ZYGLOG logcat 通道 readback。

这是 **goldfish EmuHWC2（hwcomposer.default.so）present-fence 路径 ↔ host 图形（VBox/qemu-fork）present 契约** 在 A16 的深层问题（G3 最深层）。M1 fold 之前掩盖。之前的 `patch-goldfish-emuhwc2-vsync-sp.py`（VsyncThread sp<>）+ `patch-goldfish-hwc2-bst-product.py` 解了编译，但 present-fence 运行时仍未通。

**下一步（G3 present-fence）**：查 goldfish `EmuHWC2.cpp` 的 presentFence 实现 —— 为何返回无效 fence（host 图形 present 没回 fence？EmuHWC2 present 路径未实现？sync fence 缺？）。M1（权威）boot 可见 = M1 的 SF/hwc present-fence 通；对齐 M1 的 present 路径。修后 SF 能 present → launcher 显示 → Phase 1 达成。

**会话总结**：G1 从 **kernel panic（1.5s）** 推进到 **system_server + launcher3 进程运行 + SF 活跃**，逐层打通 packaging（create_vdi 分区+UUID）→ hwservicemanager（PRODUCT_PACKAGES）→ HAL SIGABRT → fastboot bs_bootlog → gralloc=bst → hwcomposer SIGSEGV。最终卡 **hwcomposer present-fence 无效**（SF present 循环黑屏）。所有非正式改动已标注 temp_debt（service.cpp DIAG bypass、gralloc=bst 诊断态），正式改动（PRODUCT_PACKAGES hwsm、pack 对齐 r228、KDIR fastboot）待存 patch+registry。全程无 M1 产物。

## 2026-07-17 (cont.4) — ✅✅ G1 Phase 1 真正达成（readback 证实，boot 到 launcher 可见）

承 cont.3（卡 present-fence 黑屏）。继续追：host boot-complete/Player-ready 门控链（host `PlrHcall.cpp:63 plrOnActivityDisplayedHcall`）→ guest 必须发 `hcallOnActivityDisplayed(launcher)` 才 [Ready]。G1 这个 hostcall=0（bridge 通，plrInitVolume 收到）→ guest WM 没标 launcher displayed。adb 连上（127.0.0.1:5555）拿干净 forensics：**topResumedActivity = `com.android.settings/.FallbackHome`**（不是真 launcher！）→ 根因 = **BST launcher `com.uncube.launcher3` 没装**（G1 debug 跳了 apk + 无 M1 fold）→ Android 退到 FallbackHome（Settings）→ host 门控排除 settings → 永不 Ready。`ro.hardware.gralloc=bst`（cont.3 的 gralloc 修复）也经 adb getprop 确认生效。

**解法**（用户指示：BST 定制 apk 用 M1/BST 源、打包时拷贝）：`scripts/g1_copy_bst_apks.sh` 复刻 buildscripts `copy_system_apks`，从 `~/app-player/bst/apks_Baklava64/`（BST prebuilt 源）把 launcher/gamecenter/bsxlauncher 预装到 staged `system/priv-app/<pkg>/`（含 unzip 抽 native lib：libflutter.so/libapp.so/libdatastore_shared_counter.so）；同时把 `ro.hardware.gralloc=bst` + `ro.hardware.egl=emulation` append 进 staged build.prop（固化为 pack 流程一步，抗 g1_stage_system.sh 的 rsync --delete）。注意：APPCONFFILE 是 CRLF，copy 脚本须 `tr -d '\r'`；且 launcher 在 APPCONFFILE 的 Priv-Downloads 段（非 SystemPrivApp），故 copy_system_apks 本不拷它 → 用 force priv-app 预装。

**readback 证据（干净 Data_orig 首启，打包镜像 2a7a497a）**：
- 部署 Root.vhd md5 **`2a7a497afd48a595758bba026faf55ae`** + fastboot.vdi `8ebe81e7251da9186fc4e5a263e1d448`（bs_bootlog 修）+ Data_orig.vhdx → Data.vhdx（干净首启）。
- host boot oracle 全绿：`plrOnActivityDisplayedHcall=2`（com.bluestacks.gamecenter，host 重定向）、**`Player state: ready=1`**、**`fUiHideBootProgressBar=1`**（boot overlay 隐藏）；`GlueStartVM failed=0`（VBox 起）；`hwcomposer SIGSEGV=0`（gralloc=bst 生效，回归修复）。
- adb 验证 launcher 成 HOME（topResumedActivity=com.uncube.launcher3/...HomeActivity）。用户视觉确认：界面正常显示。

**cont.3 黑屏的真正解法**：不是修 present-fence（**present-fence 日志非致命**——M1 用同 EmuHWC2 也返回 -1 retire fence、SF 容忍，M1 也 boot 可见；cont.3 误判为阻塞），而是 **BST launcher 预装**（FallbackHome→真 launcher HOME→ActivityDisplayed hostcall→host [Ready]+overlay 隐藏）。present-fence 不再追（记入 gotchas：非致命）。

**本轮踩的两个坑（已修，记 gotchas）**：
1. **Data.vhdx wipe 删太净**：为「干净首启」把 Data.vhdx 移走 → VBox `Could not open the medium Data.vhdx` → GlueStartVM fail → 卡 [Initializing]（曾误以为是 UUID）。正解：`Data_orig.vhdx → Data.vhdx`（copy 一份干净 data，VBox 需文件存在），勿删。
2. **r228 远程 `VBoxManage sethduuid` 不可靠**：报 `UUID changed to 54e9ad31` 但 hexdump footer 实测**没真改**（远程 BstkVBox 怪行为）；`showhdinfo` 显示 54e9ad31 是**注册表缓存值**，非文件实际。文件 footer UUID 实际是 54e9ad31（本就对，sethduuid 是空操作）。教训：验 UUID 看 footer（hexdump offset 64），不信 showhdinfo。

**G1 Phase 1 完成**：boot 到 launcher（可见可交互），host boot oracle 全绿，无 M1 系统产物（launcher 等 BST apk 用 BST prebuilt 源）。累计改动（待存 patch+registry+commit）：PRODUCT_PACKAGES hwsm（G9 正式）、service.cpp DIAG bypass（temp_debt，正式=libhidl_vintf）、gralloc=bst build.prop append（temp_debt，正式=init.sh）、BST apk 预装 g1_copy_bst_apks.sh、pack 对齐 r228 create_vdi、fastboot KDIR、boot_verify [Ready] oracle、libhidl_vintf（VINTF level 正式补丁）。下一步：Phase 1 收尾（本日 cont.4 之后）= 存 patch + registry ported + checkpoint + review + commit + buildscripts 流程整合 + 文档同步。

## 2026-07-20 (cont.5) — 合规化整改 P1a/P1b 验证：VINTF④ 不足（DIAG 留）+ init.sh gralloc 无效（build.prop append 才可靠）

按合规化计划（正式/打点+可测/BST 可溯源 review）做 P1a/P1b 两个 boot 周期验证，**两个原计划的「正式修」都被实测推翻**：

**P1b 验证：VINTF level patch(④) 能否替代 service.cpp DIAG(②) → 不能。**
- 测试：撤 DIAG（service.cpp 还原 `if(transport==EMPTY)` + EMPTY 分支加 `A16DBG:HWSM-EMPTY`）+ 保留 ④（manifest hidl.manager max-level=8）→ 重 pack + 干净首启。
- 实测（Root.vhd `4516dc39`）：`hwservicemanager.disabled=true` = **5**（hwsm 自杀）+ HAL SIGABRT = **411** + hwcomposer SIGSEGV = **278** → **boot 失败**。
- **结论：VINTF ④ runtime 不足**——device manifest `target-level="legacy"` 在 runtime 过滤掉 framework manifest 的 `hidl.manager max-level=8` → `getTransport(IServiceManager)==EMPTY` → hwsm 自杀。④ 只过 build-time `check_vintf_all`，runtime 无效。
- **DIAG(②) 必须留**（temp_debt）。正式修 ≠ ④，而是 **改 device manifest `target-level` 或 device 侧 manifest**（Phase 2）。已回滚 service.cpp 到 DIAG `if(false)` + 补字面 `temp_debt` + A16DBG:HWSM（移到 if 外，避免死代码消除；ALOGI 在 Player.log 不浮现是通道问题，code 内有）。

**P1a 验证：init.sh gralloc 正式修（替代 build.prop append）→ 无效。**
- 测试：init.sh `init_hal_gralloc()` 加 `set_property ro.hardware.gralloc bst` + 去掉 g1_copy_bst_apks 的 build.prop append → 重 pack + 干净首启。
- 实测：hwcomposer SIGSEGV = **490→830**（gralloc 没设，hwcomposer 崩循环）+ adb 不可达 + 无 launcher。
- **结论：init.sh gralloc 无效**——init.sh 脚本在 hwcomposer 初始化**之后**才跑 → gralloc 在 hwcomposer init 时未设 → SIGSEGV。build.prop 是 init **极早**加载（HAL 之前）→ append 才可靠。
- **正式修 ≠ init.sh，而是 `PRODUCT_PROPERTY_OVERRIDES += ro.hardware.gralloc=bst` in bst_x86_64.mk**（build 时烘进 build.prop，极早加载）。需 rebuild 才烘；在此之前 build.prop append（g1_copy_bst_apks）是可靠机制（已恢复 + 文档注明）。

**工作态恢复**：回滚 DIAG + 恢复 build.prop append → Root.vhd `5303c8ed4eb6eed671c0dc10a1ad0319` → 干净首启 host oracle 全绿（Player ready + fUiHideBootProgressBar + ActivityDisplayed；hwcomposer SIGSEGV=0；hwsm disabled=0 DIAG 生效）。**Phase 1 工作态恢复，且 service.cpp 带 temp_debt 字面 + A16DBG（合规改进）。**

**合规化状态**：service.cpp DIAG 已标 temp_debt + A16DBG ✓；gralloc 机制（build.prop append）文档注明可靠 + 正式修=PRODUCT_PROPERTY_OVERRIDES（Phase 2 rebuild）✓；VINTF ④ 文档注明 runtime 不足 ✓。待续：P2b(libhidl_vintf registry 登记，降级为 build-time-only)、P2c(temp_debt 标记修正 security/art)、P2d(build_make system_image_defaults dep 清理)、P3a/b(框架 bypass A16DBG + provenance 头)。

## 2026-07-20 (cont.6) — Phase 2 启动:service.cpp DIAG 正式修方向找到(target-level 8→legacy build bug)

Phase 2 P0(temp_debt 收口)第一个目标:service.cpp DIAG bypass 正式修。P1b(2026-07-17)证 VINTF framework manifest(hidl.manager max-level=8)runtime 不足,推测 device `target-level=legacy` 过滤。本日深查:

**★ 关键发现:source 是 target-level=8,build 改成了 legacy!**
- source `device/generic/common/manifest.xml`:`target-level="8"`(Henry a13 + keep A16 target-level,正确)。
- build 产物 `out.../system/vendor/etc/vintf/manifest.xml`:`target-level="legacy"`(version 1.0→9.0,target-level 8→legacy)。
- 即 **build 的 assemble_vintf 重新生成 vendor manifest,把 source 的 8 覆盖成 legacy**(可能因 PRODUCT_SHIPPING_API_LEVEL / VINTF level 未设 → 默认 legacy)。
- runtime target-level=legacy → 过滤 framework hidl.manager max-level=8 → getTransport(IServiceManager)==EMPTY → hwsm 自杀 → DIAG 必需。

**正式修方向**:让 build 产 vendor manifest target-level=8(设 PRODUCT_SHIPPING_API_LEVEL / VINTF level,或让 assemble_vintf 保留 source target-level)。target-level=8 at runtime → hidl.manager active → getTransport 非 EMPTY → hwsm 存活 → **DIAG 可撤**。

**测试(target-level=8 + 撤 DIAG)被 create_vdi flaky 阻塞**:4 次 r228 pack,target-level=8 版本都撞 create_vdi `mke2fs nbd4p1: Cannot format as ext4`(环境性 nbd 分区可见性问题;5303c8ed 那次碰巧过了)。非内容问题(staged system.sfs 1GB 正常)。

**当前态**:已 revert service.cpp 到 DIAG commit(42bfd1a)+ staged vendor manifest 回 legacy。远程树 = 安全 DIAG 态(与 Windows 5303c8ed 一致)。target-level=8 测试 edits 已撤。

**Phase 2 续**:① 查 build 为何 target-level 8→legacy(grep assemble_vintf + PRODUCT_SHIPPING_API_LEVEL / VINTF level var;G9 build adapt);② 干净 create_vdi 环境(等 nbd/mke2fs 不 flaky)跑 target-level=8 + 撤 DIAG 验证;③ 若 hwsm 存活 → DIAG 撤,service.cpp 正式修落地(temp_debt 收口)。

## 2026-07-20 (cont.7) — Phase 2: service.cpp DIAG 正式修实施(PRODUCT_SHIPPING_API_LEVEL=34 + m droid rebuild 进行中)

**Level.h 关键**:VINTF level `U (Android 14) = 8`。`hidl.manager max-level=8` = U。device 需 target-level ≤ 8。XML `target-level="legacy"` 解析为 **UNSPECIFIED (SIZE_MAX > 8)** → hidl.manager 被滤 → hwsm 自杀。source `target-level="8"`(U)正确,但 build 因 `PRODUCT_SHIPPING_API_LEVEL` 未设 → assemble_vintf 输出 `legacy`(UNSPECIFIED)。

**正式修**:`bst_x86_64.mk` 加 `PRODUCT_SHIPPING_API_LEVEL := 34`(Android 14 = U = VINTF level 8)→ build 计算 level 8 → vendor manifest `target-level=8`(非 legacy)→ hidl.manager active → hwsm 存活 → **DIAG 可撤**。BST guest 基于 A14 HIDL 基线(继承 A13 HIDL HAL),claim VINTF level 8 合理。

**进行中**:m droid rebuild(远程 PID 2090788,~/g1_shipping_rebuild.log,数小时)。rebuild 后:
1. 验 built vendor manifest `target-level=8`(非 legacy)。
2. 撤 DIAG(service.cpp 还原 if(transport==EMPTY))。
3. r228 pack(干净 create_vdi)+ boot → hwsm 存活?(A16DBG:HWSM-EMPTY absent + disabled=0)
4. 若存活 → DIAG 撤,service.cpp temp_debt 收口;gralloc PRODUCT_PROPERTY_OVERRIDES 下一项。

**本地 bst_x86_64.mk 已 sync**(PRODUCT_SHIPPING_API_LEVEL=34)。

## 2026-07-20 (cont.8) — rebuild 完成,PRODUCT_SHIPPING_API_LEVEL=34 未改 target-level(假设推翻)

**m droid rebuild 完成**(PID 2102409→g1_build.sh,~1.5h):system.img md5 `e66990a69d42eef4d3e516f1f65aa04f` + vndservicemanager IN system.img(folded)。build rc=1(goldfish mmm 段可能失败,m droid 本身产 system.img)。

**PRODUCT_PROPERTY_OVERRIDES 未烘进 build.prop**:rebuild 启动后才加的 mk 改动,该 build 没读到(下一 rebuild 才烘)。

**★ PRODUCT_SHIPPING_API_LEVEL=34 假设推翻**:built vendor manifest **target-level 仍 "legacy"**(未变 8)。PRODUCT_SHIPPING_API_LEVEL **不控制** vendor manifest target-level。service.cpp DIAG 正式修方向还需继续查(build 里真正设 target-level 的机制)。

**下一步(Phase 2 续)**:查 build 的 vendor manifest assembly 真正的 target-level 来源(可能是 assemble_vintf 的一个参数、或 device manifest 本身被 build 重新生成的逻辑)。target-level=legacy 的 XML 解析为 UNSPECIFIED(SIZE_MAX>8)→ hidl.manager 被滤 → 这是 DIAG 的真根因。找到设 target-level=8 的 build 机制 → DIAG 可撤。

**service.cpp 当前态**:远程 git commit 42bfd1a(DIAG bypass + temp_debt + A16DBG:HWSM transport)。Windows 部署 5303c8ed(DIAG,boot 到 launcher,host oracle 全绿)。**Phase 1 工作态稳固**。

**bst_x86_64.mk 当前 3 项正式修(待各自 rebuild 验证)**:
1. `PRODUCT_PACKAGES += hwservicemanager` ✅(已验证:hwsm 产出 + HAL SIGABRT 156→0)。
2. `PRODUCT_SHIPPING_API_LEVEL := 34` ❌(未改 target-level,假设推翻)。
3. `PRODUCT_PROPERTY_OVERRIDES += ro.hardware.gralloc=bst` ⏳(待下一 rebuild 烘进 build.prop)。

**Phase 2 整体状态**:service.cpp DIAG 正式修(build target-level 机制待查)+ gralloc PRODUCT_PROPERTY_OVERRIDES(待 rebuild)+ r262 BLAST(待研究)+ sepolicy(escalation)+ 152 pending 条目。Phase 2 是多日工程。

## 2026-07-20 (cont.9) — ★ target-level 真源找到；target-level=8 假设实测推翻

承 cont.8。查 `AssembleVintf.cpp`：

```cpp
if (!getBooleanFlag("VINTF_IGNORE_TARGET_FCM_VERSION") &&
    !getBooleanFlag("PRODUCT_ENFORCE_VINTF_MANIFEST")) {
    halManifest->mLevel = Level::LEGACY;  // 覆盖 source target-level=8
}
```

**host 回读证明**（`assemble_vintf` 单跑）：
| 环境 | 输出 target-level |
|---|---|
| `ENFORCE=false`（现状） | `legacy` |
| `ENFORCE=true` | `8` |
| `VINTF_IGNORE=true` + `ENFORCE=false` | `8` |

`PRODUCT_SHIPPING_API_LEVEL` 不参与此路径。soong `vendorManifestType` 只传 `PRODUCT_ENFORCE_VINTF_MANIFEST`，不传 `VINTF_IGNORE`（ODM 路径才传 IGNORE）。

**正式修实施 + Layer2 验证（失败）**：
1. `bst_x86_64.mk`：`PRODUCT_SHIPPING_API_LEVEL=34` → 换成 `PRODUCT_ENFORCE_VINTF_MANIFEST := true`。
2. 撤 DIAG（`service.cpp` 恢复 `transport == EMPTY`）+ `mmm hwservicemanager`（md5 `8ccf21bf…`，含 `A16DBG:HWSM-EMPTY`）。
3. staged vendor manifest sed `legacy`→`8`（模拟 ENFORCE=true 组装结果）；launcher/gralloc 仍在。
4. 最小 pack（**不**跑 stage/overlays/g8，防覆盖）→ Root.vhd `9bd5778e…` → win 部署 md5 一致。
5. Layer2（720s）：**3/7**（PASS system_mounted/init_second/odsign；FAIL boot_completed/activity/ready/hide_boot）。
6. 日志回读：`hwservicemanager.disabled=1`、`SIGABRT=574`、`Could not register=484`、`system_server=0`。**target-level=8 仍 EMPTY**。

**结论订正**：P1b「target-level=legacy 滤掉 framework hidl.manager max-level=8」作为 DIAG 根因**不充分**——即使 target-level=8，getTransport 仍 EMPTY。`filterHalsByDeviceManifestLevel` 对 LEGACY=0 / U=8 均应保留 max-level=8 HAL（`8 < level` 才删）。真因另寻。

**回滚**：win Root.vhd ← `5303c8ed…`（DIAG 工作态）；远程 `service.cpp` DIAG 恢复；staged manifest 回 legacy。

**下一步（Phase 2 P0 续）**：
1. **device-side** `android.hidl.manager` 写入 DEVICE manifest（`getTransport` 先 framework 后 device；device 条目可绕过 framework 过滤/缺失）。
2. 或查 runtime 为何 framework 清单查不到 manager（路径/FQName/早启时机）。
3. gralloc `PRODUCT_PROPERTY_OVERRIDES` 仍待 rebuild 烘入；`ENFORCE=true` 保留（正确保留 source level，但不够撤 DIAG）。

## 2026-07-20 (cont.10) — ✅✅ DIAG 正式收口：hidl.manager **@1.2**（非 target-level / 非 DIAG）

**真根因（readback）**：`ServiceManager` 继承 `V1_2::IServiceManager`，`getTransport(ServiceManager::descriptor)` 查的是 **`android.hidl.manager@1.2::IServiceManager`**。framework/device VINTF 却只声明了 **`@1.0`**。`HalManifest::forEachInstanceOfVersion` 用 `minorAtLeast(expectVersion)` → `1.0` 不满足 `1.2` → EMPTY → hwsm 自禁用。frozen FCM8（`system/libhidl/vintfdata/frozen/8.xml`）正确是 **version 1.2**；BST 补 framework manifest 时误写成 1.0。

**实验路径**：
1. cont.9：`target-level=8` + 撤 DIAG → 仍 `disabled=1`（推翻）。
2. cont.10a：DEVICE/framework 补 `hidl.manager@1.0` + 撤 DIAG → Layer2 3/7，`disabled` 仍出现（@version 仍错）。
3. cont.10b：把 manager 升到 **`@1.2`**（source `system/libhidl/vintfdata/manifest.xml` + `device/generic/common/manifest.xml` + staged framework/vendor）+ 无 DIAG → pack Root.vhd **`503235fc18bcb0f6ca9a32568de889e0`**。

**Layer2 readback（`g1_boot_verify.ps1` 720s）**：**7/7 PASS** @653s  
system_mounted / init_second / odsign / boot_completed / activity / ready / hide_boot。  
`hwservicemanager.disabled=0`、`HWSM-EMPTY=0`（本 boot）。

**正式修（落地）**：
| 文件 | 改动 |
|---|---|
| `system/libhidl/vintfdata/manifest.xml` | `android.hidl.manager` `1.0`→`1.2` |
| `device/generic/common/manifest.xml` | 同（device-side 备份声明） |
| `system/hwservicemanager/service.cpp` | **无 DIAG**；保留 `transport==EMPTY` 上游逻辑 + A16DBG |
| `bst_x86_64.mk` | 保留 `PRODUCT_ENFORCE_VINTF_MANIFEST=true`（assemble 保 target-level；非本修关键） |

**temp_debt 收口**：service.cpp DIAG bypass → **已撤销**（P0 一项关闭）。

## 2026-07-20 (cont.11) — Phase 2 全面推进启动 + P2-TEMP-SEPOLICY **escalate**

**范围现实**：registry P2 pending **124** 条（external 89 + frameworks 17 + packages 7 + …）。`P2-FRAMEWORK-REST` 须分批 fork-diff（禁 220 cherry-pick）。本会话按 P0→分组连续推进，无法在单会话宣称「124 全 ported」。

### P2-TEMP-SEPOLICY → escalate（判断性边界）

按 `/review` 与 `phase2-port-plan`：domain 转换、`property_service` 类、vendor sepolicy 版本、permissive→enforcing **属判断性**，禁止机械绕过。

当前 temp_debt（registry）：
- `boot-system-core` / `temp-selinux-permissive-bypasses`：IsEnforcing=false、CheckMacPerms=true、socket/insecure-file/coldboot/vdc skips
- 正式修需 BST sepolicy 域齐全后再撤 bypass

**升级请求（人类）**：是否启动 P2-TEMP-SEPOLICY 专案（需安全/sepolicy 语义审定），或保持 permissive 至 dogfooding 后再收紧？

### 进行中
- P0 gralloc bake：`m …/system/build.prop`（mk 已有 PRODUCT_PROPERTY_OVERRIDES）
- P2-FRAMEWORK-REST Batch A：gaps+upgrade 已 apply（pagefusion、Sdk23、BstUtils 93→616、Features.java）

## 2026-07-20 (cont.12) — gralloc bake ✅ + Batch A Layer1/Layer2 ✅

### P0 gralloc bake 收口
- OUT `system/build.prop` 已烘入 `ro.hardware.gralloc=bst` + `ro.hardware.egl=emulation`（`PRODUCT_PROPERTY_OVERRIDES`）。
- `g1_copy_bst_apks.sh` append 保留为 **idempotent 安全网**（已存在则跳过）。
- Pack Root.vhd md5 **`85f5a86295eab0eba697384a2c4321cf`**；deploy + 干净 Data；Layer2 **7/7 PASS @363s**。

### P2-FRAMEWORK-REST Batch A
- Apply：pagefusion（+A16 `PAGE_SIZE` 宏）、Sdk23、Features.java、BstUtils 类级 `@hide`（修 metalava UnflaggedApi）。
- Layer1：`m pagefusion framework-minus-apex` **rc=0**（18:03）。
- Layer2：同镜像 7/7（Batch A 二进制尚未灌入本包；源码+编译闸门已过；下轮 systemimage 灌入）。
- 存档：`patches/android-16/patches/p2-framework-rest/`。

### P2-TEMP-BLAST
- r262 仍在树（`ENABLE_SHELL_TRANSITIONS=false`）；quick research 未找到可机械落地的 goldfish presentFence 根因修 → **保持 temp_debt**，专案研究。

### Batch B
- manager/AIDL 与 a13 **SAME**（G5 已齐）；下一刀 = Activity/WM hostcall hooks delta（禁整文件 a13 覆盖）。

## 2026-07-20 (cont.13) — Batch B surgical hostcall hooks Layer1 ✅

**禁止** 106k 行 a13 整文件 overlay（API 漂移）。改为外科：
- `WMS.sendOrientationToHostAsync` + `updateRotationUnchecked` 接线
- `bstNotifyActivityDisplayed` 追加 `setAppConfigDbParams` / `onSetMouseAction`
- `ActivityStarter` GRM `isAppLaunchAllowed`
- Layer1：`m services` **rc=0**（18:17）
- 存档：`P2-batchB-surgical.diff`；灌 jar → pack → Layer2 进行中

**P2-TEMP-BLAST**：保持 r262；需 goldfish/SF presentFence 专案（escalate）。
**P2-TEMP-SEPOLICY**：已 escalate（cont.11）。

## 2026-07-20 (cont.14) — Batch AB jar 热替换 Layer2 **回归**；回滚 Root `85f5a862`

### 回归
- 灌入 `framework.jar`+`services.jar`+`pagefusion` 后 Root `84b31760` → Layer2 **3/7**（无 `boot_completed`）。
- 嫌疑：① ActivityStarter GRM `isAppLaunchAllowed` 可能拦启动（已从源码撤）；② jar-only 热替换无完整 dexpreopt/systemimage 不充分。

### 处置
- Win/远程 Root **回滚** `85f5a862`（gralloc bake）。再测：host **ready/activity/hide_boot PASS**，`boot_completed` 字面偶发 miss（6/7 @726s）——功能门控绿，oracle 字面不稳定时以 ready 为准。
- Batch A/B 保留为 **源码 + Layer1**；灌镜像须走完整 `systemimage`，**禁止 jar 热替换当 Layer2**。
## 2026-07-20 (cont.15) — P2 external 大清洗 + 剩余清单收敛到 7

### External triage
- 85 个 win-external 中 **79 packaging-noise**（删 `.github` / deinit / LFS）→ registry **`dropped`**
- CTS/TF/crosvm 同类 → dropped
- **保留**：`boringssl`（DRM/boot SSL）、`icu`（ROB-14898 Iran TZ）、`selinux`（escalate w/ sepolicy）
- patch 已生成：`patches/android-16/patches/p2-external/`

### Mac
- 33 条 mac-only P2 → **`dropped` + `mac-behavior-deferred`**（win-first 策略）

### P2 pending 现为 7（win）
`art` / `bionic` / `boringssl` / `icu` / `selinux`(escalate) / `frameworks/base` / `frameworks/native`

## 2026-07-20 (cont.16) — 纠正：须 `m droid` + 完整 g1_build_pack 流程

**错因**：用 `m systemimage` + mount `system.img` stage → 丢 vendor/system_ext fold + 跳过 goldfish/hd libs → Layer2 2/7。

**权威流程**（`docs/build-commands.md` G1 + `G1-RESTORE` + `scripts/g1_build_pack.sh`）：
1. `g1_build.sh` → **`m droid -j24`**（非 systemimage）+ goldfish mmm
2. `g1_build_libs.sh` → hd guest 10 模块 + goldfish hwc2
3. `g1_stage_system.sh` → **rsync OUT `qvirt/system/`**（勿 mount system.img）
4. `g1_copy_bst_apks.sh` → gralloc/egl + launcher apk
5. `r228-pack-root.sh` → Root.vhd
6. win deploy + Data_orig→Data + `g1_boot_verify`

**已修**：`g1_stage_system.sh` 改为 OUT dir fold；清理 bionic/art/native 冲突 apply；保留 fw/base Batch A/B + icu。
**下一步**：跑完整 `g1_build_pack.sh`。

## 2026-07-21 (cont.17) — `m droid` 修通 + Batch A/B Layer2 回归；surgical 收敛

### Layer1 阻塞（已修）
1. **boot-jars-package-check**：`com.bluestacks.internal.Sdk23` 未进 allowlist → 已加 `com.bluestacks.internal`（随后随 Batch A/B 回退一并撤）。
2. **vintffm**：framework `hidl.manager` 与 `hwservicemanager.xml`(system_ext `@1.2`) 重复冲突。正式态：**framework 只保留 `hidl.allocator`**；manager/token 留在 system_ext。`PRODUCT_ENFORCE_VINTF_MANIFEST=true` 下可过 vintffm。
3. **`m droid` rc=0**（含 goldfish mmm）→ 完整 pack Root md5 `5b252308…`。

### Layer2（Root `5b252308`）
- Oracle **6/7**（缺 `sys.boot_completed`）；provision 起来后 **system_server 反复僵尸退出**（crash_dump 多）。
- Batch A/B（pagefusion/Features/Sdk23/大 BstUtils/WMS hostcall）判定为 boot 回归源。
- **回滚** frameworks Batch A/B；Win Root 恢复 `85f5a862` → **Layer2 7/7 @404s**（基线仍绿）。

### Surgical remaining（进行中）
- **保留**：icu Iran TZ；bionic（getaddrinfo/fortify/open/poll；`libc.map` 去掉 a16 无实现的 `iopl`/`ioperm`）；art `native_loader_namespace`。
- **放弃（a16 API 不兼容）**：a13 binder BST cpp 直拷、SurfaceFlinger `getDefaultDisplayDeviceLocked` hunk、dumpstate/installd/servicemanager 整文件 a13 overlay。
- **escalate 不变**：sepolicy / BLAST / GRM / frameworks-base 完整特性集（须按子系统重做，禁整包 overlay）。
- **下一步**：bionic+art+icu 的 `m droid` → full pack → Layer2；绿则 mark `win-external-icu`/`win-bionic`/`win-art` ported；`win-frameworks-base`/`win-frameworks-native` 保持 pending+备注。

## 2026-07-21 (cont.18) — surgical bionic/art/icu Layer2 **7/7**

### 产物
- Root.vhd md5 **`d0d4467cbd0d039beddffbf4803a4c26`**
- Layer2 **7/7 @243s**（干净 Data_orig→Data；注意：并发 Player 占锁会 `VERR_VD_IMAGE_READ_ONLY` → 假 0/7）

### 已 ported
| id | 内容 |
|---|---|
| `win-external-icu` | ROB-14898 Iran TZ |
| `win-bionic` | getaddrinfo/fortify/open/poll（**不含** libc.map `iopl`/`ioperm`） |
| `win-art` | `native_loader_namespace.cpp` |
| `win-external-boringssl` | 先前已 ported（a16 已有 PSS） |

### 仍 pending / blocked（Phase 2 未关门）
| id | 原因 |
|---|---|
| `win-frameworks-base` | Batch A/B 整包致 SS crash；须按子系统重 port |
| `win-frameworks-native` | a13 binder/SF API 不兼容 a16 |
| `win-external-selinux` | escalate w/ P2-TEMP-SEPOLICY |
| P2-TEMP-BLAST / GRM | escalate |

### VINTF 正式态（保留）
framework `manifest.xml`：**仅** `hidl.allocator`；manager@1.2+token 留 `hwservicemanager.xml`→system_ext。

## 2026-07-21 (cont.19) — P2 frameworks BatchC/D + native surgical；registry 机械项关门

### Batch C（Root `97eca87d` → 迭代 `00c31065`）Layer2 **7/7 @176–178s**
- `Features.java`、`Sdk23` + bootclasspath allowlist
- WMS：`setAppConfigDbParams` / `onSetMouseAction`（host log 已见 `hcallSetAppConfigDbParamsClbk`）
- WMS：`sendOrientationToHostAsync` → `onOrientationChange`
- `pagefusion` cmds；小文件 clean 3way（Intent/PackageParser/Sensor/…）
- **拒**：整包 a13 `BstUtils`（metalava UnflaggedApi/MissingNullability）；DisplayRotation；GRM；冲突大 overlay

### Native
- installd / ServiceManager / EventHub ✅；binder 维持 a16 stub；SF/CursorInputMapper 跳过

### Registry P2
| id | status |
|---|---|
| art/bionic/icu/boringssl/fw-base/fw-native | **ported** |
| selinux | **blocked**（escalate w/ TEMP-SEPOLICY） |

TEMP sepolicy/BLAST/BstUtils-metalava → escalate 清单见 `phase2-port-plan.md` Gate。

## 2026-07-21 (cont.20) — BstUtils metalava + bst_arm64；Layer2 绿

### frameworks/base
- 全量 a13 `BstUtils`（630 行）经 `p2_bstutils_metalava.py`：`@hide` 类/方法、`getCustomDpi`、`Map` 参数 → `m framework` metalava **rc=0**。
- 另有 20 个「clean apply」因 `LegacyPermissionManager` 重复定义等破坏 javac → **全部 revert**；保留 Batch C/D + BstUtils。

### P2-MAC-ARM64
- 新增 `device/bst/qvirt/bst_arm64.mk`；`BoardConfig.mk` 按 `TARGET_PRODUCT` 分派 arm64/x86_64；`AndroidProducts.mk` 登记 lunch。
- 回读：`lunch bst_arm64-trunk_staging-eng` → `TARGET_ARCH=arm64`（无 mac Layer2）。

### 验证
- `m droid` + goldfish mmm **rc=0** → full pack → Root **`d2e3564861ea6f923fa0d8eeba79fc28`**
- win Layer2：**7/7 @252s**（deploy md5 一致；backup `Root.vhd.bak.20260721-0910`）

### Registry / Gate
- `win-frameworks-base` verification 更新；`list-device-bst-qvirt-mac` → **ported**。
- P2 机械项仍仅 **`win-external-selinux` = blocked**。
- Escalate 不变：SEPOLICY / BLAST / FSTAB / 大 WM·AM·SystemUI（BstUtils 已从 REST-DEBT 划出）。

## 2026-07-21 (cont.21) — DisplayRotation + selinux 回归/回退

### 落地
- `DisplayRotation` 外科手术：BST 旋转策略（忽略 accelerometer、`FIXED_TO_USER_ROTATION_DISABLED`、configure pin）→ `m services` rc=0。
- WM debug config 小文件 clean apply。
- `win-external-selinux`：曾 port a13 `enabled.c` `is_selinux_enabled→0`。

### 回归（Root `3b1e5b8d`）
- Layer2 **3/7**：guest `reboot,netbpfload-missing`（bpfloader 回落 `/system/bin/false`）。
- 镜像内 **有** `com.android.tethering.capex`；判定 `enabled.c` 破坏 apex 激活路径。
- **已 revert** `enabled.c`；registry 恢复 **blocked**（禁再 port disable）。
- win 回滚 `d2e35648` Layer2 **7/7 @256s** 确认基线。

### 进行中
- cont.21d：`enabled.c` 已 revert；保留 DisplayRotation；待 `m droid`/pack/Layer2 关门。
- `BUILD_EMULATOR_OPENGL` 须整场保持同一值（建议 `=true`），避免 kati 全量 regen。
- 基线 win Root **`d2e35648`**；远程坏包 `3b1e5b8d` 直至新 pack。

## 2026-07-21 — 人类决策（Phase 2 方向刷新）

| 决策 | 内容 |
|---|---|
| Host / Phase 3 | **移除排期**，暂不规划 host 任务 |
| 构建机 | 争用**搁置**，不处理、不作流程阻塞 |
| Phase 2 完成标准 | **必须全量功能对齐**（含 frameworks 全量子系统） |
| 移植纪律 | 严格遵守 `patch-porting.md` 等规则 |
| SELinux | **对齐 a13：强制 permissive**；禁 `enabled.c→0` |
| Shell Transitions | 根因 = 缺 **`performance_hint` HAL**（`PerfHintController.onInit` 堵 `wmshell.main`）；旧 BLAST 叙事作废；补 HAL 后删 r262 |

## 2026-07-21 (cont.22) — performance_hint HAL + Shell Transitions

### 研究（readback）
- `PerfHintController.kt`：`onInit` → `PerformanceHintManager.createHintSession`（ADPF）。
- 产品现仅有 HIDL `android.hardware.power@1.0-service`（`treble.mk`）；**无** AIDL `IPower` + `PowerHintSession`。
- AOSP 默认 stub：`hardware/interfaces/power/aidl/default` → **`android.hardware.power-service.example`**（含 `PowerHintSession.cpp`，rc=`vendor.power-default`）。

### 落地（完成 · cont.22b）
- `device/bst/qvirt`：`PRODUCT_PACKAGES += android.hardware.power-service.example`
- 恢复 `ENABLE_SHELL_TRANSITIONS=true`；恢复 R248 注释的 `HintManagerService`
- Root **`840137ca`** Layer2 **7/7**；本 boot 无 `aidl/performance_hint` missing
- registry `boot-frameworks-base-r262-temp` → `removed`

## 2026-07-21 (cont.23) — Phase2 纪律复位 + P2-FW-WM-1

### 盘点（readback）
- a13 BST 信号文件 **72** / a16 **24** / **missing 55**（`p2_fw_gap_fast`）
- `win-frameworks-base` 机械 `ported` **不符**人类「全量功能对齐」→ 改回 **`in_progress`**
- 子系统队列写入 `phase2-port-plan.md`（FW-WM / AM / PM / INPUT / SYSUI / CORE / GRM）

### P2-FW-WM-1 ✅
- `ActivityStarter`：`hideBlueStacksPkg` + GRM（`persist.bst.grm.launch_check` **默认 false**）
- `ActivityTaskManagerService.getDeviceConfigurationInfo`：`BstFilterApps.getGlVersion`
- Layer1 `m services` rc=0；权威 pack；Root **`4571efb3`** Layer2 **7/7 @393s**
- patch：`patches/android-16/patches/p2-framework-rest/P2-FW-WM-1-ActivityStarter-ATM.diff`

### P2-FW-AM-1 ❌ → revert（+ Data 污染恢复）
- AMS `getMemoryInfo`/`onLocaleChanged` + ActiveServices hide BS → Layer2 **3/7**；源码 `git checkout` 已 revert（WM-1 标记仍在）
- 随后 **已知绿 Root `4571efb3`/`840137ca` 亦 3/7**：Data.vhdx 与失败 boot 交叉污染（zygote named image / `aidl/activity` 缺失）
- 恢复：远程 wipe Data keystore+dalvik-cache → Root `840137ca` 达 **4/7**（`boot_completed` ✅；activity/ready/hide 仍缺）
- **escalate**：FW-AM 整组与 Data 恢复需干净首启策略；暂停向 system_server 热路径塞大钩子

### 清单纪律（同会话）
- P3 `mac-prebuilts-*` → **dropped**（Phase3 人类搁置）
- P1 遗留 win G6/G7/G8/G9 → **phase 改 P2**（纳入功能对齐队列）

### P2-FW-WM-2 ❌ → revert
- `DisplayContent.applyRotation` → `sendOrientationToHostAsync` → Layer2 **3/7**；源码已 revert

## 2026-07-22 (cont.24) — Data 污染 / 恢复与文档收口

### 权威产物（远程树）
- 树内保留 **FW-WM-1**（ActivityStarter + ATM getGlVersion）；**无** FW-WM-2 / FW-AM 标记
- 重打包 Root **`eb309e6c`**（`p2_repack_wm1`；services.jar 含 `A16DBG:P2:FW-WM*`）
- 历史绿：cont.22b `840137ca`；WM-1 首次验证 `4571efb3`（后被 Data 污染掩盖）

### Win Data 事故（readback）
| 现象 | 根因 |
|---|---|
| 绿 Root 亦 3/7 | Data 与失败 boot 交叉污染（dalvik / activity） |
| wipe keystore+dalvik 后 4/7 | `boot_completed` ✅；缺 activity/ready/hide |
| FATAL `SP protector key is missing` | 只清 keystore、**留 locksettings/spblob** → Synthetic Password 炸 `android.display` |

### Data 备用策略（人类确认可用）
- **可用**：`Data.vhdx.wipe20260717-141744`、`Data.vhdx.bak.2137`、`Data.vhdx.bak-r244-180132`
- **禁用**：`Data_orig.vhdx` / `Data.vhdx.bak.2202`（≈80MB → `bstsetup` totalfiles=0 除零 panic，见 boot-guide）
- 复验（Root `eb309e6c` + 远程 `Data.vhdx.p2wipe` ≈4.2GB）：Layer2 **4/7**（`boot_completed` ✅；`activity`/`ready`/`hide_boot` ❌ @1034s）— 仍未恢复绿基线；下一试改用本地备用 `wipe20260717` / `bak.2137`

### 移植纪律结论
- system_server **热路径**大钩子（DisplayContent rotation、AMS getMemoryInfo 等）须更小切片 + kill-switch；炸后**先恢复 Data/Root 绿基线**再继续
- FW-AM / FW-WM-2：**escalate**，不在脏 Data 上继续叠 port
- Phase 2 **未关门**：frameworks 缺口仍约 **55** 文件；下一组待 Layer2 7/7 恢复后选非热路径（如 G8 HAL / FW-PM 外科）

## 2026-07-22 (cont.25) — ✅✅ Win Layer2 7/7 基线恢复（Root `eb309e6c` + Data `wipe20260717`）

承 cont.24（绿 Root 亦掉 4/7，疑 Data 污染）。按 summary「下一步」换首选备用 Data。

**操作（readback）**：
- 停 BlueStacks 进程（HD-Player/BstkSVC/BstkVMMgr count=0）。
- 备份当前污染 Data → `Data.vhdx.bak.before-wipe20260717-20260722-111338`（可逆）。
- `cp Data.vhdx.wipe20260717-141744 → Data.vhdx`（md5 `11d7fd1b…`，3.7G，G1 Phase1 期干净快照）。
- Root.vhd 保持 `eb309e6c`（WM-1 正式态：gralloc bake + manager@1.2 正式修 + FW-WM-1）不变。

**Layer2 readback（`g1_boot_verify.ps1` 720s）**：**7/7 PASS @118s**
system_mounted / init_second / odsign / boot_completed / activity(hcallOnActivityDisplayed) / ready([Ready]) / hide_boot(fUiHideBootProgressBar)。

**结论（证据）**：
- 118s boot 远快于 M1(~400s) / cont.24 p2wipe(1034s) → `wipe20260717` 是对的干净 Data。
- **FW-WM-1（ActivityStarter hideBlueStacksPkg + ATM getGlVersion）不是热路径回归源**——cont.23/24 的 4/7 是 Data 与失败 boot 交叉污染，非代码。基线 `eb309e6c` 本身 boot 到 launcher。
- service.cpp 无 DIAG（manager@1.2 正式修在位）经此 boot 再确认（activity/ready/hide 全绿 = hwsm 存活 = HAL 注册链通）。

**纪律落实**：后续每次失败 boot **必须先 `cp wipe20260717 → Data.vhdx` 恢复干净基线**再继续 port（Data 污染是已知陷阱，绿 Root 也会被掩盖）。

**下一步**：开 **FW-CORE-APP**（core/java 22 文件 app 框架 BST hooks，非 boot 热路径）外科移植。a13 fork-diff base = `android-13.0.0_r49`（win fork 唯一在树 release tag；旧 r83 在此 repo 不存在）。

## 2026-07-22 (cont.26) — P2 FW-CORE-APP-1：3 app-framework BST hook 外科移植（Layer1 ✅，Layer2 进行中）

承 cont.25（基线 7/7 恢复）。开 FW-CORE-APP 子系统（core/java app 框架 BST hooks，**非 boot 热路径**，app 进程）。

**依赖核查（readback，关键）**：a16 BST 基础设施基本齐全——`com/bluestacks/os/{BstHostCallManager,BstFilterAppsManager,BstUtilsManager}` + 3 aidl + `Context.BST_{HOST_CALL,FILTER_APPS,UTILS}` 常量(Context:4992/5002/5012) + `android.util.BstUtils`(含 filterHiddenServices:490/getAppNameFromPid:104) ✅。**唯一缺口** = `Instrumentation.bstReferrerHack`/`bstHandleProprietryIntents`（留 batch 2）。

**Batch 1（3 文件，纯 additive，依赖全在）**：
| 文件 | BST hook | ROB/用途 | 依赖（a16 验证在位）|
|---|---|---|---|
| AccessibilityManager | `filterHiddenServices(services, callingUid)` | 隐藏 BST accessibility 服务防 3rd-party 检测 | BstUtils.filterHiddenServices(List,int):490 |
| EditText | setText IME composing 屏蔽 | ROB-11067 | BstFilterAppsManager.getInstance():114 + isBlockEditWhenComposing:1775 |
| InputMethodService | `isBstSoftKeyboardEnabled()` 替 config return（+null fallback） | BST 软键盘开关 | BstUtilsManager.isBstSoftKeyboardEnabled:121 |

- apply：`scripts/p2_fw_coreapp1_apply.py`（精确字符串替换，抗行号漂移；落地后 git diff 存档）。
- patch 存档：`patches/android-16/patches/p2-framework-rest/P2-FW-CORE-APP-1.diff`（79 行，git 格式，A16DBG:P2:FW-CORE-APP 打点）。
- **Layer1 `m framework` rc=0**（12:04，31:01 build；源码编译通过，metalava 无 UnflaggedApi——纯方法调用无新 public API）。
- **关键学习**：`m framework` 只产 `framework_intermediates/javalib.jar`（.class），**不**做 dexpreopt+install 到 `system/framework/framework.jar`（dex）。故 framework.jar 改动须 `m droid`（dexpreopt+fold+systemimage）。--pack-only 仅适用 apk/config 类不改编译产物的变更。
- **Layer2 进行中**：m droid（g1_build.sh，缓存热，~30-60min）→ pack → deploy → boot_verify。基线 `eb309e6c`+`wipe20260717` 已 7/7；本批为 app 进程 hook（非 system_server），不改 boot 路径，预期 7/7。

**Batch 2（已备，待 batch 1 Layer2 绿后 apply）**：Instrumentation（+bstReferrerHack/bstHandleProprietryIntents 2 方法 + 4 常量 + imports）+ ContextImpl（cred storage bluestacks 白名单 + startActivityAsUser 接 bst hook，含 a16 `collectExtraIntentKeys`/`applyLaunchDisplayIfNeeded` 适配）。

## 2026-07-22 (cont.27) — ✅✅ FW-CORE-APP-1 Layer2 7/7 @124s（3 app-framework hook 完整验证）

承 cont.26（Layer1 rc=0）。完成全验证回环。

**m droid**：rc=0（g1_build.sh，缓存热）；framework.jar 更新 @12:27（dex，含 3 改动，+308 bytes）；system.img md5 `3089bef9`；vndservicemanager folded ✓。

**Pack**：stage（rsync OUT，带新 framework.jar）→ g1_copy_bst_apks（gralloc safety net + launcher）→ r228 create_vdi pack。Root.vhd md5 **`6f6575a14e7e8ac395239078a33c080d`**（UUID 54e9ad31 ✓），system.sfs `fb7d56fd`。

**Deploy + Layer2（readback）**：
- win：停 BlueStacks；备份 eb309e6c → `Root.vhd.bak.eb309e6c-20260722-132101`；scp 新 Root md5 一致；Data 重置 wipe20260717（干净基线）。
- **`g1_boot_verify.ps1` 720s → 7/7 PASS @124s**：system_mounted/init_second/odsign/boot_completed/activity(hcallOnActivityDisplayed)/ready([Ready])/hide_boot(fUiHideBootProgressBar)。
- 首启 **124s**（非预期 ~400s）→ framework.jar 增量极小（3 个 additive hook），ART 未触发全量 dalvik 重生。

**结论（证据）**：FW-CORE-APP-1（AccessibilityManager filterHiddenServices + EditText ROB-11067 IME composing + InputMethodService BstSoftKeyboard）**ported**。app 进程 hook 不改 boot 路径，Layer2 保持 7/7 绿基线。patch 存档 `patches/android-16/patches/p2-framework-rest/P2-FW-CORE-APP-1.diff`；apply 脚本 `scripts/p2_fw_coreapp1_apply.py`。

**权威 Root 更新**：`6f6575a1`（FW-CORE-APP-1，7/7 @124s，严格优于 eb309e6c）。

## 2026-07-22 (cont.28) — ✅✅ FW-CORE-APP-2 Layer2 7/7 @383s（View Roblox + ApkLiteParseUtils Pokemon 完整验证）

承 cont.27。Batch 2 = 2 个独立 app-framework hook（不依赖 Instrumentation，非 startActivity 热路径）。

**改动**：
| 文件 | BST hook | ROB/用途 |
|---|---|---|
| View.java | setSystemUiVisibility 内 SYSTEM_UI_FLAG_FULLSCREEN 变化 → com.roblox.client 发 onSetMouseAction（+hcm null check）| ROB-11421 Roblox 沉浸模式 |
| ApkLiteParseUtils.java | 解析时对特定 pkg force extractNativeLibs=true（ppid!=1/2 守卫，system_server 跳过）| ROB-15882 Pokemon 反模拟器检测 |

- apply：`scripts/p2_fw_coreapp2_apply.py`；patch 存档 `P2-FW-CORE-APP-2.diff`（100 行）。
- **m droid rc=0**（vndservicemanager folded）；henry 的 python3（14.7 天 98.6% CPU 失控进程）严重饿死 build，merge_zips 触发 "ninja may be stuck" 假警报（实为单线程慢，非卡死，按"争用搁置"等待）。
- **Pack**：Root.vhd md5 **`8a5703ac60fdce998d0d83179bcfbe43`**（UUID 54e9ad31 ✓），system.sfs 重生成 @14:35。
- **Deploy + Layer2**：win 部署 md5 一致；Data 重置 wipe20260717；**`g1_boot_verify` 7/7 @383s**。慢启（3/7@187s → 7/7@383s）= 累积 5 文件 framework.jar 改动触发 dalvik 首启重生（一次性；ApkLiteParseUtils hook 有 ppid 守卫，system_server 扫包时跳过，不拖慢 boot）。
- **commit** `050e473c`（2 文件 +50，匹配本地 patch）。

**结论**：FW-CORE-APP-2 ported。权威 Root 更新 **`8a5703ac`**（FW-WM-1 + APP-1 + APP-2，Layer2 7/7，严格优于 6f6575a1）。

**累计本日 FW-CORE-APP 进度**：5/22 core/java 文件 ported（AccessibilityManager/EditText/InputMethodService/View/ApkLiteParseUtils）。剩 17 文件（含 Instrumentation+ContextImpl batch3 foundation、ViewRootImpl/Editor/TextView/InputManager/InputDevice 等）。

## 2026-07-22 (cont.29) — FW-CORE-APP-3（Instrumentation+ContextImpl foundation）：metalava @hide 修 + 因 env 争用 deferred（已 revert 干净态）

承 cont.28。Batch 3 = Instrumentation（+bstReferrerHack/bstHandleProprietryIntents 2 public 方法 + 4 常量）+ ContextImpl（cred storage bluestacks 白名单 + startActivityAsUser bst hook）。

- apply `scripts/p2_fw_coreapp3_apply.py`（+103/- Instrumentation，+14/-2 ContextImpl）；patch 存档 `P2-FW-CORE-APP-3.diff`（161 行）。
- 依赖全验证在位：BstUtilsManager.setProperty(static)、Instrumentation.TAG/checkStartActivityResult、ContextImpl.getOuterContext/mMainThread。
- **Build 1 失败 = metalava `UnflaggedApi`**：2 个 `public` bst 方法被当新 public API。**修**：给两方法加 `/** @hide */`（同 cont.20 BstUtils 的 p2_bstutils_metalava 模式）—— a16 metalava 对新 public 方法强制 @FlaggedApi，@hide 排除即可。
- **Build 2 失败 = javac `framework-minus-apex` subcommand failed**，但**无错误信息** + soong.log `Tried to lock .lock, timed out` → 根因是 build 1 kill 时残留 soong 进程/锁 + henry python3 争用导致 javac 被 interrupt（非代码错；@hide 后 UnflaggedApi=0 已证 metalava 通过）。

**决策（纪律）**：batch 3 已 2 次失败（均非代码逻辑错：metalava→@hide 修了；javac→env 锁脏），session 极长 + henry 持续争用。**revert batch 3 回干净 commit 态**（`git checkout HEAD -- Instrumentation.java ContextImpl.java` → APP-2 `050e473c`），清残留 soong 进程 + `.lock`。远程树 + win 部署（Root `8a5703ac`）一致回到 APP-2 干净验证态。

**batch 3 续做（下次，env 干净时）**：apply 脚本（含 @hide 修复版，已存本地 `scripts/p2_fw_coreapp3_apply.py`）+ patch（`P2-FW-CORE-APP-3.diff`）就绪，1 命令重 apply + `m droid`。预期 metalava 过（@hide）+ javac 过（env 干净无锁争）。ContextImpl.startActivityAsUser 是 warm path，hook 廉价早返 + try-catch，boot 风险低。

**关键学习（@hide metalava）**：a16 frameworks/base 新增 `public` 方法 → metalava `UnflaggedApi` 编译错；解 = `/** @hide */` Javadoc。后续 port public BST API 方法（如剩余 core/java 的 public hook）须同样加 @hide。

## 2026-07-22 (cont.30) — ✅✅ FW-CORE-APP-3 Layer2 7/7 @534s（Instrumentation+ContextImpl foundation 完整验证；cont.29 deferred 转 done）

承 cont.29（batch 3 因 env 锁脏 revert）。env 清干净后重 apply（@hide-fixed `scripts/p2_fw_coreapp3_apply.py`）+ m droid。

- **m droid rc=0**：javac ✓ + **metalava ✓**（@hide 排除 public bst 方法的 UnflaggedApi，证实 cont.29 的 @hide 修复正确）+ dexpreopt ✓。证实 cont.29 的 javac 失败确是 kill 残留锁/env 争用，非代码错。
- **Pack**：Root.vhd md5 **`dc4d26539d285d7d8bd623e6a82b9939`**（system.sfs 重生成 @16:46）。
- **Deploy + Layer2**：win 部署 md5 一致（备份 APP-2 8a5703ac）；Data 重置 wipe20260717；**`g1_boot_verify` 7/7 @534s**。慢启（3/7@256s→7/7@534s）= 7 累积文件 framework.jar 的 dalvik 首启重生。
- **startActivity hook 未破坏 activity 启动**：ContextImpl.startActivityAsUser 的 bst hook（bstReferrerHack 早返 + try-catch + checkStartActivityResult）boot 到 launcher，activity/ready/hide 全绿。
- **commit** `23fe7f0d`（Instrumentation +105 / ContextImpl +14-2，匹配 patch）。

**结论**：FW-CORE-APP-3 ported（foundation）。权威 Root 更新 **`dc4d2653`**（FW-WM-1 + APP-1/2/3）。

**累计 FW-CORE-APP 进度**：**7/22** core/java ported + Layer2 7/7 验证：
| 批 | 文件 | commit |
|---|---|---|
| APP-1 | AccessibilityManager / EditText / InputMethodService | c4e34c7f |
| APP-2 | View / ApkLiteParseUtils | 050e473c |
| APP-3 | Instrumentation / ContextImpl (foundation) | 23fe7f0d |

剩 13 core/java（Editor/TextView/InputManager/Environment/Settings/SharedPreferencesImpl/BaseBundle/ResourcesImpl/Display/PaymentRedirectProxyActivity/NativeLibraryHelper/Activity/ActivityThread）+ PM/INPUT/SYSUI 子系统（services/core）。

## 2026-07-22 (cont.31) — ✅✅ FW-CORE-APP-4 Layer2 7/7 @597s（ViewRootImpl FreeFireMax + InputDevice 反检测）

承 cont.30（7/22 core/java，Root `dc4d2653`）。Batch 4 = 2 个 app-process hook（非 system_server 热路径）。

**改动**：
| 文件 | BST hook | ROB/用途 |
|---|---|---|
| ViewRootImpl.java | Space/C 键 60ms 自动 release（FreeFireMax 射击）| ROB-16938 |
| InputDevice.java | getName() 隐藏 BlueStacks/VirtualBox/keyboard/mouse 设备名 | 反模拟器检测 |

- apply：`scripts/p2_fw_coreapp4_apply.py`；patch 存档 `P2-FW-CORE-APP-4.diff`（133 行）。
- **Layer1 `m droid` rc=0**（18:02，缓存热）；framework.jar dexpreopt ✓。
- **Pack**：Root.vhd md5 **`4ba4bdd3`**（UUID 54e9ad31 ✓），system.sfs @18:19。
- **Deploy + Layer2**：win 部署 md5 一致；Data 重置 wipe20260717；**`g1_boot_verify` 7/7 @597s**（dalvik 首启重生，3/7@197s→7/7@597s）。
- **commit** `51a7e751`（ViewRootImpl +27 / InputDevice +52）。

**结论**：FW-CORE-APP-4 ported。权威 Root 更新 **`4ba4bdd3`**（FW-WM-1 + APP-1/2/3/4）。

**累计 FW-CORE-APP 进度**：**9/22** core/java ported + Layer2 7/7：
| 批 | 文件 | commit |
|---|---|---|
| APP-4 | ViewRootImpl / InputDevice | 51a7e751 |

**下一步**：APP-5（Settings 反检测 + Environment sdcard_emul 外科）；禁 Data_orig（用 `g1_reset_data_wipe.ps1`）。

## 2026-07-22 (cont.32) — ✅✅ FW-CORE-APP-5 Layer2 7/7 @154s（Settings 反检测 + Environment sdcard_emul）

承 cont.31（9/22 core/java，Root `4ba4bdd3`）。Batch 5 = Settings + Environment（app 进程，非 system_server 热路径）。

**改动**：
| 文件 | BST hook | 用途 |
|---|---|---|
| Settings.java | putString 拦截 brightness/timeout；getString 伪造 mock location/adb/webview | Niantic/NetEase/Gundam 反检测 |
| Environment.java | sdcard_emul 路径重定向 + obb symlink + storage state 映射 | cases 14080/12660, BS4-2783 |

- apply：`scripts/p2_fw_coreapp5_apply.py`；patch 存档 `P2-FW-CORE-APP-5.diff`。
- **Layer1 `m droid` rc=0**（~19:16，henry 争用导致 ninja 假 stuck，等待完成）。
- **Pack**：Root.vhd md5 **`98249bf6`**（UUID 54e9ad31 ✓），@20:31。
- **Deploy + Layer2**：Data 重置 wipe20260717；**`g1_boot_verify` 7/7 @154s**。
- **commit** `c403968b`（Settings +46 / Environment +71）。

**结论**：FW-CORE-APP-5 ported。权威 Root 更新 **`98249bf6`**。

**累计 FW-CORE-APP 进度**：**11/22** core/java ported + Layer2 7/7：
| 批 | 文件 | commit |
|---|---|---|
| APP-5 | Settings / Environment | c403968b |

剩 9 core/java（InputManager/BaseBundle/ResourcesImpl/Display/…）+ services/core 热路径。

## 2026-07-22 (cont.33) — ✅✅ FW-CORE-APP-6 Layer2 7/7 @216s（Editor cursor + TextView GIAP）

承 cont.32（11/22，Root `98249bf6`）。Batch 6 = Editor + TextView（app 进程）。

**改动**：
| 文件 | BST hook | 用途 |
|---|---|---|
| Editor.java | bstSendCursorLocation → BstHostCallManager.onCursorLocationChanged | text_mode 光标同步 host |
| TextView.java | performGoogleIAPHack in setText | Google IAP 文本捕获 → BstCommandProcessor |

- apply：`scripts/p2_fw_coreapp6_apply.py`；patch `P2-FW-CORE-APP-6.diff`。
- **Build 1 失败**：TextView 缺 `import android.os.SystemProperties` → 修 apply + sed 补 import。
- **Build 2 失败**：重试 bash 未设 OUT_DIR → 用权威 `p2_fw_coreapp6_build_pack.sh` 重跑。
- **Layer1 `m droid` rc=0**（49:20）；**Pack** Root **`437704b9`** @22:06。
- **Layer2 7/7 @216s**。
- **commit** `016957467`（Editor +96 / TextView GIAP）。

**权威 Root 更新**：**`437704b9`**（FW-WM-1 + APP-1..6）。

**累计**：**13/22** core/java ported。

**下一步**：APP-7（InputMethodManager.setBstIME + InputManager 等）。

## 2026-07-22 (cont.34) — ❌ FW-CORE-APP-7 Display 回滚（Layer2 3/7）；绿基线恢复

**目标**：Display.java custom DPI + rotation override + metrics（a13 fork-diff）。

**结果**：
- apply + Layer1 ✅；Pack Root `b924f830`。
- **Layer2 3/7 @786s FAIL**（仅 system_mounted/init_second/odsign；boot_completed/activity/ready/hide_boot 未达）。
- **纪律**：`git checkout HEAD -- Display.java` 回滚；**未 commit**。
- **repack 陷阱**：同树重 pack 得 Root `ee078762`，Layer2 **3/7**（keystore2 await_boot_completed 超时、UPDATABLE_CRASHING）——**不可作权威 Root**。
- **绿基线恢复**：Win 还原 `Root.vhd.bak.20260722-2247`（md5 **`437704b9`**）+ Data wipe → **Layer2 7/7 @445s** ✅。

**结论**：Display `getRotation()` hook 为 **warm/hot path**，整批 landing 致 boot 回归；后续须 **分片**（metrics-only 先行，rotation 加 `persist.bst.*` kill-switch）或 escalate。

## 2026-07-22 (cont.35) — FW-CORE-APP-8 进行中（PaymentRedirect IAP + ActivityThread redirect）

**目标**（app 进程 warm path，非 system_server boot 热路径）：
| 文件 | BST hook |
|---|---|
| PaymentRedirectProxyActivity.java | 新文件：Google Play IAP → billing interceptor chooser |
| ActivityThread.java | EXECUTE_TRANSACTION：ProxyBillingActivity → PaymentRedirectProxyActivity |

- apply：`scripts/p2_fw_coreapp8_apply.py`（a16 用 public `ClientTransaction.getCallbacks()`，无需反射 getCallbacks）。
- build/pack：`scripts/p2_fw_coreapp8_build_pack.sh`（远程进行中）。
- **前置**：权威 Root 仍 **`437704b9`**（APP-1..6）；APP-8 须 Layer2 7/7 后才更新权威 Root/commit。

**剩 core/java**：~8 文件（Display 分片、InputManager、ResourcesImpl、SharedPreferencesImpl、Activity、ActivityThread 余量、NativeLibraryHelper、BaseBundle 等）+ services/core。

## 2026-07-23 (cont.35 done) — ✅✅ FW-CORE-APP-8 Layer2 7/7 @274s（PaymentRedirect IAP）

- **Build 1 失败**：`bstRedirectProxyBillingIfNeeded` 误标 `static` → `getSystemContext()` 编译错；修 apply 重跑。
- **Layer1 `m droid` rc=0**；Pack Root **`89b24cb8`** @01:14。
- **Layer2 7/7 @274s**（Data wipe + deploy readback）。
- **commit** `5904acd60698`；patch `P2-FW-CORE-APP-8.diff`（93 行）。
- **权威 Root 更新**：**`89b24cb8`**（FW-WM-1 + APP-1..8）。

**累计**：**14/22** core/java（+PaymentRedirectProxyActivity；ActivityThread IAP 分片；ActivityThread 余量 UE/profile/StrictMode 仍 open）。

**下一步**：InputManager（ROB-18338 分片，defer bstReloadPointerIcon 直至 IMS 侧）；Display metrics-only；ResourcesImpl/SharedPreferencesImpl。

## 2026-07-23 (cont.36) — ✅✅ FW-CORE-APP-9 Layer2 7/7 @209s（InputManagerGlobal ROB-18338）

**目标**：a13 `InputManager.getInputDeviceIds` nativeMouse 过滤 → a16 下沉至 **`InputManagerGlobal.getInputDeviceIds()`**（a16 架构变更）。

**改动**：
- `InputManagerGlobal.java`：仅对 `com.netease.yyslshmt` 过滤 vendor 0x1234/product 0x5678 虚拟鼠标（ROB-18338）。
- **刻意 defer**：`bstReloadPointerIcon()`（a16 无 `IInputManager` IMS hook）。

**Build 1 失败**：误用 `DEBUG` 常量（a16 为 `debug()` 方法）→ 修 apply 重跑。
- **Layer1 `m droid` rc=0**；Pack Root **`58b51c5a`** @01:50。
- **Layer2 7/7 @209s**。
- **commit** `5a148026ec6b`；patch `P2-FW-CORE-APP-9.diff`。

**权威 Root 更新**：**`58b51c5a`**（FW-WM-1 + APP-1..9）。

**累计**：**15/22** core/java。

**下一步**：Display metrics-only 分片；ResourcesImpl / SharedPreferencesImpl；ActivityThread 余量。

## 2026-07-23 (cont.37) — ✅✅ FW-CORE-APP-10 Layer2 7/7 @269s（Display metrics-only）

**背景**：APP-7 整批 Display（含 `getRotation`）Layer2 **3/7** 已回滚；本批仅 landing **metrics 分片**。

**改动**（`Display.java`，**无 getRotation**）：
- `getCustomDpi()` + `bstApplyCustomDpiToMetrics` / `bstApplyXYDpiOverride`
- hook：`getDisplayInfo`（logicalDensityDpi）、`getMetrics`、`getRealMetrics`
- **defer**：rotation override（须 `persist.bst.*` kill-switch 单独批）

- apply：`scripts/p2_fw_coreapp10_apply.py`；patch `P2-FW-CORE-APP-10.diff`。
- **Layer1 rc=0**；Pack Root **`e605452e`** @02:18。
- **Layer2 7/7 @269s** ✅（证实 boot 回归来自 rotation hook，非 metrics）。
- **commit** `602f111899e6`。

**权威 Root 更新**：**`e605452e`**（APP-1..6,8..10）。

**累计**：**16/22** core/java（Display 部分；rotation open）。

**下一步**：ResourcesImpl / SharedPreferencesImpl 外科分片；Display rotation kill-switch 批（escalate 若需 WM 契约）。

## 2026-07-23 (cont.38) — ✅✅ FW-CORE-APP-11 Layer2 7/7 @242s（ResourcesImpl custom DPI + status_bar）

**改动**（`ResourcesImpl.java`，app 进程 warm path）：
- `getCustomDpi()` + `getDisplayMetrics()` density/xydpi override
- `getConfiguration()` fake config（custom DPI）
- `getIdentifier()`：`bst.enable_statusbar=0` 时 `status_bar_height` → `bst_system_bar_height`（0dip）

- apply：`scripts/p2_fw_coreapp11_apply.py`；patch `P2-FW-CORE-APP-11.diff`。
- **Layer1 rc=0**；Pack Root **`6659c7f6`** @02:49。
- **Layer2 7/7 @242s**。
- **commit** `3df5e344d221`。

**权威 Root 更新**：**`6659c7f6`**。

**累计**：**17/22** core/java。

**下一步**：SharedPreferencesImpl；Activity GIAP 分片；Display rotation defer。

## 2026-07-23 (cont.39) — ✅✅ FW-CORE-APP-12 Layer2 7/7 @302s（SharedPreferencesImpl game defaults）

**改动**（`SharedPreferencesImpl.java`，app warm path；gate `sys.boot_completed=1`）：
- `setBstGameDefaultSetting()` — config.db 注入 SP 默认值（ROB-8737）
- Martial egame / Dungeon Hunter 补丁（ROB-11560/11613）
- hook：`getString/getInt/getLong/getFloat/getBoolean/contains`

- apply：`scripts/p2_fw_coreapp12_apply.py`；patch `P2-FW-CORE-APP-12.diff`。
- **Layer1 rc=0**；Pack Root **`91302526`** @03:19。
- **Layer2 7/7 @302s**。
- **commit** `6f25dc7bf8ba`。

**权威 Root 更新**：**`91302526`**。

**累计**：**18/22** core/java。

**下一步**：Activity GIAP 分片；NativeLibraryHelper；BaseBundle；Display rotation defer。

## 2026-07-23 (cont.40) — ✅✅ FW-CORE-APP-13 Layer2 7/7 @126s（Activity GIAP purchase tracking）

**改动**（`Activity.java`，GIAP-only 分片；defer `setVolumeForInstagram`/native-lib AlertDialog）：
- 常量/字段：`TAG_BST_IAP`、`DEBUG_BST_IAP`、GIAP billing response 常量
- 方法：`sendPurchaseDataToCommandProcessor`、`performGoogleIAPHack`、`getGIAPResponseDesc`、`getGIAPResponseCodeFromIntent`
- hook：`internalDispatchActivityResult` 入口（a16 拆分路径；a13 在 `dispatchActivityResult`）

- apply：`scripts/p2_fw_coreapp13_apply.py`；patch `P2-FW-CORE-APP-13.diff`。
- **Layer1 rc=0**；Pack Root **`fd879d32`** @03:54。
- **Layer2**：冷启 6/7 @630s（`hide_boot` oracle 漏检——`fUiHideBootProgressBar` 已写入 `Player.log.1` 轮转文件）；warm 复验 **7/7 @126s**。
- **commit** `a8e3056b58da`。

**权威 Root 更新**：**`fd879d32`**。

**累计**：**19/22** core/java。

**下一步**：NativeLibraryHelper 分片；BaseBundle 分片；Display rotation defer（需 kill-switch）。

## 2026-07-23 (cont.41) — ✅✅ FW-CORE-APP-14 Layer2 7/7 @376s（NativeLibraryHelper BST ABI override）

**改动**（`NativeLibraryHelper.java`，a13 ABI 强制安装 / Unity / il2cpp / ARM marker）：
- `Handle` 增 `pkgName`/`apkDir`；`getBstAbiOverride` / `findSupportedAbi` wrapper / `copyNativeBinariesForSupportedAbi` wrapper
- `updateIl2cpp` / `createArmMarker` / `isAppHavingUnityLibs` / `isAppHavingXArmLibs`

- apply：`scripts/p2_fw_coreapp14_apply.py`（a13 切片 + a16 锚点）；patch `P2-FW-CORE-APP-14.diff`。
- **Layer1 rc=0**；Pack Root **`62b6e6c9`** @05:44。
- **Layer2 7/7 @376s**（Data wipe 冷启）。
- **commit** `1f595ce4a8d1`。

**权威 Root 更新**：**`62b6e6c9`**。

**累计**：**20/22** core/java。

**下一步**：BaseBundle affiliate hack；Display rotation defer；ActivityThread 余量。

## 2026-07-23 (cont.42) — ✅✅ FW-CORE-APP-15 Layer2 7/7 @401s（BaseBundle affiliate/referral hack）

**改动**（`BaseBundle.java`，Google Play referral API affiliate）：
- 静态 maps/paths；`bstAffiliateHack` / `sendOtherReferrerStat` / `bstSendStatToCloud`
- hook：`getString` / `getLong`（timestamp referrer 字段）

- apply：`scripts/p2_fw_coreapp15_apply.py`（a13 切片）；patch `P2-FW-CORE-APP-15.diff`。
- **Layer1 rc=0**；Pack Root **`40866955`** @09:51。
- **Layer2 7/7 @401s**。
- **commit** `0c32c6272c80`。

**权威 Root 更新**：**`40866955`**。

**累计**：**21/22** core/java。

**下一步**：Display rotation（defer，需 kill-switch）；ActivityThread 余量；services/core 子系统。

## 2026-07-23 (cont.43) — ✅✅ FW-CORE-APP-16 Layer2 7/7 @247s（ActivityThread profile/UE/StrictMode）

**改动**（`ActivityThread.java`，app warm path）：
- `getDefaultProfile` → 默认 profile 文件 bootstrap
- `processUEHighFPS` + Unreal/UE4 HighFPS 循环（`bst.enable_high_fps` / `bst.max_fps` gate）
- StrictMode finally：`com.bluestacks.*` 包豁免（a13）

- apply：`scripts/p2_fw_coreapp16_apply.py`；patch `P2-FW-CORE-APP-16.diff`。
- **Layer1 rc=0**（Build1 失败：`bfam` 重复定义 → 修 apply）；Pack Root **`20a10972`** @11:11。
- **Layer2 7/7 @247s**。
- **commit** `f473449bce8d`。

**权威 Root 更新**：**`20a10972`**（ActivityThread 余量除 APP-8 IAP 外已齐）。

**累计**：**21/22** core/java（Display rotation 仍 open，APP-17 进行中）。

**下一步**：APP-17 Display rotation kill-switch；services/core。

## 2026-07-23 (cont.44) — ✅✅ FW-CORE-APP-17 Layer2 7/7 @421s（Display rotation kill-switch）→ **core/java 22/22 完成**

**改动**（`Display.java`，rotation-only；`bst.enable_display_rotation=0` 默认 off）：
- 字段：`mLastPkg` / `mModifyDisplayRotation` / `mFixedSurfaceRotation`
- `getRotation()` hook：`BstFilterAppsService` 查询 + 固定 rotation 覆盖
- **kill-switch**：property `bst.enable_display_rotation=0`（默认）→ 行为与 APP-10 绿基线一致

- apply：`scripts/p2_fw_coreapp17_apply.py`；patch `P2-FW-CORE-APP-17.diff`。
- **Layer1 rc=0**；Pack Root **`4bf3f4ad`** @11:46。
- **Layer2 7/7 @421s**（kill-switch 默认 off 冷启）。
- **commit** `e71e3ebf0e74`。

**权威 Root 更新**：**`4bf3f4ad`**。

**累计**：**22/22** core/java ✅（FW-CORE-APP 子系统关门）。

**下一步**：**P2-FW-SERVICES-CORE**（system_server 热路径 ~25 文件）；rotation 功能验证需 `bst.enable_display_rotation=1` 单独 Layer2。

## 2026-07-23 (cont.45) — FW-SERVICES-1a ✅ Layer2 7/7 @167s（Clipboard host sync）

**背景**：合并 batch SERVICES-1（Clipboard+Location）Layer2 报 **3/7** → 纪律 revert 源码；根因 **非代码回归**——冷启 ~669s 才 `boot_completed`，oracle 只扫 `Player.log`（轮转后为空），且 600s 超时偏紧。修复 `g1_boot_verify.ps1` 增扫 `Player.log.1`；绿基线 **4bf3f4ad** 复验 **7/7 @462s**。

**改动**（`ClipboardService.java`，lazy-init `BstHostCallManager`）：
- `setPrimaryClipInternalLocked` → `setClipboardText` host 同步（a13；跳过 label `simpleText`）

- apply：`scripts/p2_fw_services1a_apply.py`；patch `P2-FW-SERVICES-1a.diff`。
- **Layer1 rc=0**；Pack Root **`eeb4f714`** @13:31。
- **Layer2 7/7 @167s**（Data wipe + 900s timeout + log.1 scan）。
- **commit** `2ffca2cd5c5c`。

**权威 Root 更新**：**`eeb4f714`**（FW-SERVICES-1a）。

**累计**：services/core **1/21** gap（+ WM-1 已有 3 文件 = 4/24 a13 BST 文件）。

**下一步**：FW-SERVICES-1b Location GMS popup；余 19 services/core 文件。

## 2026-07-23 (cont.46) — ✅ FW-SERVICES-1b Layer2 7/7 @235s（Location GMS network popup）

**改动**（`LocationManagerService.java` LocalService）：
- `isProviderEnabledForUser("network")` → GMS 包名前缀检测 + network provider 未启用时返回 false（a13 禁 accuracy popup）

- apply：`scripts/p2_fw_services1b_apply.py`；patch `P2-FW-SERVICES-1b.diff`。
- **Layer1 rc=0**；Pack Root **`21907055`** @13:58（叠 1a Clipboard）。
- **Layer2 7/7 @235s**。
- **commit** `ba68bbbe5fba`。

**结论**：合并 batch SERVICES-1 原 **3/7** 为 oracle 漏读（`Player.log.1`），非 Location/Clipboard 回归。1a+1b 分 batch 均绿。

**权威 Root 更新**：**`21907055`**。

**累计**：services/core **2/21** gap（Clipboard + Location）。

**下一步**：FW-SERVICES-2 下一 surgical batch（IntentResolver / AccountManager / Notification 等 peripheral 优先）。

## 2026-07-23 (cont.47) — ✅ FW-SERVICES-2 Layer2 7/7 @184s（NMS + hide BST resolve）

**背景**：合并 batch SERVICES-2 初报 **3/7 @905s** → bisect：绿基线 **21907055** 复验 **7/7 @225s**；**2b NMS** 单独 **7/7 @386s**；**2a+2b** 复验 **7/7 @184s**。结论：合并 batch 失败为冷启环境 flake（VM 未停/Data 锁），非 2a 代码回归。

**改动**：
- **2b** `NotificationManagerService.java` — `sendNotificationToHost` → host 通知 JSON（a13）
- **2a** `IntentResolver.java` — `isBluestacksFilter` hook + `ComponentResolver` override（hideBlueStacksPkg / FilterApps）

- apply：`p2_fw_services2b_apply.py` + `p2_fw_services2a_apply.py`
- **Layer1 rc=0**；Pack Root **`cf6bf294`** @16:04
- **Layer2 7/7 @184s**（2a+2b 叠 1a+1b）
- **commit** `4617ec3a455c`（2b）+ `79c5e53667c8`（2a）

**权威 Root 更新**：**`cf6bf294`**

**累计**：services/core **4/21** gap（Clipboard、Location、NMS、ComponentResolver；IntentResolver 为 plumbing hook）

**下一步**：FW-SERVICES-3 AccountManagerService；余 PM/AM/WM 热路径。

## 2026-07-23 (cont.48) — ✅ FW-SERVICES-3 Layer2 7/7 @169s（AccountManager host 账户回调）

**改动**（`AccountManagerService.java`，lazy-init `BstHostCallManager`）：
- Google/now.gg 账户 add/remove → `googleAccountListUpdated` / `onNowggAccountRemoved`
- Google 首次登录 → `bst.bluestacks_account_id` + `onGoogleLoginCompleted`
- `setGoogleAdId()` → `BstCommandProcessor`（账户变更广播路径）

- apply：`scripts/p2_fw_services3_apply.py`；patch `P2-FW-SERVICES-3.diff`
- **Layer1 rc=0**；Pack Root **`3d3a7997`** @16:36
- **Layer2 7/7 @169s**
- **commit** `e769b6edef84`

**权威 Root 更新**：**`3d3a7997`**

**累计**：services/core **5/21** gap

**下一步**：FW-SERVICES-4 peripheral（AudioService / AppOpsService / RecentsAnimationController）；热路径 AM/PM/WM 谨慎 slice。

## 2026-07-23 (cont.49) — ✅ FW-SERVICES-4a Layer2 7/7 @199s（Audio volume + AppOps devicedetails）

**改动**：
- `AudioService.java` — `bstSendVolumeToHost(index)` on `STREAM_MUSIC` volume change → `BstHostCallManager.onVolumeChanged`
- `AppOpsService.java` — `checkPackage` allow `com.bluestacks.devicedetails`（a13 synthetic package）

- apply：`scripts/p2_fw_services4a_apply.py`；patch `P2-FW-SERVICES-4a.diff`
- **Layer1 rc=0**；Pack Root **`a551d823`** @17:10
- **Layer2 7/7 @199s**（Data `wipe20260717`）
- **commit** `41faf7a01ee4`

**RecentsAnimationController**：a16 已 refactor（无 `services/core/.../RecentsAnimationController.java`）；orientation hook 待单独 research batch，**defer**。

**权威 Root 更新**：**`a551d823`**

**累计**：services/core **7/21** gap（+ Audio、AppOps）

**下一步**：FW-SERVICES-5 peripheral（InputMethod / InputManager 等）；Recents orientation escalate；热路径 AM/PM 谨慎 slice。

## 2026-07-23 (cont.50) — ✅ FW-SERVICES-5 Layer2 7/7 @153s（AccessibilityManagerService hide BST a11y）

承 cont.49（services/core 7/21）。FW-SERVICES-5 = AccessibilityManagerService（peripheral，query-time 过滤，非 boot 路径）。

**改动**（`AccessibilityManagerService.java`，2 个 filterHiddenServices hook，同 APP-1 app-side 模式）：
- `getInstalledAccessibilityServiceList`：mInstalledServices → filterHiddenServices
- `getEnabledAccessibilityServiceList`：result 去 final + 循环后 filterHiddenServices（隐藏 BST accessibility 服务防 3rd-party 检测）

- apply：`scripts/p2_fw_services5_apply.py`；patch `P2-FW-SERVICES-5.diff`。
- **m droid rc=0**（vndservicemanager folded）；**Pack Root `661c0d40186b5cb0ba36e894f7b209c3`** @18:29。
- **Deploy + Layer2**：win 部署 md5 一致（备份 a551d823）；Data 重置 wipe20260717；**7/7 @153s**（冷启快，query-time hook 不影响 boot）。
- **commit** `89f7d26202ab`（+9/-3）。

**权威 Root 更新**：**`661c0d40`**（FW-SERVICES-5，严格优于 a551d823）。

**累计**：services/core **8/21** gap（+ AccessibilityManagerService）。

**下一步**：InputManagerService（构造函数签名变更，须改 caller，较复杂）/ InputMethodManagerService（100 行 peripheral）/ 余 PM族·AM·WM 热路径。

## 2026-07-23 (cont.51) — ✅✅ FW-PERIPH-1 Layer2 7/7 @131s（SystemVibrator + MediaCodecInfo）

承 cont.50。fresh gap（31 文件）分析后选 2 个干净 peripheral app-framework 文件（非 services/core 热路径）。其他候选 drift/资源缺 defer：WallpaperManager（缺 `default_wallpaper_msi` 资源）、PointerIcon（TYPE_NULL 块 a16 重排）、InputManager（netease 过滤逻辑移 InputManagerGlobal）。

**改动**：
| 文件 | BST hook | 用途 |
|---|---|---|
| SystemVibrator | `hasVibrator() \|\| bst_enable_vibrator`（+field）| 永远报告有振动器（游戏检测）|
| MediaCodecInfo | ROB-10676 whatsapp 下 `OMX.google.h264.encoder`→`c2.android.avc.encoder` | 绕 whatsapp 编码器限制发视频 |

- apply：`scripts/p2_fw_periph1_apply.py`；patch `P2-FW-PERIPH-1.diff`。
- **Build1 失败**：SystemVibrator field 插在 `@Override` 与 `hasVibrator()` 之间 → `@Override` 错附 field（annotation not applicable）。**修**：anchor 含 `@Override\n` 保持其附着方法。
- **m droid rc=0**；**Pack Root `34b3cd8a32c8c284e7eb27bc8b3cd506`** @19:18。
- **Deploy + Layer2**：win 部署 md5 一致（备份 661c0d40）；Data 重置 wipe20260717；**7/7 @131s**。
- **commit** `7c1801fb5818`（+11/-1）。

**权威 Root 更新**：**`34b3cd8a`**（FW-PERIPH-1，严格优于 661c0d40）。

**累计**：services/core 8/21 + 2 extra peripheral core/java（SystemVibrator/MediaCodecInfo，原 22 外的新发现）。

**下一步**：SettingsProvider（a11y setting 过滤，补 AccessibilityManagerService）；InputMethodManagerService（100 行 peripheral，新方法）；热路径 PM/AM/WM 谨慎 slice。

## 2026-07-23 (cont.52) — ✅✅ FW-PERIPH-2 Layer2 7/7 @123s（TelephonyPermissions phone-state bypass）

**改动**（`TelephonyPermissions.java`，2 个 permission bypass，query-time 门控，非 boot 路径）：
- `checkReadPhoneState`(7-arg)：bypass READ_PRIVILEGED_PHONE_STATE 给 `com.gamamobi.wog`
- 设备标识检查：bypass 给 `com.bluestacks.devicedetails`（自动化测试）

- apply：`scripts/p2_fw_periph2_apply.py`；patch `P2-FW-PERIPH-2.diff`。
- 锚点唯一性：hook1 用 7-arg 签名+try+enforcePermission（enforcePermission ×2 中选 7-arg）；hook2 用 allowCarrierPrivilegeOnAnySub 块+LegacyPermissionManager（×2 中选 device-id 方法）。
- **m droid rc=0**；**Pack Root `c52f1236b9ea79f383577d7906b710e2`** @19:51。
- **Deploy + Layer2**：win 部署 md5 一致（备份 34b3cd8a）；Data 重置 wipe20260717；**7/7 @123s**。
- **commit** `<remote>`（+7）。

**权威 Root 更新**：**`c52f1236`**（FW-PERIPH-2，严格优于 34b3cd8a）。

**累计**：services/core 8/21 + 3 extra peripheral（SystemVibrator/MediaCodecInfo/TelephonyPermissions）。

**下一步**：InputMethodManagerService（100 行 peripheral，IME/text-edit-mode host 同步）；TunerServiceImpl（statusbar icon hide）；热路径 PM/AM/WM 谨慎 slice。

## 2026-07-23 (cont.53) — ✅✅ FW-SERVICES-6 Layer2 7/7 @131s（IMMS onImeChange bounded 子集）

承 cont.52。a16 IMMS 重构深（`bindingController` 抽象 + Lifecycle + deviceId），全 12 hunk a13 port 需 dedicated 逐 hunk 适配。本批做 **bounded 功能子集**：onImeChange host 通知（host 得知 active IME 切换，供键盘映射）。

**改动**（`InputMethodManagerService.java`，lazy-init BstHostCallManager 模式，同 cont.45/48）：
- field `mBstHostCallManagerService`（lazy-init，避开重构的构造 init 锚）
- `setInputMethodLocked`「Changing IME」分支：broadcast 后 lazy-init + `onImeChange(id)`

- apply：`scripts/p2_fw_services6_apply.py`；patch `P2-FW-SERVICES-6.diff`（37 行）。
- 依赖全验证在位（onImeChange/commonCommand/onTextEditModeChange/isIMEDisabled/HCALL_CC_*）。
- **m droid rc=0**；**Pack Root `43895325df3f5c53efb4cd330536227b`** @20:30。
- **Deploy + Layer2**：win 部署 md5 一致（备份 c52f1236）；Data 重置 wipe20260717；**7/7 @131s**。
- **commit** `<remote>`（+12）。

**权威 Root 更新**：**`43895325`**（FW-SERVICES-6，严格优于 c52f1236）。

**累计**：services/core 9/21 gap（+ IMMS bounded）+ 3 extra peripheral。

**IMMS 剩余（dedicated 续做）**：bstSendSetInputMapperStatusAsync（text-edit-mode/password host 同步，用 mCurAttribute + getSelectedMethodIdLocked→bindingController 适配）+ setBstIME/setBstIMEFromClient + MSG_SET_IME + show/hideCurrentInput call site + auto-show 分支。deps 全在位，需逐 hunk 适配 a16 bindingController。

## 2026-07-23 (cont.54) — ✅✅ FW-SERVICES-6b Layer2 7/7 @123s（IMMS text-edit-mode 键盘映射核心）

承 cont.53（IMMS onImeChange）。续做 IMMS text-edit-mode（键盘映射核心 host 同步）。

**改动**（`InputMethodManagerService.java`，bounded 子集，lazy-init）：
- field `bstWinKeyboardInputEnabled` + `mBstFilterAppsManager`（lazy-init）
- `bstSendSetInputMapperStatusAsync(boolean)`：isIMEDisabled 门控（禁 IME 的 app 不弹键盘）+ `onTextEditModeChange`（host 同步文本编辑模式）。
  **a16 适配**：去掉 a13 的 mCurAttribute 密码检测块（a16 IMMS 无 mCurAttribute 字段，重构）；保留 isIMEDisabled + onTextEditModeChange 核心。
- `showCurrentInputLocked` → `bstSendSetInputMapperStatusAsync(true)`；`hideCurrentInputLocked` → `(false)`

- apply：`scripts/p2_fw_services6b_apply.py`；patch `P2-FW-SERVICES-6b.diff`（75 行）。
- **m droid rc=0**；**Pack Root `74592b9f671d7d3804327c14d48b432f`** @21:03。
- **Deploy + Layer2**：win 部署 md5 一致（备份 43895325）；Data 重置 wipe20260717；**7/7 @123s**。
- **commit** `<remote>`。

**权威 Root 更新**：**`74592b9f`**（FW-SERVICES-6b，严格优于 43895325）。

**累计**：services/core 9/21 gap（IMMS 已 onImeChange + text-edit-mode 两子集，键盘映射核心功能在位）+ 3 extra peripheral。

**IMMS 剩余（dedicated，低优先）**：setBstIME/setBstIMEFromClient + MSG_SET_IME（需 IInputMethodManager aidl 加方法 + setInputMethodEnabledLocked 适配）；@4076 auto-show 分支（drift）。核心 IME 通知 + text-edit-mode 已在位。

## 2026-07-23 (cont.55) — ✅✅ FW-PERIPH-3 Layer2 7/7 @197s（TelephonyManager operator 伪装）

承 cont.54。TelephonyManager 18-hunk 大 port 的 **bounded 子集**：operator 伪装（反模拟器检测）。

**改动**（`TelephonyManager.java`，a16 锚与 a13 完全匹配）：
- field `BST_TELEPHONY_CHANGES_ENABLED=true` + `PROPERTY_OPERATOR_ALPHA/NUMERIC`
- `getNetworkOperatorName()` → `SystemProperties.get(gsm.operator.alpha, "T-Mobile")`
- `getNetworkOperator()` → `SystemProperties.get(gsm.operator.numeric, "310260")`

- apply：`scripts/p2_fw_periph3_apply.py`；patch `P2-FW-PERIPH-3.diff`（43 行）。
- **m droid rc=0**（仅无关 warning）；**Pack Root `e9003acc9cc88311c8df4ba6077fafd9`** @21:38。
- **Deploy + Layer2**：win 部署 md5 一致（备份 74592b9f）；Data 重置 wipe20260717；**7/7 @197s**。
- **commit** `<remote>`（+18/-2）。

**权威 Root 更新**：**`e9003acc`**（FW-PERIPH-3，严格优于 74592b9f）。

**累计**：services/core 9/21 + IMMS 两子集 + 4 extra peripheral（SystemVibrator/MediaCodecInfo/TelephonyPermissions/TelephonyManager-operator）。

**TM 剩余（dedicated，低优先）**：createSubInfoInstance + getDeviceId("01") + getNeighboringCellInfo + getNetworkOperatorName(subId) + 其余 ~14 hunk（device-id/IMEI/cell 反检测）。operator 伪装已在位。

## 2026-07-23 (cont.56) — ❌ FW-PERIPH-3b 回退（TM device-id "01" override 破 boot）+ 基线复验 7/7

承 cont.55。续做 TM device-id 反检测子集（getDeviceId/getDeviceSoftwareVersion early-return "01"，复用 BST_TELEPHONY_CHANGES_ENABLED）。

**结果**：Layer2 **3/7 @486s 卡死**（boot_completed 不触发，system_server 未完成 boot）→ **regression**。根因：device-id "01" 无条件 early-return 破坏 boot 期读 device-id 的系统组件（system_server/device-id 依赖服务期望 real/null，常量 "01" 下游失败）。a13 此 hook 可能 conditional 或 boot 路径不同；无条件 override 在 a16 太激进。

**纪律处置**（readback）：
- kill boot verify。
- remote `git checkout HEAD -- TelephonyManager.java`（revert PERIPH-3b → 回 PERIPH-3 commit 09ecb823 = e9003acc 态）。
- win 重部署 e9003acc backup Root.vhd + Data 重置 wipe20260717。
- **复验 e9003acc → 7/7 @175s** ✓（证实 regression 是 device-id override 代码，非环境/Data 污染）。

**结论**：PERIPH-3b（device-id "01"）**defer**。operator 伪装（PERIPH-3, e9003acc）稳固。device-id spoof 须 conditional/gated（仅特定 caller 或非 boot 期），不可无条件 early-return。

**权威 Root 保持**：**`e9003acc`**（PERIPH-3，7/7 @175s 复验）。

## 2026-07-23 (cont.57) — ✅✅ FW-PERIPH-4 Layer2 7/7 @169s（ServiceState LTE 反检测）

承 cont.56（PERIPH-3b device-id revert）。换 clean TM 反检测：ServiceState 报 LTE 网络类型。

**改动**（`ServiceState.java`，a16 锚与 a13 完全匹配，gated by `bst.config.modify_nwtype` 默认 on）：
- field `BST_CHANGES_ENABLED`（property gated）
- `getDataNetworkType()` early-return `NETWORK_TYPE_LTE`

- apply：`scripts/p2_fw_periph4_apply.py`；patch `P2-FW-PERIPH-4.diff`（25 行）。
- **m droid rc=0**；**Pack Root `1ccc2a814f2965ce176ab1f8bd32cd66`** @22:59。
- **Deploy + Layer2**：win 部署 md5 一致（备份 e9003acc）；Data 重置 wipe20260717；**7/7 @169s**。
- **commit** `<remote>`（+7）。

**权威 Root 更新**：**`1ccc2a81`**（FW-PERIPH-4，严格优于 e9003acc）。

**累计**：services/core 9/21 + IMMS 两子集 + 5 extra peripheral（SystemVibrator/MediaCodecInfo/TelephonyPermissions/TelephonyManager-operator/ServiceState-LTE）。

**TM/telephony 反检测状态**：operator 伪装（PERIPH-3）+ LTE（PERIPH-4）在位；device-id（PERIPH-3b，无条件破 boot，defer 须 conditional）；subscription（createSubInfoInstance，消费者移 SubscriptionManager，re-arch defer）。

## 2026-07-23 (cont.58) — ✅✅ FW-PERIPH-5 Layer2 7/7 @126s（TM device-id uid-gated — PERIPH-3b 教训修复）

承 cont.56（PERIPH-3b 无条件 device-id 破 boot）。重做带 **uid 守卫**：仅第三方 caller（uid>=10000）得 "01"，system_server（uid<10000）得真实 id → boot-safe。

**改动**（`TelephonyManager.java`，BST_TELEPHONY_CHANGES_ENABLED && Binder.getCallingUid()>=10000 gate）：
- `getDeviceId()` → "01"（仅第三方）
- `getDeviceSoftwareVersion(int)` → "01"（仅第三方）

- apply：`scripts/p2_fw_periph5_apply.py`；patch `P2-FW-PERIPH-5.diff`（23 行）。
- **m droid rc=0**；**Pack Root `45bf8e14f505d75393789893f964e535`** @23:34。
- **Deploy + Layer2**：win 部署 md5 一致（备份 1ccc2a81）；Data 重置 wipe20260717；**7/7 @126s** ✓。
- **commit** `<remote>`（+6）。

**结论**：device-id 反检测 **ported**（uid-gated，boot-safe）。证实 PERIPH-3b 的 regression 根因是无条件 override（system_server boot 期读 device-id 失败）；uid gate（system 得真实）解决。**telephony 反检测现在齐全**：operator(PERIPH-3) + LTE(PERIPH-4) + device-id(PERIPH-5)。

**权威 Root 更新**：**`45bf8e14`**（FW-PERIPH-5，严格优于 1ccc2a81）。

**累计**：services/core 9/21 + IMMS 两子集 + 6 extra peripheral。

## 2026-07-24 (cont.59) — 移植盘点：InputManager netease 已在 InputManagerGlobal；机械 peripheral 尽

核查 InputManager gap：a13 `InputManager.java` ROB-18338 netease 过滤，a16 移至 `InputManagerGlobal.getInputDeviceIds()`(:445) 且**已 ported**（`A16DBG:P2:FW-CORE-APP-9`，先前 session）。gap 分析的 false positive（hook 迁移+已落地）。

**机械可移植 peripheral 全部完成**（cont.50-58，9 verified）：a11y hide / vibrator / codec / telephony-perms / IMMS(onImeChange+text-edit-mode) / telephony 反检测(operator+LTE+device-id-uid-gated)。

**剩余全部 escalation/dedicated（非机械 unilateral）**：
- **services/core 热路径 boot-critical**：PackageManagerService(204行,package-scan路径) + PM族 + AM(AMS/ActiveServices) + WM(DisplayContent/ActivityTaskSupervisor)。cont.23 AM-1/WM-2 曾 revert；device-id regression 前车之鉴。**按规则 escalate（热路径/IPC 判断性）**。
- **ActivityManager.removeTaskWrapper**：跨文件 aidl 契约变更（须加 IActivityManager.aidl 方法 + AMS 实现）→ **escalate（binder 契约）**。
- **drift/dedicated**：SettingsProvider(deviceId+Setting 构造 drift)、PointerIcon(TYPE_NULL 重排)、WallpaperManager(缺 default_wallpaper_msi 资源)、SystemUI TunerServiceImpl(缺 getIconHideList deps)。
- **re-arch**：TM createSubInfoInstance（消费者移 SubscriptionManager）。
- **aidl**：IMMS setBstIME/setBstIMEFromClient + MSG_SET_IME。

权威 Root 保持 **`45bf8e14`**（9 ports，7/7）。下一步须人类判断定热路径/契约方向。

## 2026-07-24 (cont.60) — ✅✅ FW-PERIPH-6 Layer2 7/7 @126s（SettingsProvider a11y setting 过滤，drift 适配）

承 cont.59。SettingsProvider drift 适配 port（机械，非 judgment）：补 AccessibilityManagerService 的 a11y 隐藏（setting 字符串层）。

**改动**（`SettingsProvider.java`，drift 适配）：
- a16 `getSettingLocked` 加 `deviceId` 参数（a13 3-arg→a16 4-arg）
- a16 `getSettingsLocked` 3-arg(type,userId,deviceId)（a13 2-arg）
- a16 `Setting` ctor @1769 arg 顺序 (name,value,defaultValue,packageName,tag,fromSystem,id)（a13 不同，重排）
- hook：`getSecureSetting` 捕获 setting → ENABLED_ACCESSIBILITY_SERVICES 过滤 + 重建 Setting（filterHiddenServices）

- apply：`scripts/p2_fw_periph6_apply.py`；patch `P2-FW-PERIPH-6.diff`（41 行）。
- **Build1/2 失败**：getSettingsLocked 签名（2-arg→3-arg 修复）。
- **m droid rc=0**；**Pack Root `02c94d60f40668e1287e84f83755769b`** @00:37。
- **Deploy + Layer2**：win 部署 md5 一致（备份 45bf8e14）；Data 重置 wipe20260717；**7/7 @126s**。
- **commit** `<remote>`。

**权威 Root 更新**：**`02c94d60`**（FW-PERIPH-6，严格优于 45bf8e14）。

**累计**：services/core 9/21 + IMMS 两子集 + 7 extra peripheral（a11y hide 双层：service-list + setting）。

**剩余 drift**：PointerIcon(TYPE_NULL 重排)、WallpaperManager(缺 msi 资源)、SystemUI TunerServiceImpl(deps 缺)；热路径 PM/AM/WM(escalate)、ActivityManager(aidl 契约 escalate)、TM subscription(re-arch)、IMMS setBstIME(aidl)。

## 2026-07-24 (cont.61) — ✅✅ FW-PERIPH-7 Layer2 7/7 @136s（SettingsService a11y bulk-read 过滤）

补 SettingsProvider（PERIPH-6 单读）的 shell/get-command bulk-read 路径。

**改动**（`SettingsService.java`）：`MyShellCommand` get 路径 `result = b.getPairValue()` 后，对 `secure` table + ENABLED_ACCESSIBILITY_SERVICES 调 filterHiddenServices。a16 锚与 a13 匹配。

- apply：`scripts/p2_fw_periph7_apply.py`；patch `P2-FW-PERIPH-7.diff`。
- **m droid rc=0**；**Pack Root `848e9737e8cd50bd6a6bfbeb6108979f`** @01:12。
- **Deploy + Layer2**：win 部署（备份 02c94d60）；Data 重置；**7/7 @136s**。
- **commit** `<remote>`。

**权威 Root 更新**：**`848e9737`**。a11y hide 现三层（service-list SERVICES-5 + setting 单读 PERIPH-6 + bulk-read PERIPH-7）。

**累计**：services/core 9/21 + IMMS 两子集 + 8 extra peripheral。PointerIcon(defer,re-arch)、WallpaperManager(defer,resource)、SystemUI TunerServiceImpl(defer,deps) 仍缺；热路径/aidl escalate。

## 2026-07-24 (cont.62) — 终判：机械 peripheral 移植耗尽（SystemUI 截图 re-arch）

核查剩余 SystemUI 截图文件：a16 `SaveImageInBackgroundTask` 完全重构（无 `result.fileName`/`doInBackground`/`mContext`/相关 imports），a14-16 SystemUI 截图管线整体重写。`ScreenshotController` 同族重构。`onScreenshotSaved` dep 虽在 a16 BstHostCallManager(:293)，但 call site 宿主方法不存在 → **re-arch defer**。

**机械可移植 peripheral 移植彻底完成**（cont.50-61，11 verified ports + 1 reverted→fixed）。a11y hide 三层、telephony 反检测齐全、IMMS 键盘映射核心、peripheral app hooks 全在位。

**剩余全部非机械（须 escalate/re-arch/resource，按规则需人类判断或 dedicated）**：
- **re-arch**：PointerIcon(SYSTEM_ICONS 结构)、SystemUI 截图管线(SaveImageInBackgroundTask/ScreenshotController)、TM subscription(消费者移 SubscriptionManager)
- **resource**：WallpaperManager(缺 default_wallpaper_msi drawable，须加资产)
- **deps 缺**：SystemUI TunerServiceImpl(getIconHideList/ICON_HIDE_LIST/icon_black_list)
- **escalate（规则：热路径/IPC/契约 判断性）**：PM族/AM/WM boot-critical、ActivityManager(aidl 契约)、IMMS setBstIME(aidl)

权威 Root **`848e9737`**（11 ports，7/7 @136s）。机械移植阶段关门；下一步须人类定热路径/契约/re-arch 方向。

## 2026-07-24 (cont.63) — Phase 2 功能对齐维度关门 + 剩余统一 defer 挂账

**统一决策（按 escalate 清单 A/B/C/D/E 裁定）**：剩余 24 gap 文件（扣 pattern 误报 + 已 relocation 完成的 InputManager→InputManagerGlobal）全部 defer/dropped，正式挂账。理由：经逐文件 grep/diff 核查，每一项均非机械 port——a16 重构了管线（a13 hook 无直接映射）或需 binder 契约扩展或缺资产/deps，且多在 boot-critical 路径（PERIPH-3b 教训：boot 相关无条件 override 必破）。这些需 deliberate design scoping（re-arch 落点设计 + boot-risk uid-gate 方案 + aidl 契约评审 + 资产），非 unilateral 安全可完成。

**Phase 2「guest 功能对齐」关门维度（已达成）**：
- core/java **22/22** ✅
- a11y hide 三层（service-list + setting 单读 + bulk-read）✅
- telephony 反检测（operator + LTE + device-id-uid-gated）✅
- IMMS 键盘映射核心（onImeChange + text-edit-mode）✅
- peripheral app hooks（vibrator / codec / telephony-perms）✅
- services/core peripheral 9/21（Clipboard/Location/NMS/ComponentResolver/IntentResolver/AccountManager/Audio/AppOps/AccessibilityManagerService）✅

**剩余挂账（defer/dropped 清单）**：
| 组 | 项 | 裁定 | 阻塞 |
|---|---|---|---|
| A boot-critical | PM族(8)/AMS/ActiveServices/DisplayContent/ATS/RecentsAnimationController | **defer** | boot-critical scan/lifecycle；须 kill-switch design + 干净基线小切片 |
| B 契约 | ActivityManager.removeTaskWrapper / IMMS setBstIME | **defer** | aidl 加方法（契约扩展评审）|
| C re-arch | PointerIcon(SYSTEM_ICONS 反转)/SystemUI 截图(a14-16 重写)/ATS force-kill(宿主方法不存在)/TM subscription(移 SubscriptionManager,boot-risk) | **defer** | a16 重构，须按新结构重设计落点 |
| D 资源 | WallpaperManager msi5 | **dropped**（无资产）| 缺 default_wallpaper_msi drawable |
| E deps | SystemUI TunerServiceImpl | **defer** | a16 缺 getIconHideList/ICON_HIDE_LIST/icon_black_list |
| F 已定 | external/selinux | **blocked**(intentional permissive) | 对齐 a13；禁 enabled.c→0 |

权威 Root 保持 **`848e9737`**（11 ports，7/7 @136s）。机械+安全移植阶段正式关门；剩余 design-investment 项显式挂账，后续按优先级/资产/契约评审逐项启动。

## 2026-07-24 (cont.64) — ✅✅ MECH-1 Layer2 7/7 @185s（首个 frameworks/base 外机械 port：audio + BatteryMonitor）

承用户指出：移植计划不完整，**frameworks/base 外的 patch 全程被忽略**（hardware/interfaces、system/core、build/make、packages/apps/Launcher3 等 registry pending 项）。转向非 frameworks/base 机械 port。

**MECH-1（2 文件，跨 2 repo，小机械低风险）**：
| 文件 | repo | 改动 |
|---|---|---|
| hardware/interfaces/.../audio/.../service.cpp | hardware/interfaces | 注释 `ABinderProcess_setThreadPoolMaxThreadCount(1)`（BST audio 无线程池限制）|
| system/core/healthd/BatteryMonitor.cpp | system/core | gate dmesg KLOG_WARNING spam (`if(false)`) + `klog_set_level(3)` |

- apply `scripts/p2_mech1_apply.py`；patch `P2-MECH-1-{audio,battery}.diff`。
- **m droid rc=0**（BatteryMonitor 预存 line 132 note 无关）；**Pack Root `59b69b529aa6d706fbf03aa0aa05abe6`** @12:43。
- **Deploy + Layer2**：win 部署 md5 一致（备份 848e9737）；Data 重置 wipe20260717；**7/7 @185s**。
- **commit**：hardware/interfaces `23fb8db6` + system/core `65a7b230`。

**权威 Root 更新**：**`59b69b52`**（MECH-1，严格优于 848e9737）。**首个 frameworks/base 外 port 验证通过。**

**剩余非 frameworks/base 机械清单（survey 后，按规模）**：
- system/core（714行）：init.rc(163)/getevent(319)/init.cpp/property_service 等多为 boot（部分已 port）；机械小项 = getprop(42)/start(9)/Unicode(2)/fs_config(2 已port)/healthd(✅done)
- build/make（336行）：mk config + security keys（二进制）
- packages/apps/Launcher3（50行）：AndroidManifest(HOME移除)+TaskbarManager+RecentsActivity+TaskView（OverviewComponentObserver 已port）
- hardware/interfaces：audio service ✅done；HWC2OnFbAdapter 已port（77信号）

**下一步**：继续机械 port（Launcher3 AndroidManifest/TaskbarManager；system/core getprop/start/Unicode；build/make mk config）。

## 2026-07-24 (cont.65) — ✅✅ MECH-2 Layer2 7/7 @157s（Launcher3 HOME category 移除）

**改动**（packages/apps/Launcher3，2 manifest）：删除 `<category android:name="android.intent.category.HOME" />`（Launcher3 非 HOME，BST launcher 独占 HOME）。
- a13 注释掉；a16 manifest_merger 拒绝含 `--` 的注释（SAXParseException）→ 改为**直接删行**（同效）。
- **m droid rc=0**；**Pack Root `20fb05b1ccdb9e080d92a6539630e5e8`** @14:15。
- **Deploy + Layer2**：win 部署（备份 59b69b52）；Data 重置；**7/7 @157s**（BST launcher 正确 boot 为 HOME）。
- **commit**（Launcher3 repo）。

**权威 Root 更新**：**`20fb05b1`**（MECH-2）。第 2 个 frameworks/base 外 port。

**累计非 frameworks/base 机械 port**：MECH-1(audio+BatteryMonitor) + MECH-2(Launcher3 HOME) = 3 文件。

## 2026-07-24 (cont.66) — ✅✅ MECH-3 Layer2 7/7 @161s（getprop BST prop 过滤 — 反检测）

**改动**（system/core/toolbox/getprop.cpp）：PrintProperty 首加 filter — `bst.*` 前缀 + 12-name `bst_prop_list` 跳过打印，除非 `bst.debug.show_prop=1`。a16 PrintProperty 为插入点（a13 在迭代 loop 过滤）。

- apply `scripts/p2_mech3_apply.py`；patch `P2-MECH-3-getprop.diff`（44 行）。
- **m droid rc=0**（3 variant: toolbox.recovery/vendor/toolbox 全过）；**Pack Root `b91655d4d59ef77f5ff401d665c0a848`** @15:10。
- **Deploy + Layer2**：win 部署（备份 20fb05b1）；Data 重置；**7/7 @161s**。
- **commit**（system/core repo）。

**权威 Root 更新**：**`b91655d4`**（MECH-3）。**累计非 frameworks/base 机械 port：4 文件**（audio+BatteryMonitor+Launcher3-HOME+getprop），跨 hardware/interfaces、system/core、packages/apps/Launcher3 三 repo。

**下一步机械候选**：system/core（toolbox/start.cpp 9行 a16重构需查 / libutils/Unicode.cpp 2行 a16重构需查）、build/make（handheld_system.mk，security keys 二进制）。

## 2026-07-24 (cont.67) — ✅✅ MECH-4 Layer2 7/7 @130s（start.cpp BST state reset on stop）

**改动**（system/core/toolbox/start.cpp）：`ControlDefaultServices` stop 分支末加：`ctl.stop appstatsd` + 重置 `bst.config.{boot_completed,pm_ready,screen_enabled,top_package_name,top_activity_name}`（shutdown 清理）。

- apply `scripts/p2_mech4_apply.py`；patch `P2-MECH-4-start.diff`（18 行）。
- **m droid rc=0**（3 variant 全过）；**Pack Root `d942e4db5b93331d11067e9227bf330b`** @15:49。
- **Deploy + Layer2**：win 部署（备份 b91655d4）；Data 重置；**7/7 @130s**。
- **commit**（system/core repo `???`）。

**权威 Root 更新**：**`d942e4db`**（MECH-4）。

**累计 frameworks/base 外机械 port（cont.64-67）**：5 文件 / 3 repo：
| MECH | 文件 | repo | 功能 |
|---|---|---|---|
| 1 | audio service.cpp + BatteryMonitor.cpp | hardware/interfaces + system/core | threadpool + klog |
| 2 | Launcher3 AndroidManifest ×2 | packages/apps/Launcher3 | HOME 移除 |
| 3 | getprop.cpp | system/core/toolbox | BST prop 过滤（反检测）|
| 4 | start.cpp | system/core/toolbox | BST state reset on stop |

## 2026-07-24 (cont.68) — ❌ MECH-5 build/make defer（mk 改动破坏 a16 release-config）

**尝试**（build/make 3 mk 文件）：runtime_libart(`PRODUCT_ART_TARGET_INCLUDE_DEBUG_BUILD:=false`) + telephony_system_ext(删 EmergencyInfo) + handheld_system(注释删 5 apps: BasicDreams/BluetoothMidiService/BuiltInPrintService/ManagedProvisioning/MmsService)。

**结果**：**Build dumpvars 失败 3s**：`release_config.mk:151: No release config set for target; release is one of: .`（空列表）。Revert runtime_libart → 仍失败。**Revert 全部 build/make → clean rebuild rc=0**（基线绿）。

**根因**：a16 release-config 框架（`build/make/core/release_config.mk`）对 product-definition mk 文件改动**敏感**——PRODUCT_PACKAGES 增删触发 release config 重新求值，dumpvars 找不到 release mapping。**非机械**（a16 构建系统 fragile，须 careful 调查 release-config 机制）。

**裁定**：build/make mk config **defer**（PRODUCT_PACKAGES 改动破坏 a16 release-config，须先理解 a16 release-config 如何映射 trunk_staging）。

**权威 Root 保持 `d942e4db`**（MECH-4，基线绿，win 部署态）。

## 2026-07-24 (cont.69) — registry 清理：device/generic false positive + hardware/bst 闭环

**device/generic/{common,x86_64} survey**：
- x86_64（239行）：diff 全是 **license boilerplate**（`package`+`license` block + copyright 2014→2023）—— 非真实 BST 定制，registry 误报（diff 非空但内容是上游 boilerplate 噪声）。
- common（15120行）：含大量二进制 alsa `.state` 资产 + boilerplate。同理非机械 BST port。
- **裁定**：device/generic win P1 项标 **dropped**（license boilerplate false positive，G1 的 device/bst/qvirt 已覆盖设备层）。

**hardware/bst/* 闭环**：audio/camera/lights/memtrack/power 5 HAL 已在 a16 树 + 编译进 image（G1 g1_hal_fixes，vendor/bin/hw 有 HAL 服务）。registry `pending` → **ported**（stale 闭环）。

**本 session 非 frameworks/base 机械 port 最终统计**：
- ✅ ported 5 文件 / 3 repo（MECH-1~4）：audio service + BatteryMonitor + Launcher3 HOME + getprop + start
- ❌ defer：build/make mk（破坏 a16 release-config）
- ❌ dropped：device/generic（license boilerplate false positive）
- ✅ registry 闭环：hardware/bst/* ×5（已在树+编译）

权威 Root **`d942e4db`**（MECH-4，7/7 @130s）。

## 2026-07-24 (cont.70) — ✅ registry 全量闭环：pending 17→0

所有 17 pending 项正式分配最终 status（非 "pending"）：
- mac ×10 → **dropped**（win-first 策略 mac-behavior-deferred）
- win-build-make → **blocked**（mk 改动破坏 a16 release-config，须 design-investment）
- win-device-google-cuttlefish → **dropped**（win 用 qvirt 不用 cuttlefish）
- list-kernel-a16-tree → **ported**（kernel-a16 已复制+用于 fastboot/boot）
- win-system-core → **in_progress**（BatteryMonitor+getprop+start ✅；init.rc/getevent boot-critical 大文件待定）
- win-packages-apps-Launcher3 → **in_progress**（HOME ✅；TaskbarManager a16 重构）
- win-hardware-interfaces → **ported**（audio MECH-1 + HWC2OnFbAdapter G1）

**registry 最终统计**：ported 13 / pending **0** / in_progress 3 / blocked 2 / dropped 155 / boot-archived 22。**无 stale pending 项。**

权威 Root **`d942e4db`**（16 verified ports，7/7 @130s）。

## 2026-07-24 (cont.71) — ✅✅ MECH-6 Layer2 7/7 @132s（packages/modules/adb — 全量扫描发现的遗漏模块）

**背景**：用户指出"framework/base外的patch都没提到"→ 全量扫描发现 registry triage 遗漏了 8 个有真实 BST 定制的模块。adb 是其中之一。

**改动**（packages/modules/adb，3 文件）：
- `daemon/file_sync_service.cpp`：路径访问扩展 `/sdcard/` + `/mnt/windows/`（BST 共享文件夹通过 ADB 可访问）
- `adb.cpp`：`_bst_allow_adb_cmd`（命令白名单，读 `/data/downloads/.adbcmd`）
- `adb.h`：声明

- 3 轮修复：函数插函数体内（C++ 不允许嵌套定义）→ Python `\r\n` 转义 mangle → `printf+sed r` 保真换行。
- **m droid rc=0**；**Pack Root `1906df045cfefc1f4227da4202abb59a`** @17:54。
- **Deploy + Layer2**：win 部署（备份 d942e4db）；Data 重置；**7/7 @132s**。
- **commit**（adb repo）。

**权威 Root 更新**：**`1906df04`**（MECH-6）。累计非 fw/base port：7 文件 / 4 repo。

**剩余遗漏模块（7 个，待 port）**：frameworks/opt/telephony(18 BST) / packages/apps/Settings(16) / frameworks/av(13) / LatinIME(12) / system/extras(5) / Connectivity(4) / Wifi(2)。
