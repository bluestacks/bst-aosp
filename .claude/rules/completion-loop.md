# 完成循环（Completion Loop）

# 当一个工作单元（一个定制 port / 一个 phase / 一个修复）完成时，agent 自行跑完
# verify → checkpoint → review → fix 循环。人类只在两点介入：实施前的计划接受、以及
# 循环升级（escalation）上来的事项。不需要人手动敲命令推进循环——那会重新插回本项目
# 要消除的「易遗漏的交接」。

## 完成一个工作单元时

按顺序自动跑，不等被催：

1. **Validate** — `validation-gate.md` 的两层（Layer 1 远程编译 + Layer 2 启动 readback）。注意时序：Phase 1 仅 Layer 1；Layer 2 需虚拟化就位（Phase 2 起）。按 readback 验证，别假设改对了。
2. **Checkpoint** — 写/刷新 `.claude/summary.md`（若接受的计划还没存，先写 `.claude/plan.md`），按 `/save-summary`。这是 review 读取的轨迹，也是日后 PR 的依据。
3. **Review→fix** — 跑 `/review`，传入本工作单元的 **review base**（开分支时的 fork 来源，见 `CLAUDE.md` 的「每工作单元开独立分支」）。新子代理对整条分支 vs base diff 审查；机械发现自动修并重验，≤3 轮。
4. **Report** — 「converged + verified」（附 readback 证据），或升级清单。

## 唯一强制的人类介入点

- **计划接受** — 实施前（plan mode → accept）。
- **升级（escalation）** — 判断性发现（架构、公共接缝/IPC/host-guest 契约、歧义下的正确性）与达到轮次上限仍未收敛。循环**呈现**这些，**不**自行修。这是 `/review` 的「仅机械性自主」边界。

两点之间的一切都由 agent 端到端跑。别停下来问「现在要 review 吗」——跑 review 是默认，停才是例外。

## AOSP 特别说明

- **长任务**：远程 build 可能数小时。Validate 的 Layer 1 发起后台任务后即可继续 checkpoint/review 准备；用 `CronCreate` 周期轮询，完成回读后才算 Validate 过。
- **boot-pending**：Layer 2 因耗时本会话跑不完时，summary 标 `verification: build-only, boot-pending` 并登记 `progress/`；循环可对 Layer 1 收敛，但必须显式上报 Layer 2 未闭环。

## 手动调用仍然可用

slash 命令（`/review`、`/quick-review`、`/save-summary`、`/remote-build`、`/port-patch`、`/boot-verify`）可单跑某一阶段——例如实施中途的一次性 review，或在压缩长会话前 `/save-summary` checkpoint。它们是循环的构件，不是人必须记得敲的清单。
