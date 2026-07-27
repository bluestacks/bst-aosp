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

**Phase 2 — guest 全量功能对齐（唯一活跃阶段；不规划 host/Phase 3）。**  
绿基线：D8+D9 Root.vhd **`02690d11`**（system.img `a878d3c8`）Layer2 **7/7 @161s**（cont.101）。**22/22** core/java ✅；services/core gap 持续收口；**deferred 8/9 done**（D1/D2/D5/D6/D7/D8/D9 + ActiveServices；仅 D3 截图 defer 到虚拟化 port 阶段）。frameworks/base source-vs-commit drift 已清零（全 commit）。  
SELinux：**对齐 a13 强制 permissive**。Shell Transitions：已补 **`performance_hint`** HAL，r262 **removed**。  
详见 [.claude/SETUP-ROADMAP.md](.claude/SETUP-ROADMAP.md) · [phase2-port-plan](progress/phase2-port-plan.md) · [porting-log](progress/porting-log.md)。

## Build / test / verify（远程形态）

两层验证（详见 [.claude/rules/validation-gate.md](.claude/rules/validation-gate.md)）：

**Layer 1 — 编译验证（远程，完整 AOSP 树）**
```bash
ssh <host> 'cd <remote-root> && bash -lc "source build/envsetup.sh && lunch <target> && m <module>"'
# 全量镜像: m dist → out/dist/*.img；迭代清理: installclean
```
回读：真实 exit code（`echo $?`）+ 产物 `ls -la out/target/product/<device>/*.img`。

**Layer 2 — 启动/行为 readback oracle 套件**（需 host 最小实现已 port 入虚拟化后才能跑；详见 [docs/boot-oracles.md](docs/boot-oracles.md)）：kernel boot log、分区 by-name symlink、动态分区创建、分区挂载、init rc 解析、SELinux 域转换、vbmeta/verity、bootanim→launcher。

> **时序**：Phase 1 起 win 路径 Layer 2 已可用（M1 boot 后）；mac 不做独立验证。详见 [.claude/SETUP-ROADMAP.md](.claude/SETUP-ROADMAP.md)。

## Working agreement

- **双端定制清单 + 有意识统一。** diff `-a13`/`-mac` vs 上游 android-13；同一定制归 `unify_group`；平台特有加平台区分。见 [.claude/rules/dual-platform-customization.md](.claude/rules/dual-platform-customization.md)。
- **统一板先做。** `device/bst/qvirt`（`bst_x86_64` / `bst_arm64`）是构建前提；arch 差异下沉 BoardConfig。
- **工作单元 = patch-group**（关联 patch 一起移植）；每组全验证回环 + 文档（源/用途/质量/影响）+ 存 patch + checkpoint。见 [.claude/rules/patch-porting.md](.claude/rules/patch-porting.md)。
- **win 先行验证；mac 基于同码、不做独立验证。** 见 [.claude/rules/platform-win-first-mac-reuse.md](.claude/rules/platform-win-first-mac-reuse.md)。
- **每次修改加埋点 + 测试。** 见 [.claude/rules/instrumentation-and-tests.md](.claude/rules/instrumentation-and-tests.md)。
- **完成循环自动跑完**：validate → checkpoint → review→fix → report；人类只在「计划接受」和「escalation」介入。见 [.claude/rules/completion-loop.md](.claude/rules/completion-loop.md)。
- **Research before action**：先读权威源，再 grep/猜测。见 [.claude/rules/research-before-action.md](.claude/rules/research-before-action.md)。
- **机械性自主、契约/歧义升级**：dm-verity/SELinux/打包/binder-HAL/图形契约/虚拟化设备模型/rebase 语义判断 → escalate。见 [.claude/commands/review.md](.claude/commands/review.md)。
- **host-guest 契约**：guest 升级绝不静默破坏 host。见 [.claude/rules/host-guest-contract.md](.claude/rules/host-guest-contract.md)。
- **远程长任务必须后台化 + log 落盘**。见 [.claude/rules/remote-build.md](.claude/rules/remote-build.md)。
- **文档/规则随改随同步**。见 [.claude/rules/rule-maintenance.md](.claude/rules/rule-maintenance.md)。

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
