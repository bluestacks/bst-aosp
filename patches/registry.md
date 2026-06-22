# 定制 Registry

`-a13`(win)/`-mac`(mac) BlueStacks fork 相对**上游 android-13** 的定制，port 到 **android-16.0.0_r4** 的权威进度表。机器可读：[registry.json](registry.json)（**457 项**，Phase 0 完整 triage——android-13/android-mac 递归 init 完成后重跑；早前 289 项版因 init 未完成有遗漏，已废弃）。

## 方法与基线

- 对每子模块计算「最新 `android-13.0.0_r*` tag .. HEAD」偏离数 `since`，并统计 `--author=bluestacks` 提交数 `bst`。
- **`bst>0` = 真定制（高置信）**；`bst=0` = 待复查（标签漂移或作者过滤未命中）。
- win 基线 `android-13.0.0_r49`；**mac 基线 `android-13.0.0_r83`（漂移严重，since 不可靠，以 bst>0 为准）**。
- ⚠️ 作者过滤 `--author=bluestacks` 可能漏非 bluestacks 邮箱提交；mac `bst=0` 的 device/frameworks port 前需人工复查。

## 汇总（完整版）

| 平台 | 总非vanilla | bst>0(真定制) | bst=0(待复查) |
|---|---|---|---|
| win (`android-13`) | 229 | **202** | 27 |
| mac (`android-mac`) | 228 | **48** | 180(r83 漂移噪声为主) |

bst>0 by area：win external136/prebuilts29/packages10/hardware7/system5/frameworks4/device3/…；mac prebuilts15/packages7/hardware6/external5/frameworks3/system3/build2/device2/…。

## P1 — 板 / HAL / kernel（先做，lunch 目标 + 启动）

| 平台 | 仓库 | bst | 说明 |
|---|---|---|---|
| **mac** | `device/bst/qvirt` | **35** | BlueStacks qvirt 自定义板 → mac lunch `bst_arm64` |
| mac | `kernel-mac` | 33 | mac guest kernel 定制 |
| mac | `hardware/bst/{audio,power,memtrack,lights}` | 2/1/2/1 | BlueStacks HAL |
| mac | `device/google/cuttlefish` | 1 | 设备配置 |
| **win** | `device/generic/common` | **63** | win 设备定制集中处（generic 设备配置） |
| win | `kernel` | 55 | win guest kernel gitlink（实在 `~/kernel-common-a13`） |
| win | `device/google/cuttlefish`, `device/generic/x86_64` | 1/1 | win 设备配置 → lunch `bst_x86_64`(统一板) |
| win | `hardware/bst/{camera,audio,memtrack,power,lights}` | 3/2/1/1/1 | BlueStacks HAL |

> 统一板方案已采纳：两端共用 `device/bst/qvirt`，mac `bst_arm64`(arm64) + win `bst_x86_64`(x86_64 新增)。win `device/generic/common`(bst63) 是 win 设备定制的主体，port 时须并入统一板。

## P2 — 功能定制（非 prebuilt，bst>0）

win `external/*`（136 项，主体）、`packages/*`(10)、`system/*`(5)、`frameworks/*`(4)、`bionic`/`build`/`art`/`cts`/`libcore`(各1)；mac `packages/*`(7)、`frameworks/*`(3)、`system/*`(3)、`external/*`(5) 等。完整清单见 registry.json（`has_bst=true && area!=prebuilts`）。

## P3 — prebuilts（二进制版本号，低优先，bst>0）

win 29（rust/gradle-plugin/vndk/jdk/go/clang…）；mac 15。

## P3-review — bst=0 待复查

win 27、mac 180。mac 多为 r83 漂移噪声；但 mac `bst=0` 的 device/frameworks 需复查是否漏检。

## 字段（registry.json）

`id`、`platform`、`project_path`、`area`、`base_tag`、`since_count`、`bst_count`、`has_bst`、`confidence`、`phase_hint`(P1/P2/P3/P3-review)、`port_status`(pending)、`host_compat`(unknown)、`notes`。

## 下一步

1. ✅ lunch 目标已定（统一板 `device/bst/qvirt`：mac `bst_arm64`/win `bst_x86_64`）。
2. android-13 基线构建通过后，按 P1→P2→P3 顺序 port 到 android-16（`~/aosp16`）。
3. port 前复查 mac `bst=0` device/frameworks（作者过滤漏检？）。
