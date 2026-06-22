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
