# CLAUDE.md

本文件为 Claude Code（claude.ai/code）在本仓库工作时提供指引。**先读此文件。**

> ⚠️ **本仓库不含可编译的 AOSP 源码。** `bst-aosp` 是**本地协调 / 文档 / 规则 / patch registry 区**。
> guest 源码与编译都在**远程 Ubuntu 主机**上，所有 build/test 经 `ssh <host>` 远程执行。
> 本地只持有：脚手架（`.claude/`）、文档（`docs/`、`architecture*.md`）、patch 副本与 registry（`patches/`）、进度记录（`progress/`）。

## 这个项目是什么

**Windows + ARM64 Mac 的 Android 模拟器**。本仓库的目标：把 Android **guest 从 android-13 升级到 android-16**（base ref `android-16.0.0_r4`）。**AI 主导、人类辅助**，开发模式参考 [bst-scout](../bst-scout)（详见 [architecture.md](architecture.md)）。

**核心原则（继承自 bst-scout，内化于心）**：

> **通过独立回读路径验证效果，绝不信任发起变更那次调用返回的确认。**
> （Verify by readback, not by acknowledgement.）—— `m` 跑完没报错 ≠ 构建成功；构建成功 ≠ 能启动；能启动 ≠ host 能跑。每一步都要用独立取数证据确认。

### 组件 / 仓库 / 分支清单（权威）

| 组件（角色） | mac（branch `bst-v5.21.700-nxt_mac2`） | win（branch `bst-v5.22.210-5.22.210.1033`） |
|---|---|---|
| guest kernel | `kernel-mac.git` | `kernel-common-a13.git` |
| guest 图形（goldfish-opengl） | `ggl-goldfish-opengl-mac.git` | `ggl-goldfish-opengl-pie.git` |
| guest 框架（frameworks-base 等，完整 AOSP 树） | `…-mac.git`（`-mac` 后缀） | `…-a13.git`（`-a13` 后缀） |
| host 图形驱动（qemu fork，**非虚拟化**） | `ggl-external-qemu-mac.git` | `qemu.git` |
| host 框架（hd） | `hd-mac.git` | `hd.git` |
| host 虚拟化（VMM） | `qvm`（mac） | `vbox`（位于 `app-player` 的 `hd/` 内） |

- `-a13` 与 `-mac` 仓库**均基于 android-13**；大部分 AOSP repo 通过后缀不同指向 BlueStacks fork。
- **guest = 完整 AOSP 树**（android-16.0.0_r4，**从拉代码 `repo init`/`sync` 做起**）。guest 图形 = goldfish-opengl。
- **host 图形驱动 = qemu fork**（非虚拟化，可从 mac 分支代码构建）；**host 虚拟化 = mac `qvm` / win `vbox`**；`hd` = host 框架。
- 本地参考目录：host 图形/虚拟化源 = `C:\workspace\qvm`（mac）、`C:\workspace\app-player`（win 完整）/ `C:\workspace\app-player-dev`（win 最小）；开发模式 = `C:\workspace\bst-scout`。

### 分层（架构主线）

1. **guest（android-16.0.0_r4 完整 AOSP 树，两端统一）**，图形基于 goldfish-opengl，**win 先行、mac 跟进**。
2. **host 图形驱动 = qemu fork**（可从 mac 分支代码构建），**host 虚拟化两端各异** = mac `qvm` / win `vbox`（`app-player` 的 `hd/` 内），`hd` 为 host 框架（win ← `hd.git`、mac ← `hd-mac.git`）。
3. **host 非虚拟化两端统一。**

升级主线是 guest（port `-a13`/`-mac` 定制到 android-16），**并触发 host 适配**——当前最小范围含两端 `hd` + 图形驱动，虚拟化后续纳入。

## 当前阶段

**Phase 0 — 环境就绪 + 定制清单（构建前）。** 远程主机能连、完整 AOSP 树从拉代码做起、**构建前先 diff 出定制清单并评估分阶段**、vanilla android-16 能构建。详见 [.claude/SETUP-ROADMAP.md](.claude/SETUP-ROADMAP.md)。

## Build / test / verify（远程形态）

两层验证（详见 [.claude/rules/validation-gate.md](.claude/rules/validation-gate.md)）：

**Layer 1 — 编译验证（远程，完整 AOSP 树）**
```bash
ssh <host> 'cd <remote-root> && bash -lc "source build/envsetup.sh && lunch <target> && m <module>"'
# 全量镜像: m dist → out/dist/*.img；迭代清理: installclean
```
回读：真实 exit code（`echo $?`）+ 产物 `ls -la out/target/product/<device>/*.img`。

