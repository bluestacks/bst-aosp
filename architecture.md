# 架构决策记录（ADR）—— bst-aosp Android 13→16 Guest 升级

> 状态：草案。组件角色由用户提供（权威）；Phase 0 补全的项标【待确认】。

## 1. 升级目标

把 Android **guest 从 android-13 升级到 android-16**（AOSP base ref `android-16.0.0_r4`），保持 BlueStacks 定制功能，并使两端 host（mac `qvm` / win `app-player`+`vbox`）仍能运行该 guest。**AI 主导、人类辅助**。

## 2. 范围边界

- **guest**（升级目标）：基于 android-16.0.0_r4 的**完整 AOSP 树**（从拉代码 `repo init`/`sync` 做起）。定制来源：自动 diff `-a13`（win）/`-mac`（mac）BlueStacks fork vs 上游 android-13。
- **host 适配**（guest 触发）：当前最小范围 = 两端 `hd`（win ← `hd.git`、mac ← `hd-mac.git`）+ 图形驱动（qemu fork，可从 mac 分支代码构建）；虚拟化（`qvm`/`vbox`）后续阶段纳入。
- **不在范围**：host 非虚拟化部分（两端统一，本次不动）；产品 UI 等。
- 仅参考用户指定目录：bst-scout / app-player-dev / app-player / qvm / bst-aosp。

## 3. 组件角色（权威）

| 组件 | 角色 | mac | win |
|---|---|---|---|
| kernel | guest | `kernel-mac.git` | `kernel-common-a13.git` |
| goldfish-opengl | guest 图形 | `ggl-goldfish-opengl-mac.git` | `ggl-goldfish-opengl-pie.git` |
| frameworks-base 等 | guest 框架（完整 AOSP 树） | `…-mac.git` | `…-a13.git` |
| qemu fork | **host 图形驱动**（非虚拟化） | `ggl-external-qemu-mac.git` | `qemu.git` |
| hd | **host 框架** | `hd-mac.git` | `hd.git` |
| qvm / vbox | **host 虚拟化**（VMM） | `qvm` | `vbox`（`app-player` 的 `hd/` 内） |

关键区分：**qemu = host 图形（不是虚拟化）**；**虚拟化 = mac `qvm` / win `vbox`**；`hd` = host 框架。

## 4. 平台策略

- **win 先行**，全程跨平台意识（mac 跟进）。同一 guest 须在两个虚拟化栈上运行。
- **图形驱动可使用 mac 分支 `bst-v5.21.700-nxt_mac2` 的代码构建**（跨平台）。
- registry 按 `platform`(mac/win) 分组，共用同一套规则。
- **lunch target / 板：统一板方案（已采纳，覆盖早前「不可统一」结论）**。两端都用 BlueStacks 自定义板 `device/bst/qvirt`，仅 arch 不同：
  - **mac** → `bst_arm64-userdebug`（arm64，板源自 `android-mac/device/bst/qvirt`，已存在）。
  - **win** → `bst_x86_64-userdebug`（x86_64，**新增** x86_64 product 变体；win 不再用 cuttlefish/generic）。
  - 依据：两端虚拟化**均实现 qvirt 设备模型**——mac `qvm`、win `hd/Source/{vmsg(bstvmsg), hst(bstpgaipc), gr(gr-channel)}`；`hardware/bst/*` HAL 两端都有。板配置（`device.mk`/`BoardConfig`/`init.bst.rc`/`fstab.bst`）arch 无关、共享，arch 由 BoardConfig 定。
  - Phase 1 = port **单一 `device/bst/qvirt`** 到 android-16，产出 arm64+x86_64 双 product。
  - 待办：win guest kernel（`kernel-common-a13`→android-16）需含 `bstvmsg`/`bstpgaipc` 驱动（驱动源在 mac kernel-mac 的 22 个 bst 提交或 hd 随模块注入；属 kernel P1 移植细节）。

## 5. 验证策略（设计支柱）

**两层验证**，因为「`m` 成功 ≠ 能启动」是本项目最大陷阱：

- **Layer 1 — 编译**（远程，完整 AOSP 树）：`lunch` + `m`，回读 exit code + 产物。
- **Layer 2 — 启动 readback**：kernel log、by-name symlink、动态分区、挂载、init、SELinux、verity、bootanim→launcher。**需 host 虚拟化就位后才能跑**。

逐层验证上限：Layer 1 是构建期上限；Layer 2 是行为期上限。Phase 1 仅达 Layer 1；Phase 2 起 Layer 2。

## 6. 工作单元与 porting 顺序

工作单元 = **一个定制 port**（从 `-a13`/`-mac` fork 的一条定制 port 到 android-16）。

顺序：
1. **构建前**：diff 出完整定制清单 + 评估分阶段（registry 标 phase）。
2. **自定义板**（device/board overlay）最先做（构建前提）。
3. 按启动依赖 port 其余：kernel → guest 图形 goldfish-opengl → frameworks-base → 其余 AOSP 仓库。
4. **guest 就绪后**：port hd + 图形驱动 + 虚拟化进 host 最小实现 → Layer 2 启动验证。
5. 功能对齐 android-13 baseline。

## 7. host-guest 契约面

- **图形**：host qemu fork ↔ guest goldfish-opengl。
- **虚拟化设备模型**：`qvm`/`vbox` ↔ guest kernel/设备模型。
- **框架**：`hd` ↔ guest 通道。
- 镜像分区布局、设备/PCI 约定（具体 Phase 0 从 `qvm`/`app-player` 对 guest 的调用关系识别）。
- guest 就绪后参考 `app-player` 编译脚本，了解如何产出 host 使用的镜像（镜像格式/打包权威）。
- 强约束：**绝不静默破坏 host**；每个 patch 集 Phase 完成前 host-compat 必须有一行 ok 或显式 escalate。

## 8. 风险

- **rebase 冲突**：跨 13→16 三大版本，`-a13`/`-mac` 定制与上游 delta 冲突多 → 自定义板/device overlay 先做、定制收敛到最小接缝。
- **dm-verity / SELinux 回归**：android-16 策略变化 → 作 escalate 项，不自行改。
- **构建耗时**：完整 AOSP 树全量 `m` 数小时 → 后台化 + 断线恢复。
- **host 兼容破坏**：图形/虚拟化契约漂移 → 两端 smoke + host-compat 检查点。
- **远程不可达**：SSH 主机断线 → escalate，不切错误主机凑数。

## 9. 待确认（Phase 0 补全）

1. AOSP 构建 target / manifest / lunch 目标 / 设备；自定义板（device overlay / BoardConfig）形态与来源。
2. 远程 Ubuntu 主机地址、AOSP checkout 路径、磁盘容量（全量树 ~数百 GB）。
3. 完整定制清单（diff `-a13`/`-mac` vs 上游 android-13 的结果）与每项阶段评估。
