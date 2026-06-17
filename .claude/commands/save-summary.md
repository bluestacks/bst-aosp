---
description: checkpoint——保存计划 + 实施摘要，作为 review 的轨迹
allowed-tools: Write, Read
---
这是完成循环（`.claude/rules/completion-loop.md`）的 **checkpoint** 步。循环自动跑它；人只在逃生时手动调——例如压缩长会话前先存状态。

先，若接受的计划还没在 `.claude/plan.md`，全文写入（所有阶段、需求、验收标准，不截断）。

然后基于刚实施的，写简明实施摘要到 `.claude/summary.md`，含：

- **实施了什么**（按远程相对路径列 changes，注明 project）。
- **Patch identity** — 本单元 port 的定制 id（对应 `patches/registry.json` 条目）、源 commit（`-a13`/`-mac` fork，android-13）、目标（android-16）、platform（win/mac）。
- **Conflict resolution** — rebase/cherry-pick 遇到的冲突、如何解（保留 BlueStacks 语义 vs 采用 upstream）、为何。
- **Upstream delta** — android-13→16 间该子系统 upstream 变了什么（影响本次难度）。
- **关键决策** — 实施中的决策、偏离计划处及原因。
- **已知限制 / TODO**。
- **新增依赖**（BUILD.bp/Android.bp/manifest 项）。
- **如何验证** — 哪些 gate 命令跑了且过：Layer 1（命令 + exit code + 产物路径 + mtime）、Layer 2（哪些 oracle 跑了、结果片段）。用 readback 证据表述，不用「应该行」。boot-pending 显式标注。
- **host-compat status** — 本变更后 host（mac `qvm` / win `app-player-dev`）是否仍兼容（见 `progress/host-compat.md`）。
- **Session context** — 非显然决策、试过放弃的方案、边界情况、reviewer/未来会话需要的细节。防会话间丢上下文。
- **Rule changes** — 本会话改的任何规则/文档（及原因），以及应改规则但还没改的模式/gotcha。按 `rule-maintenance.md`，行为性规则改动落进 diff 像代码一样被 review——这条注记是让该 review 成为可能的痕迹。无则省略。
