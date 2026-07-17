# 定制 Registry（v2）

`-a13`(win) / `-mac`(mac) BlueStacks fork 相对**上游 android-13** 的定制，port 到 **android-16.0.0_r4** 的权威进度表。

| 文件 | 说明 |
|---|---|
| [`registry.json`](registry.json) | **权威**机器可读（schema v2） |
| [`registry.schema.md`](registry.schema.md) | 字段定义 |
| `registry.v1.backup.json` | v1 错位树 triage（**废弃**） |
| [`triage_win.jsonl`](triage_win.jsonl) / [`triage_mac.jsonl`](triage_mac.jsonl) | 远程 triage 原始输出 |
| [phase1-port-plan.md](../progress/phase1-port-plan.md) | Phase 1 G1–G10 |
| [phase2-port-plan.md](../progress/phase2-port-plan.md) | Phase 2 + 临时债 + mac |
| [android-16/RESTORE.md](android-16/RESTORE.md) | M1 boot 可恢复存档 |

## 方法（v2 · 2026-07-15）

远程：`markxu@172.16.6.191`

| 树 | 路径 | 分支 |
|---|---|---|
| win | `~/app-player/android-13` | `bst-v5.22.210` |
| mac | `~/app-player-mac/android-mac` | `bst-v5.21.700-nxt_mac2` |

- `scripts/triage_focused.sh`：high-value 前缀全量扫描；`external/*` 仅 bluestacks 作者 + timeout。
- `scripts/remote_fill_key_stats.sh`：补全关键路径（如 win `frameworks/base` bst=**220**）。
- 修正旧缺陷：不唯依赖单一 r 号；mac `since` 受 r83 膨胀时以 `bst_count` 为准；`device/bst/qvirt` 无 r* tag 时用路径信号。
- **M1 boot 存量**映射为 `port_status=boot-archived`；临时 hack → `temp_debt=true`。

## 汇总（registry.json 当前 · review-fix 后）

| 维度 | 数量 |
|---|---|
| 总计 | **196** |
| boot-archived（M1 映射） | 23 |
| dropped（Pixel/物理 HAL，与 qvirt 无关） | 13 |
| temp_debt | 4 |
| P1 / P2 / P3 | 45 / 127 / 24 |
| P1 pending 非 boot | 25 |
| external（win / mac） | 86 / 4 |

> **review-fix（2026-07-15）**：① frameworks/base·native 全项目特性集降 **P2**（`P2-FRAMEWORK-REST`），G5 只做 boot-minimal 子集；② 13 个 mac Pixel/物理设备 HAL 标 `dropped`；③ 清 bogus `since`（r83 误配）；④ **external 补采完成**（`triage_external.sh`，win 27→86），覆盖回归。

## 当前工作：G1 ✅ Phase 1 完成（2026-07-17 · boot 到 launcher，host oracle 全绿）

> 2026-07-16 曾误记「7/7 PASS（245s）」——245s 是 G1-RESTORE 的「期望」值被当结果，G1 镜像从未真部署实测（详见 porting-log cont.1/cont.4 订正）。**真正 Phase 1 达成 = 2026-07-17 cont.4**：打包镜像部署 + 干净 Data 首启 + readback 证实。

| 项 | 状态 |
|---|---|
| `device/bst/qvirt` 脚手架（含 PRODUCT_PACKAGES hwservicemanager） | ✅ |
| `lunch bst_x86_64-trunk_staging-eng` | ✅ |
| 配置等价预检 | ✅ EQUIVALENT |
| Layer1 `m droid`（rc=0，VINTF patch applied） | ✅ |
| Layer2 boot 回归（host oracle：Player ready + fUiHideBootProgressBar + ActivityDisplayed） | ✅ **boot 到 launcher**（porting-log cont.4） |
| Root.vhd（gralloc=bst + BST launcher 预装 + create_vdi 分区+UUID） | `2a7a497afd48a595758bba026faf55ae` |
| 修复链 | packaging(create_vdi) → hwservicemanager(PRODUCT_PACKAGES) → bs_bootlog(fastboot KDIR) → gralloc=bst(hwcomposer SIGSEGV 0) → BST launcher 预装 |
| temp_debt（Phase 2 收口） | service.cpp DIAG bypass（→VINTF level）、gralloc build.prop append（→init.sh）、r262 BLAST、P2-PACK-148、P2-APKS-DATAFS |
| G1 checkpoint | ✅ `patches/android-16/checkpoints/G1.md` |

详情：[`progress/porting-log.md`](../progress/porting-log.md) · [`progress/phase1-port-plan.md`](../progress/phase1-port-plan.md) §G1。

### 关键清单命中（remote fill）

| 平台 | project | since | bst | phase 组 |
|---|---|---|---|---|
| win | frameworks/base | 406 | **220** | G5 |
| win | frameworks/native | 116 | 71 | G5 |
| win | device/generic/common | 107 | 63 | G1 |
| win | system/core | 36 | 29 | G7 |
| win | build/make | — | 15 | G9 |
| win | packages/apps/Launcher3 | 8 | 4 | G6 |
| mac | frameworks/base | 304† | 68 | G5 |
| mac | device/bst/qvirt |（无 r* tag）| 路径信号 | G1 |
| mac | system/core | 46428† | 16 | G7 |

† mac since 受 `android-13.0.0_r83` 漂移，**不可作规模依据**。

## Phase groups

| Group | 标题 | Layer2 |
|---|---|---|
| G1 | 统一板 `device/bst/qvirt`（generic→qvirt） | 必须 |
| G2 | kernel-a16 | 必须 |
| G3 | goldfish-opengl-pie | 必须 |
| G4 | hd guest JNI | 必须 |
| G5 | BST frameworks | 必须 |
| G6 | launcher | 必须 |
| G7 | init / shutdown（含 debt） | 必须 |
| G8 | HAL / VINTF | 必须 |
| G9 | build 适配 | Layer1 |
| G10 | buildscripts / 打包 | 必须（收口） |
| TEMP | bringup bypass | Phase2 |

## Boot 存量 → 组（摘要）

见 [phase1-port-plan.md](../progress/phase1-port-plan.md)。临时债：`r262` shell transitions、SELinux/property bypass、keystore wipe 运维。

## 下一步

1. **G1 ✅ 完成（Phase 1，2026-07-17）**：统一板 `bst_x86_64`/`qvirt` boot 到 launcher（host oracle 全绿，porting-log cont.4）。详见 [G1 checkpoint](android-16/checkpoints/G1.md)。
2. **Phase 2 启动**：(a) temp_debt 收口（service.cpp DIAG→VINTF level、gralloc→init.sh、vndservicemanager→G9 build-config、P2-PACK-148、P2-APKS-DATAFS、r262 BLAST）；(b) 有序移植 G2(kernel)→G3(goldfish)→G4(hd JNI)→G5(frameworks)→G6(launcher)→G7(init/shutdown)→G8(HAL/VINTF)→G9(build)→G10(packaging)，每组 `/port-patch` + 存 patch + checkpoint。
3. **mac**：win Phase 1 稳定后，bst_arm64 基于同码 + arm64 BoardConfig（Phase 3 host 阶段集中验）。
