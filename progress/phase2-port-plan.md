# Phase 2 — 全量功能对齐（guest only）

> 状态：**进行中**（2026-07-23 刷新）。  
> Root 绿基线 **`a551d823`** Layer2 **7/7 @199s**（FW-SERVICES-4a）。  
> **完成定义变更**：Phase 2 **必须**完成 a13→a16 **全部功能对齐**（含 frameworks 全量子系统）；机械子集 ported ≠ 关门。  
> **范围**：仅 guest；**不规划** host / Phase 3。构建机争用搁置、不处理。  
> **移植**：一律遵守 `.claude/rules/patch-porting.md`、`dual-platform-customization.md`、`validation-gate.md` 等。

## 人类决策（2026-07-21）

| 议题 | 决策 |
|---|---|
| Phase 3 / host | **移除排期**；暂不规划 host 任务 |
| 构建机负载 | **搁置**；不作阻塞、不为此改流程 |
| Phase 2 完成标准 | **必须**全量功能对齐（含 framework） |
| SELinux | 对齐 a13：**强制 permissive**；禁 `enabled.c→0` |
| Shell Transitions / r262 | 根因 = 缺 **`performance_hint` HAL**（`PerfHintController.onInit` 堵 `wmshell.main`）；**非** BLAST/SF commit 旧说 |
| 代码移植 | 严格遵守移植规则（patch-group、双端清单、win 先行 Layer2、埋点、完成循环） |

## 目标

1. 移植 Phase 1 之外的双端定制，**按子系统做到功能对齐**，非只 port「能编译的一小撮」。
2. 收口可收口的 temp_debt；SELinux **保持** a13 permissive（正式化该策略，非转向 enforcing）。
3. 落地 `performance_hint` HAL（或等价 stub），删除 r262，恢复 Shell Transitions。
4. **mac**：同码 + `bst_arm64` 差异；不做独立 Layer2。
5. **不做** host 适配排期。

## 优先级维度

| 优先级 | 类别 | 说明 |
|---|---|---|
| P0 | 阻塞功能对齐的 temp | `performance_hint` HAL → 删 r262；SELinux permissive 对齐 a13（已基本到位） |
| P1 | frameworks 子系统 | WM / AM / PM / SystemUI / …（P2-FRAMEWORK-REST）—— **Phase 2 主体** |
| P2 | packages / system / hardware | 清单 pending 与业务特性 |
| P3 | prebuilts 等 | 低优先，仍须在 Phase 2 内清完或显式 dropped |

## 关联分组规则

- 同一 `unify_group` 的 win+mac 项同组落地。
- sepolicy / HAL+manifest / framework+JNI / external 互依赖 → 同 `related_group`。
- 每组：文档 → Layer1 → Layer2（强制）→ 存 patch → checkpoint → review（`patch-porting.md`）。

## Phase 2 组

