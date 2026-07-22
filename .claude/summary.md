# Summary — Phase 2 进行中（2026-07-22 cont.25 — Win Layer2 7/7 基线已恢复）

> guest 全量功能对齐；host/Phase3 暂不规划。权威时间线：`progress/porting-log.md` · 计划：`progress/phase2-port-plan.md`。

## 已收口

| 项 | 证据 |
|---|---|
| Shell Transitions / r262 | `power-service.example` + HintManager；Root **`840137ca`** Layer2 7/7（cont.22b）；registry r262 → `removed` |
| SELinux | a13 permissive；`enabled.c→0` **blocked** |
| mac `bst_arm64` | scaffold；无独立 Layer2 |
| P3 prebuilts | **dropped**（人类搁置 Phase3） |
| FW-WM-1 | ActivityStarter hideBlueStacksPkg + ATM getGlVersion；patch 已存；树内保留 |

## 进行中 / 阻断

| 项 | 状态 |
|---|---|
| Win Layer2 基线 | ✅ **恢复 7/7 @118s**（Root `eb309e6c` + `Data.vhdx.wipe20260717`）；证实热路径回归是 Data 污染非 WM-1 代码 |
| `win-frameworks-base` | `in_progress`；gap≈55 文件（core/java 22 / services/core 25 / 其余 8） |
| FW-WM-2 / FW-AM-1 | **revert + escalate**（热路径；基线稳后带 kill-switch 重做） |

## 绿 / 坏 Root（md5 前缀）

| md5 | 备注 |
|---|---|
| **`dc4d2653`** | **当前权威**（FW-CORE-APP-3 foundation，Layer2 7/7 @534s，严格优于 8a5703ac）|
| `8a5703ac` | FW-CORE-APP-2（7/7 @383s）|
| `6f6575a1` | FW-CORE-APP-1（7/7 @124s）|
| `840137ca` | cont.22b 绿（performance_hint） |
| `eb309e6c` | WM-1 repack（基线恢复用） |
| `4e144a82` / `2d2a3f80` | AM-1 / WM-2 **坏**（勿用） |

## Data 备用

- **用**：`Data.vhdx.wipe20260717-141744`（首选）、`bak.2137`、`bak-r244-*`
- **禁**：`Data_orig.vhdx`、`bak.2202`（空盘 panic）
- 半擦 keystore **不够**：须连 locksettings/spblob，否则 `SP protector key is missing`

## 已完成：FW-CORE-APP-1/2/3（cont.26-30）✅

| 批 | 文件 | commit | Layer2 |
|---|---|---|---|
| APP-1 | AccessibilityManager / EditText / InputMethodService | `c4e34c7f` | 7/7 @124s |
| APP-2 | View（Roblox）/ ApkLiteParseUtils（Pokemon）| `050e473c` | 7/7 @383s |
| APP-3 | Instrumentation（bst 方法）/ ContextImpl（startActivity hook，foundation）| `23fe7f0d` | 7/7 @534s |
| 权威 Root | **`dc4d2653`**（FW-WM-1 + APP-1/2/3，**7/22 core/java ported**）| | |
| 关键学习 | `m framework` 只产 .class jar（须 m droid 做 dexpreopt+install）；**a16 新增 public BST 方法须 `/** @hide */`**（否则 metalava UnflaggedApi）；henry python3 失控进程饿死 build，merge_zips "ninja may be stuck" 是假警报。 | | |

## 下一步

1. 剩余 15 core/java（ViewRootImpl FreeFireMax/Editor/TextView/InputManager/InputDevice/Environment/Settings/SharedPreferencesImpl/BaseBundle/ResourcesImpl/Display/…）按批续推（public hook 须加 @hide）
2. 每次失败 boot **先 cp wipe20260717→Data.vhdx 恢复**再继续
3. 热路径（FW-AM/FW-WM-2/GRM/PM 族 services/core）基线稳固后带 kill-switch 重做

## Rule changes

无新行为规则；文档同步 cont.22–24 事实与 Data 备用策略。
