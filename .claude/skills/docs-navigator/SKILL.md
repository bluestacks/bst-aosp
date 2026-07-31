---
name: docs-navigator
description: 在 bst-aosp 任何区域动手前找到对的文档——架构决策与组件角色（guest 完整 AOSP 树 / host 图形 qemu fork / 虚拟化 qvm+vbox / hd 框架）、平台策略（win 先行验证 mac 同码复用）、两层验证（Layer 1 编译 / Layer 2 启动 oracle）、阶段模型（M1 boot 完成→Phase1 融合→Phase2 其余+临时债→Phase3 CI）、定制 registry v2、host-guest 契约、远程构建拓扑、以及三处 host 源（qvm / app-player / app-player-dev）
---

# 文档导航器

动手前用它找到对的文档。本仓库是**本地协调/规则/registry 区**（不含 AOSP 源码），源码与编译在远程 Ubuntu 主机。先读相关文档再 grep/猜（见 `.claude/rules/research-before-action.md`）。

## 架构（仓库根）

- **[architecture.md](../../../architecture.md)** — 完整架构决策记录。关键节：升级目标、组件角色、**统一板 qvirt + boot 路径回归决策（§4.2）**、验证策略、porting 顺序、host-guest 契约、风险。
- **[architecture-brief.md](../../../architecture-brief.md)** — 压缩版，先读它抓 gist。

## 验证

- **两层验证** → `architecture.md` *验证策略* + [validation-gate.md](../../rules/validation-gate.md)。
- **埋点与测试** → [instrumentation-and-tests.md](../../rules/instrumentation-and-tests.md)。
- **启动 oracle** → [docs/boot-oracles.md](../../../docs/boot-oracles.md) + [progress/android-16-boot-guide.md](../../../progress/android-16-boot-guide.md) §7 / [patches/android-16/RESTORE.md](../../../patches/android-16/RESTORE.md)。

## 阶段与流程

- **阶段模型** → [SETUP-ROADMAP.md](../../SETUP-ROADMAP.md)（AOSP16 开发线 → promotion → Android-16 主线维护）。
- **完成循环** → [completion-loop.md](../../rules/completion-loop.md)。
- **双端清单** → [dual-platform-customization.md](../../rules/dual-platform-customization.md)。
- **win 先行 / mac 同码** → [platform-win-first-mac-reuse.md](../../rules/platform-win-first-mac-reuse.md)。
- **定制移植（patch-group）** → [patch-porting.md](../../rules/patch-porting.md) + `/port-patch`。

## 进度与契约

- **定制 registry v2** → [patches/registry.md](../../../patches/registry.md) / [patches/registry.json](../../../patches/registry.json) / [patches/registry.schema.md](../../../patches/registry.schema.md)。
- **Phase 计划** → [progress/phase1-port-plan.md](../../../progress/phase1-port-plan.md) / [progress/phase2-port-plan.md](../../../progress/phase2-port-plan.md)。
- **移植时间线** → [progress/porting-log.md](../../../progress/porting-log.md)。
- **A16 boot 存档** → [patches/android-16/RESTORE.md](../../../patches/android-16/RESTORE.md)。
- **host 兼容** → [progress/host-compat.md](../../../progress/host-compat.md) + [host-guest-contract.md](../../rules/host-guest-contract.md)。

## 远程与构建

- **主机/路径** → [docs/remote-topology.md](../../../docs/remote-topology.md) + [remote-build.md](../../rules/remote-build.md)。
- **构建命令** → [docs/build-commands.md](../../../docs/build-commands.md)。

## 三处 host 源（本地参考）

- **mac 虚拟化/图形** → `C:\workspace\qvm`
- **win 完整 host** → `C:\workspace\app-player`
- **win 最小 host** → `C:\workspace\app-player-dev`
- **开发模式参考** → `C:\workspace\bst-scout`

## 按任务速查

- **当前 phase / 下一步** → SETUP-ROADMAP.md + phase1/phase2-port-plan.md。
- **port 一个 patch-group** → patch-porting.md + `/port-patch`。
- **如何验证** → validation-gate.md + instrumentation-and-tests.md。
- **统一板 / qvirt 迁移** → architecture.md §4。
- **动了 host 契约？** → host-guest-contract.md + progress/host-compat.md。
