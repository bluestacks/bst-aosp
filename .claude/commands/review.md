---
description: 有界 review→fix 循环——在新子代理跑 quick-review，机械发现自动修并回读重验，判断性发现升级
allowed-tools: Read, Grep, Glob, Edit, Agent, Bash(ssh:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(git status:*), Bash(git ls-files:*), Bash(git merge-base:*), Bash(repo status:*), Bash(repo diff:*)
---
对当前工作改动跑自动 review→fix 循环。本命令是编排器；`quick-review` 是它跑的单遍检查。设计主线：`.claude/SETUP-ROADMAP.md` → *自动 review→fix 循环*。

## 固定原则（不偏离）

- **review 在新子代理跑**，不在自己上下文——独立上下文就是 readback 路径。绝不自己审自己的 diff。
- **通过 = gate 重跑绿（readback）**，不是 reviewer 的口头确认。修完只有重验通过才算完。
- **自主边界 = 仅机械性**。自动修仅限：`#ifdef`/platform 宏漏改、fstab 字段顺序、clang-format、死 include、BoardConfig 变量 typo、init rc 语法、missing plan items。**升级（上报不修）**：dm-verity 策略、SELinux 域/标签、打包格式（APEX 等）、binder/HAL 协议、图形契约（goldfish-opengl ↔ host qemu 图形驱动）、虚拟化设备模型（`qvm`/`vbox` ↔ guest kernel）、任何改 host↔guest 契约的代码、rebase 中「语义二选一」的判断。
- **有界 + 升级**。最多 3 轮。非收敛、任何超机械边界的发现、或重验跑不起来 → 升级给人。

## Step 1 — 确定 review base

base = 本工作单元 fork 自的 ref。按阶段选择：

- AOSP16 historical port：记录的 upstream/fork point。
- AOSP16→Android-16 promotion：目标项目应用 development 内容前的 SHA。
- Android-16 mainline：`aosp16-bst` 或明确记录的工作单元 fork point。

repo 多仓库下每个受影响 project 单独确定 base，并同时审根 gitlink。
子代理自己读状态建 diff。若无 base，退回 `git diff HEAD`，并明确仅覆盖
未提交改动。

## Step 2 — 派发 review 子代理

用 **Agent** 工具（fresh 子代理，`general-purpose`）prompt：
- 传 **base ref**（或声明无），让它按 `quick-review.md` 自建 diff；
- 应用 `quick-review.md` 清单与 `.claude/rules/` 规则；
- 要求只返回**结构化 findings**——JSON 数组：
  `{ "severity": "info|warn|block", "location": "file:line", "class": "mechanical|judgment", "summary": "...", "autofixable": true|false }`

不让子代理改文件——它只审只报；修在本循环做。

## Step 3 — 分区

- **自动修集**：`class: mechanical` AND `autofixable: true` AND 在上述自主边界内。
- **升级集**：其余（`class: judgment`，或非机械的 `severity: block`，或触及架构/契约/歧义）。

## Step 4 — 施加机械修复

用 `Edit` 改自动修集。改动保持针对性。

## Step 5 — readback 重验

对改到的部分重跑 gate 并读真实结果，别假设：
- **Layer 1**（若改动需编译验证）：远程 `m <module>`，readback exit code + 产物。Phase 0 无完整 build 时降级为远程 `git apply --check` 干跑 + 冲突标注。
- **Layer 2**：按 validation-gate 时序前提（需虚拟化就位）；否则标 boot-pending，不阻塞 review 收敛判定，但登记 summary。

重验失败本身是下一轮的 finding。

## Step 6 — 循环或停

自动修集非空且 round < 3 → 回 Step 2（重审更新后的 diff）。某轮无机械发现、或到 round 3 → 停。

## Step 7 — 报告

打印：
- **跑了几轮**、是否收敛（无机械发现残留）或触顶。
- **自动修了**——每条 `file:line — 改了什么`。
- **重验**——跑的确切 gate 命令与 pass/fail（readback 证据），或「N/A — Layer 2 boot-pending / Phase 0 无 build」。
- **⚠️ 升级给你**——每个升级集 finding，附 `file:line`、为何超机械边界、建议方向。这些是人的决定，别替他们修。
- 非收敛：明说，建议人过一遍再继续。
