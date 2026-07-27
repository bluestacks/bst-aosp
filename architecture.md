# 架构决策记录（ADR）—— bst-aosp Android 13→16 Guest 升级

> 状态：活跃。M1（android-16 win boot）已完成（2026-07-14）；当前阶段 = Phase 1 清单融合移植。

## 1. 升级目标

把 Android **guest 从 android-13 升级到 android-16**（AOSP base ref `android-16.0.0_r4`），保持 BlueStacks 定制功能，并使两端 host（mac `qvm` / win `app-player`+`vbox`）仍能运行该 guest。**AI 主导、人类辅助**。

## 2. 范围边界

- **guest**（升级目标）：基于 android-16.0.0_r4 的**完整 AOSP 树**。定制来源：自动 diff `-a13`（win）/`-mac`（mac）BlueStacks fork vs 上游 android-13。
- **host 适配**（guest 触发）：两端 `hd` + 图形驱动（qemu fork）；虚拟化（`qvm`/`vbox`）按需。
- **不在范围**：host 非虚拟化部分（两端统一，本次不动）；产品 UI 等。

## 3. 组件角色（权威）

| 组件 | 角色 | mac | win |
|---|---|---|---|
| kernel | guest | `kernel-mac.git` | `kernel-common-a13.git` / `kernel-a16` |
| goldfish-opengl | guest 图形 | `ggl-goldfish-opengl-mac.git` | `ggl-goldfish-opengl-pie.git` |
| frameworks-base 等 | guest 框架（完整 AOSP 树） | `…-mac.git` | `…-a13.git` |
| qemu fork | **host 图形驱动**（非虚拟化） | `ggl-external-qemu-mac.git` | `qemu.git` |
| hd | **host 框架** | `hd-mac.git` | `hd.git` |
| qvm / vbox | **host 虚拟化**（VMM） | `qvm` | `vbox`（`app-player` 的 `hd/` 内） |

关键区分：**qemu = host 图形（不是虚拟化）**；**虚拟化 = mac `qvm` / win `vbox`**；`hd` = host 框架。

## 4. 平台策略

- **win 先行且做验证；mac 不做独立验证**——win 完成后基于**同一份代码**（统一源 + 平台差异）开发。见 [.claude/rules/platform-win-first-mac-reuse.md](.claude/rules/platform-win-first-mac-reuse.md)。
- **图形驱动可使用 mac 分支 `bst-v5.21.700-nxt_mac2` 的代码构建**（跨平台）。
- registry 按 `platform`(win/mac/both) + `unify_group` 组织；有意识统一两端，特有定制加平台区分。

### 4.1 统一板 `device/bst/qvirt`（主线 · 已确认）

两端共用 BlueStacks 自定义板 `device/bst/qvirt`，**同一份板源**，x86_64 / arm64 **各自定制**（BoardConfig / product mk）：

| 平台 | product | arch |
|---|---|---|
| win | `bst_x86_64` | x86_64 |
| mac | `bst_arm64` | arm64 |

- 依据：两端虚拟化均实现 qvirt 设备模型（mac `qvm`；win `hd/Source/{vmsg,hst,gr}`）；`hardware/bst/*` HAL 两端都有。
- 共享：`device.mk` / `init.bst.rc` / `fstab.bst` 等 arch 无关配置。
- 差异：BoardConfig、product mk、arch 相关 HAL/内核驱动。

### 4.2 Boot 路径回归决策（2026-07-15）

| 项 | 内容 |
|---|---|
| M1 boot 实际路径 | `device/generic/common` + `device/generic/x86_64`，lunch `android_x86_64-trunk_staging-eng` |
| 主线目标 | 统一板 `device/bst/qvirt` |
| Phase 1 动作 | 把 booted generic overlay **并入 qvirt**，产出 `bst_x86_64`；与 mac `bst_arm64` 对齐 |
| 风险 | 迁移可能打破已绿 boot → G1 必须以 Layer 2 boot 回归 oracle 为 gate，不过则 escalate |

证据：`patches/android-16/RESTORE.md`、`progress/android-16-boot-guide.md`。

## 5. 验证策略（设计支柱）

**两层验证**（「`m` 成功 ≠ 能启动」）：

- **Layer 1 — 编译**（远程）：`lunch` + `m`，回读 exit code + 产物。
- **Layer 2 — 启动 readback**：boot oracle（见 `docs/boot-oracles.md` + boot-guide §7）：`system mounted from sfs` → `boot_completed=1` → `Player state: ready` → Settings 可见 → 优雅关机。

**Phase 1**：Layer 1 每 patch-group 强制；Layer 2 在「并入 boot 镜像」节点跑（相关组可批量并入后一次验证，保留每组 Layer 1 证据）。
**Phase 2+**：每组 Layer 1 + Layer 2。

埋点与测试约定：见 [.claude/rules/instrumentation-and-tests.md](.claude/rules/instrumentation-and-tests.md)。

## 6. 工作单元与 porting 顺序

工作单元 = **patch-group**（关联定制一起移植），不是孤立单 patch。

顺序：
1. 双端 diff 出完整定制清单 + 统一/平台差异标注 + boot 存量映射（registry v2）。
2. **Phase 1**：融合（临时 boot patch + 清单最小 patch）→ G1–G10（统一板最先）。
3. **Phase 2**：其余按优先级 + 关联分组；临时债真实修复。
4. **mac**：基于同份代码收尾（不做独立验证）。

每组：研究 → rebase → 文档（源/用途/质量/影响）→ 验证回环 → 存 patch → checkpoint（可恢复）。见 [.claude/rules/patch-porting.md](.claude/rules/patch-porting.md)。

## 7. host-guest 契约面

- **图形**：host qemu fork ↔ guest goldfish-opengl。
- **虚拟化设备模型**：`qvm`/`vbox` ↔ guest kernel/设备模型（bstvmsg / bstpgaipc / gr-channel）。
- **框架**：`hd` ↔ guest 通道（hcall / gcall / xpl）。
- 强约束：**绝不静默破坏 host**；每个 patch-group 完成前 host-compat 必须有一行 ok 或显式 escalate。

## 8. 风险

- **qvirt 迁移打破 boot**：G1 结构性改动 → Layer 2 回归 gate。
- **临时债收口**：SELinux / BLAST 属判断性 → escalate，不机械绕过。
- **rebase 冲突**：跨 13→16 → 定制收敛到 device/vendor 接缝。
- **构建耗时**：全量 `m` 数小时 → 后台化 + 断线恢复。
- **远程不可达**：SSH 断线 → escalate，不切错误主机凑数。