| 组 | 内容 | 状态 |
|---|---|---|
| **P2-TEMP-SEPOLICY** | a13 策略：强制 permissive（IsEnforcing/CheckMacPerms 等）；**禁** `enabled.c→0` | 策略已定；bypass 保留为 intentional |
| **P2-TEMP-SHELL-TRANSITIONS**（原 BLAST） | 补 `performance_hint` HAL + 恢复 HintManager；删 r262；恢复 ENABLE_SHELL_TRANSITIONS | **✅ cont.22b** Root `840137ca` Layer2 7/7 |
| **P2-TEMP-FSTAB** | — | **obsolete** |
| **P2-FRAMEWORK-REST** | frameworks/base 全量特性 | **22/22 core/java** ✅；services/core **7/21** gap ✅；Root **`a551d823`** Layer2 7/7 @199s |
| **P2-PACKAGES** | packages/* | 待做 |
| **P2-EXTERNAL** | external/*（已 drop 噪声；有 bst 信号的保留） | 部分 |
| **P2-SYSTEM** | system/* 非 init | 待做 |
| **P2-BIONIC-ART-LIBCORE** | — | 机械项 ✅ |
| **P2-PREBUILTS** | prebuilts | **dropped**（Phase3 人类搁置；mac-prebuilts-* 显式 dropped） |
| **P2-MAC-ARM64** | `bst_arm64` | scaffold ✅ |

## 临时债细则（更新）

### SELinux（intentional permissive）

- **对齐 a13**：强制 permissive（`IsEnforcing→false` 等），**不是** Phase 2 内设计 enforcing 域策略。
- **禁止**：port a13 `external/selinux` `enabled.c` `is_selinux_enabled→0`（cont.21：apex/netbpfload 回归）。
- `win-external-selinux` 保持 **blocked**。

### Shell Transitions（`performance_hint`）— ✅ cont.22b

- **根因**：缺 `performance_hint`（AIDL `IPower` + 框架 `HintManagerService`）→ `PerfHintController.onInit` 堵 `wmshell.main`。
- **收口**：`android.hardware.power-service.example` + 恢复 R248 注释掉的 `HintManagerService` + `ENABLE_SHELL_TRANSITIONS=true`；Root **`840137ca`** Layer2 7/7。

## P2-FRAMEWORK-REST 子系统队列（功能对齐权威）

> registry 曾标 `ported` 仅为机械子集；下列缺口以 2026-07-21 fork-diff 信号盘点为准（a13 **72** 文件 / a16 **24** / **missing 55**）。

| 子组 | 代表路径 | 状态 |
|---|---|---|
| FW-UTILS | BstUtils / Features / Sdk23 / pagefusion | 部分 ✅（BstUtils metalava） |
| FW-WM | ActivityStarter / ATM / DisplayContent / WMS hostcall | **WM-1 ✅**（Root `eb309e6c` repack）；**WM-2 ❌ revert** |
| FW-AM | ActivityManagerService / ActiveServices | **AM-1 ❌ revert**；escalate（勿在脏 Data 上重试） |
| FW-PM | PackageManagerService 族 | 待做 |
| FW-INPUT | InputManagerService / InputMethodManagerService / ViewRootImpl | 待做（Audio/AppOps ✅ 见 FW-SERVICES） |
| FW-SYSUI | SystemUI BST hooks | 待做 |
| FW-CORE-APP | SharedPreferencesImpl/ResourcesImpl/… | **APP-1~17 ✅**（**22/22 完成**）|
| FW-SERVICES | system_server services/core BST hooks | **7/21 gap ✅**（1a/1b/2a/2b/3/4a）；Root **`a551d823`** |
| FW-FILTER/GRM | BstFilterApps + isAppLaunchAllowed | escalate 史；须带 kill-switch 重做 |

### FW-SERVICES 已移植（7/21 gap）

| 批次 | 文件 | Root | Layer2 |
|---|---|---|---|
| WM-1（先行） | ActivityStarter / ATM / WMS | `eb309e6c` | 7/7 |
| 1a | ClipboardService | `eeb4f714` | 7/7 @167s |
| 1b | LocationManagerService | `21907055` | 7/7 @235s |
| 2b | NotificationManagerService | `d14a9562` | 7/7 @386s |
| 2a | ComponentResolver + IntentResolver | `cf6bf294` | 7/7 @184s |
| 3 | AccountManagerService | `3d3a7997` | 7/7 @169s |
| 4a | AudioService + AppOpsService | **`a551d823`** | 7/7 @199s |

**defer**：RecentsAnimationController（a16 refactor，无同名 server 类）。

**余 14 gap**（peripheral 优先）：InputMethod / InputManager → PM 族 → AM/WM 热路径。

## Gate（Phase 2 完成）

- [ ] 清单内功能定制均 ported 或显式 dropped（含 frameworks 全量子系统；上表子组清空）
- [x] `performance_hint` 落地；r262 删除；Shell Transitions 恢复并 Layer2 绿（cont.22b）
- [x] SELinux 保持 a13 permissive；无 `enabled.c` disable
- [x] mac `bst_arm64` 同码就位（无 mac Layer2）
- [ ] host-compat 行齐全（guest 侧）；**无** host 适配完成要求
- [x] **Win Layer2 7/7 基线恢复**（Data `wipe20260717`；cont.31 Root `4ba4bdd3` @597s）

### Data 备用（Layer2 环境）

| 文件 | 用途 |
|---|---|
| `Data.vhdx.wipe20260717-141744` | **首选备用**（G1 期干净快照） |
| `Data.vhdx.bak.2137` / `bak-r244-*` | 次选完整备份 |
| `Data_orig.vhdx` / `bak.2202` | **禁用**（空盘 panic） |