**Layer 2 — 启动/行为 readback oracle 套件**（需 host 最小实现已 port 入虚拟化后才能跑；详见 [docs/boot-oracles.md](docs/boot-oracles.md)）：kernel boot log、分区 by-name symlink、动态分区创建、分区挂载、init rc 解析、SELinux 域转换、vbmeta/verity、bootanim→launcher。

> **时序前提**：guest 构建就绪 ≠ 可启动验证。Phase 1 仅达 Layer 1；Phase 2 才 port 虚拟化进 host 最小实现并做 Layer 2。

## Working agreement

- **构建前先出定制清单。** 自动 diff `-a13`/`-mac` fork vs 上游 android-13 找出定制，评估每项应在哪个阶段做（写入 `patches/registry.json`，标 phase）。见 [.claude/rules/patch-porting.md](.claude/rules/patch-porting.md)。
- **自定义板先做。** device/board overlay 是构建前提（如 `-mac` 添加的自定义板），先于其余定制。
- **每工作单元开独立分支**，记住 fork 来源作为 review base，传给 `/review`。
- **完成循环自动跑完**：validate → checkpoint → review→fix → report；人类只在「计划接受」和「escalation」介入。见 [.claude/rules/completion-loop.md](.claude/rules/completion-loop.md)。
- **Research before action**：先读权威源（上游 AOSP 源码、`-a13`/`-mac` fork 定制、`app-player` 编译脚本），再 grep/猜测。见 [.claude/rules/research-before-action.md](.claude/rules/research-before-action.md)。
- **机械性自主、契约/歧义升级**：dm-verity/SELinux/打包/binder-HAL/图形契约/虚拟化设备模型/rebase 语义判断 → escalate，不自行修。见 [.claude/commands/review.md](.claude/commands/review.md)。
- **host-guest 契约**：guest 升级绝不静默破坏 host（mac `qvm` / win `app-player`+`vbox`）。见 [.claude/rules/host-guest-contract.md](.claude/rules/host-guest-contract.md)。
- **远程长任务必须后台化 + log 落盘**（nohup + PID + log 路径），断线靠 `ps -p <pid>` + `tail <log>` 恢复。见 [.claude/rules/remote-build.md](.claude/rules/remote-build.md)。
- **文档/规则随改随同步**：机械性过期（路径/链接/phase 标签）直接改并回读验证；行为性规则改动落进 diff 并在 summary 记 Rule changes。见 [.claude/rules/rule-maintenance.md](.claude/rules/rule-maintenance.md)。

## Commands

完成循环的构件（也可手动单跑）：

- `/review` — 有界 review→fix 循环：新子代理审 diff，机械发现自动修并回读重验，判断性发现升级，≤3 轮。
- `/quick-review` — `/review` 在子代理里跑的单遍检查清单。
- `/save-summary` — checkpoint：写 `.claude/plan.md` + `.claude/summary.md`（AOSP 字段：定制 id、源 commit、冲突解决、upstream delta、verification、host-compat）。
- `/remote-build` — 远程 lunch + m，后台化 + 回读日志/exit code/产物。
- `/port-patch` — 识别（diff 取一条定制）→ 研究 → rebase → 记冲突 → 更新 registry。
- `/boot-verify` — 取 kernel/串口 log，跑 Layer 2 oracle 套件。

## Where things live

| 主题 | 文件 |
|---|---|
| 架构决策记录 | [architecture.md](architecture.md) / [architecture-brief.md](architecture-brief.md) |
| 验证策略（两层） | [architecture.md](architecture.md) + [.claude/rules/validation-gate.md](.claude/rules/validation-gate.md) |
| 升级阶段模型 | [.claude/SETUP-ROADMAP.md](.claude/SETUP-ROADMAP.md) |
| 定制 registry（权威进度） | [patches/registry.md](patches/registry.md) / [patches/registry.json](patches/registry.json) |
| 移植时间线 | [progress/porting-log.md](progress/porting-log.md) |
| host 兼容检查点 | [progress/host-compat.md](progress/host-compat.md) |
| 远程主机/路径/构建命令 | [docs/remote-topology.md](docs/remote-topology.md) / [docs/build-commands.md](docs/build-commands.md) |
| 启动 readback oracle | [docs/boot-oracles.md](docs/boot-oracles.md) |
| 文档导航器 | `docs-navigator` skill（[.claude/skills/docs-navigator/SKILL.md](.claude/skills/docs-navigator/SKILL.md)） |
| Agent 规则 | [.claude/rules/](.claude/rules/) |
