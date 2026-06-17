---
name: docs-navigator
description: 在 bst-aosp 任何区域动手前找到对的文档——架构决策与组件角色（guest 完整 AOSP 树 / host 图形 qemu fork / 虚拟化 qvm+vbox / hd 框架）、平台策略（win 先行 mac 跟进）、两层验证（Layer 1 编译 / Layer 2 启动 oracle）、阶段模型（P0 定制清单→P1 自定义板+最小 guest→P2 镜像产出+虚拟化 port+启动验证→P3 功能对齐→P4 收尾）、定制 registry、host-guest 契约、远程构建拓扑、以及三处 host 源（qvm / app-player / app-player-dev）
---

# 文档导航器

动手前用它找到对的文档。本仓库是**本地协调/规则/registry 区**（不含 AOSP 源码），源码与编译在远程 Ubuntu 主机。先读相关文档再 grep/猜（见 `.claude/rules/research-before-action.md`）。

## 架构（仓库根）

- **[architecture.md](architecture.md)** — 完整架构决策记录。关键节：升级目标、范围边界、组件角色（kernel/goldfish-opengl/frameworks-base=guest；qemu fork=host 图形；qvm/vbox=host 虚拟化；hd=host 框架）、平台策略（win 先行）、验证策略（两层，readback）、porting 顺序、host-guest 契约、风险、待确认。
- **[architecture-brief.md](architecture-brief.md)** — 压缩版，先读它抓 gist，再读全文要 rationale。

## 验证

- **两层验证** → `architecture.md` *验证策略* + [.claude/rules/validation-gate.md](.claude/rules/validation-gate.md)（Layer 1 编译 / Layer 2 启动 oracle；时序前提：虚拟化就位）。
- **启动 oracle 取数** → [docs/boot-oracles.md](docs/boot-oracles.md)。

## 阶段与流程

- **阶段模型** → [.claude/SETUP-ROADMAP.md](.claude/SETUP-ROADMAP.md)（P0 环境就绪+定制清单→P1 自定义板+最小 guest→P2 host 镜像产出+虚拟化 port+启动验证→P3 功能对齐+两端 host 兼容→P4 收尾/CI）。
- **完成循环** → [.claude/rules/completion-loop.md](.claude/rules/completion-loop.md)（validate→checkpoint→review→fix→report）。
- **定制移植** → [.claude/rules/patch-porting.md](.claude/rules/patch-porting.md) + `/port-patch`。

## 进度与契约

- **定制 registry（权威进度）** → [patches/registry.md](patches/registry.md) / [patches/registry.json](patches/registry.json)。
- **移植时间线** → [progress/porting-log.md](progress/porting-log.md)。
- **host 兼容检查点** → [progress/host-compat.md](progress/host-compat.md) + [.claude/rules/host-guest-contract.md](.claude/rules/host-guest-contract.md)。

## 远程与构建

- **主机/路径/角色** → [docs/remote-topology.md](docs/remote-topology.md) + [.claude/rules/remote-build.md](.claude/rules/remote-build.md)。
- **构建命令/host 镜像产出** → [docs/build-commands.md](docs/build-commands.md)（host 镜像产出参考 `app-player` 脚本）。

## 三处 host 源（本地参考）

- **mac 虚拟化/图形** → `C:\workspace\qvm`（QEMU fork）。
- **win 完整 host** → `C:\workspace\app-player`（含 `hd/` 内的 `vbox`）。
- **win 最小 host** → `C:\workspace\app-player-dev`（smoke 用）。
- **开发模式参考** → `C:\workspace\bst-scout`。

## 按任务速查

- **组件角色 / qemu vs 虚拟化** → architecture.md *组件角色*。
- **如何验证一个改动** → architecture.md *验证策略* + validation-gate.md。
- **port 一个定制** → patch-porting.md + `/port-patch`。
- **远程怎么 build** → remote-build.md + `/remote-build` + docs/build-commands.md。
- **当前 phase / 下一步** → SETUP-ROADMAP.md + README.md 状态表。
- **动了 host 契约？** → host-guest-contract.md + progress/host-compat.md。
