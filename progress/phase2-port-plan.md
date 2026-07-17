# Phase 2 — 其余定制 + 临时债收口 + mac 同码

> 状态：计划框架（2026-07-15）。在 Phase 1 Gate 通过后启动。  
> 输入：registry v2 中 `phase!=P1` 或 `temp_debt=true` 项；android-13 功能对齐目标。

## 目标

1. 移植 Phase 1 之外的双端定制（按优先级 + 关联分组）。
2. **真实修复** Phase 1 临时债（sepolicy、BLAST），撤销 bypass。
3. 功能对齐 android-13 baseline。
4. **mac**：基于同一份代码加 arm64 差异；**不做独立验证**。

## 优先级维度

| 优先级 | 类别 | 说明 |
|---|---|---|
| P0 | 临时债收口 | sepolicy / BLAST / fstab-vold；阻塞「可维护 boot」 |
| P1 | 启动后稳定性 | 非 boot 但影响崩溃/性能的 system/frameworks |
| P2 | 功能对齐 | packages / external 业务特性 |
| P3 | prebuilts 版本号 | 二进制 pin，低优先 |

## 关联分组规则

- 同一 `unify_group` 的 win+mac 项尽量同组落地（共享路径一次改）。
- sepolicy 各域、HAL+manifest、framework+JNI、external 互依赖 → **同 `related_group` 一起移植**。
- 每组仍走 patch-group 全验证回环（Layer1 + Layer2）+ 文档 + 存 patch + checkpoint。

## 建议 Phase 2 组（初稿，清单 triage 完成后细化 id）

| 组 | 内容 | 依赖 |
|---|---|---|
| **P2-TEMP-SEPOLICY** | BST sepolicy；撤销 G7 permissive/CheckMacPerms/socket/insecure-file/coldboot；property_service 类齐全 | G7 |
| **P2-TEMP-BLAST** | 修 goldfish/SF BLAST commit callback；删 r262 TEMP；恢复 shell transitions | G3, G5 |
| **P2-TEMP-FSTAB** | 真实 fstab/vold；撤销 `do_exec /vdc` skip | G7, G1 |
| **P2-FRAMEWORK-REST** | **frameworks/base(win bst=220 / mac 68) + frameworks/native(71/10) 的完整特性集**（G5 只做了 boot 子集）；按子系统拆分再 port | G5 |
| **P2-PACKAGES** | packages/* 功能定制 | G6 |
| **P2-EXTERNAL** | external/*（体积大，按子系统再拆；清单见 registry external 项） | — |
| **P2-SYSTEM** | system/* 非 init 部分 | G7 |
| **P2-BIONIC-ART-LIBCORE** | bionic/art/libcore/cts 等 | G9 |
| **P2-PREBUILTS** | prebuilts 版本对齐 | — |
| **P2-MAC-ARM64** | 同码基础上 `bst_arm64` 差异（BoardConfig/驱动）；不跑 mac Layer2，但登记 `mac-behavior-deferred` | G1 完成 |

> **P2-FRAMEWORK-REST 是 Phase 2 主体工作量**：frameworks/base 的 220 个 win 定制里，boot 只用到一小撮；其余是功能特性，须按子系统（WM/AM/PM/media/telephony…）分组、fork-diff overlay、逐组验证。这是「功能对齐 android-13 baseline」的核心。

## 临时债收口细则

### SELinux / property（escalate 边界）

- 判断性：domain 转换、`property_service` 类、vendor sepolicy 版本 → **escalate**，不机械绕过。
- 完成后：日志中无 `Unknown class property_service`；服务落正确域（非 `u:r:kernel:s0`）；可逐步 `enforcing`。

### BLAST / Shell Transitions

- 根因在 SF/goldfish sync 路径；修后删 `aosp16__frameworks_base__r262-temp-disable-shell-transitions.patch`。
- 验证：Settings 可见且 `ENABLE_SHELL_TRANSITIONS=true`；`Transition Root` 不卡死。

### keystore wipe

- 保持运维脚本 + RESTORE 文档；非源码移植。评估是否可改为「首次 boot 自动清陈旧 blob」。

## mac 同码收尾

1. 以 win Phase1(+相关 P2) checkpoint 为唯一 guest 源。
2. 仅追加 `platform=mac` / arm64 BoardConfig / mac-only unify 项。
3. **不**要求 mac BlueStacks Layer2；win Layer1「不破坏 x86 构建」即可关门。
4. mac host（qvm/hd-mac）适配不在本 Phase guest 范围内（见 roadmap Phase 3）。

## 每组完成定义

与 Phase 1 相同：文档 → Layer1 → Layer2（TEMP 与功能组强制）→ 存 patch → checkpoint → review。

## Gate→Phase 3

- [ ] `temp_debt` 清零或显式 escalate 清单
- [ ] 高优先功能对齐项 ported
- [ ] mac 同码差异已合入统一树
- [ ] host-compat 行齐全
