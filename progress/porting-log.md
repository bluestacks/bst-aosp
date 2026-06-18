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
