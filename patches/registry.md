# 定制 Registry

把 `-a13`（win）/`-mac`（mac）BlueStacks fork 相对**上游 android-13** 的定制 port 到 **android-16.0.0_r4** 的权威进度表。机器可读：[registry.json](registry.json)（289 项，Phase 0 自动 triage 生成）。

## 方法与基线（重要）

- 对每个子模块计算「最新 `android-13.0.0_r*` tag .. HEAD」的偏离提交数 `since`，并统计 `--author=bluestacks` 的提交数 `bst`。
- **`bst>0` = 真定制（高置信）**；`bst=0` = 待复查（标签漂移或作者过滤未命中）。
- **win 基线 = `android-13.0.0_r49`**（偏离小，since 可参考）。
- **mac 基线 = `android-13.0.0_r83`（漂移严重）**——mac 大量 `bst=0` 但 `since` 巨大（cts=36 万、system/core=4.6 万…）= 上游分支跟踪噪声，**非定制**；mac 一律以 `bst>0` 为准。
- ⚠️ 作者过滤 `--author=bluestacks` 可能漏掉非 bluestacks 邮箱的 mac 提交；mac 的 `bst=0` device/frameworks 仓库 port 前需人工复查。

## 汇总

| 平台 | 总非vanilla | bst>0(真定制) | bst=0(待复查) |
|---|---|---|---|
| win (`android-13`) | 75 | 44 | 31 |
| mac (`android-mac`) | 214 | 11 | 203 |

## P1 — 板 / HAL / kernel（先做，关系到 lunch 目标与启动）

| 平台 | 仓库 | bst | 说明 |
|---|---|---|---|
| **mac** | `device/bst/qvirt` | 8 | **BlueStacks qvirt 虚拟设备 = mac 自定义板 → mac lunch 目标** |
| mac | `kernel-mac` | 22 | mac guest kernel 定制 |
| mac | `hardware/bst/{audio,power,memtrack,lights}` | 2/1/1/1 | BlueStacks HAL（无上游） |
| mac | `device/google/cuttlefish`, `device/generic/vulkan-cereal` | 0/0 | mac 设备配置（bst=0 待复查） |
| win | `device/google/cuttlefish`, `device/generic/x86_64` | 1/1 | win 设备配置 → win lunch 目标 |
| win | `hardware/bst/{camera,audio,power,memtrack,lights}` | 3/2/1/0/0 | BlueStacks HAL |
| win | `kernel` | 2 | win guest kernel gitlink（实际在 `~/kernel-common-a13`） |

## P2 — 功能定制（非 prebuilt，bst>0）

- win：`frameworks/native`(1)、`bionic`(2)、`build`(1)、`cts`(8)、`external/chromium-webview`(4)、`external/swiftshader`(2)、`external/efivar`(1)、`tools/tradefederation/prebuilts`(2)、`hardware/libhardware`(1)
- mac：`external/busybox`(4)

## P3 — prebuilts（二进制版本号，低优先，bst>0）

- win 29 项：`prebuilts/rust`(56)、`prebuilts/gradle-plugin`(48)、`prebuilts/abi-dumps/vndk`(85)、`prebuilts/android-emulator`(20)、`prebuilts/vndk/v{28..32}`、`prebuilts/jdk/*`、`prebuilts/go/*`、`prebuilts/clang/*` 等。
- mac 4 项：`prebuilts/gradle-plugin`(5)、`prebuilts/ktools/{gcc,ndk-r23,kernel-build-tools}`。

## P3-review — bst=0 待复查（port 前人工确认）

win 31 项、mac 203 项。mac 绝大多数为 r83 标签漂移噪声；但 mac 的 `device/*`、`frameworks/*`（如 `frameworks/base` since=185、`frameworks/native` since=25）需复查是否含非 bluestacks 邮箱的真实定制。完整清单见 registry.json（`has_bst=false`）。

## 字段（registry.json 每条）

`id`、`platform`(win/mac)、`project_path`、`area`、`base_tag`、`since_count`、`bst_count`、`has_bst`、`confidence`(high/low)、`phase_hint`(P1/P2/P3/P3-review)、`port_status`(pending)、`host_compat`(unknown)、`owner`、`notes`。

## 下一步

1. ✅ 已采纳**统一板方案**：两端共用 BlueStacks 自定义板 `device/bst/qvirt`，mac `bst_arm64-userdebug`(arm64) + win `bst_x86_64-userdebug`(x86_64 新增)。依据：两端虚拟化均实现 qvirt 设备（mac `qvm` / win `hd` 的 `vmsg`+`hst`+`gr`）+ `hardware/bst/*` HAL 两端都有。Phase 1 = port 单一 `device/bst/qvirt` 到 android-16（arm64+x86_64 双 product）。详见 architecture.md / progress/porting-log。
2. 复查 mac `bst=0` 的 device/frameworks 仓库（作者过滤漏检？）。
3. aosp16 base 树 sync 完成后，按 P1→P2→P3 顺序 port。
