# 规则维护（Rule Maintenance）

# 保持 .claude/ 设置准确且持续演进。规则、命令、skill 在实施中学到东西后改进。机制刻意
# **不**是「请用户审批」的手动步骤：那易遗漏，而人在环里的打断正是本项目 agentic 循环
# 要消除的交接。规则改动走与其它改动相同的可验证 gate。

## 两类改动，两条可机械化路径

**1. 机械性同步 —— 直接改，然后验证。**
- **Trigger**：一条规则/文档事实过期——失效路径、死链、错误的 phase 标签、对不上现实的文件名/count、指向已改名文件的引用。
- **Do**：在当前改动里就地修。然后**readback 验证**（`validation-gate.md` 的原则）：路径能解析、链接目标存在、陈述与目录一致。无需审批——正确性可查，那就查。
- **Doc/规则**：AOSP 特有——定制状态变化同步进 `patches/registry.md` + `registry.json` + `progress/porting-log.md`（见 `doc-update-checklist.md`）。

**2. 行为性改动 —— 落进 diff，附理由。**
- **Trigger**：碰到一个应广泛改变 agent 工作方式的模式/约束/gotcha（新规则，或对现有规则的真改动）。
- **Do**：在正常 diff 里改，并在 `.claude/summary.md` 的 **Rule changes** 下记录*改了什么、为什么*（没有它会出什么错）。然后像代码一样被 `/quick-review` 和（后续）PR gate review，而非单独的带外审批。**review 就是监督**——它用同样的机械化方式抓住坏规则改动，就像抓住坏代码改动一样。

## 为什么这契合循环

目标是廉价、独立地验证一个改动，无需每个交接都有人。手动审批 gate 两头违反：易忘（靠记忆而非检查）、且在人身上卡住循环。把规则改动走 readback + 现有 review gate，既保住监督又保住可机械化——agent 能端到端跑，review 步骤就是规则改动与其它一切一起被审视的地方。

**绝不**默默改一条 governing 规则而不留痕。痕迹（diff + **Rule changes** 注记）才让 review 成为可能——这才是真要求，不是许可提示。

## 执行，而非提醒

别靠记住这些。**Rule changes** 捕获是完成循环 checkpoint（`/save-summary`）的一步；review 它是 `/review` 的一步。当 pre-commit hook 和 reviewer agent 落地（后续阶段，见 [SETUP-ROADMAP.md](../SETUP-ROADMAP.md)），它们机械地强制 readback 和 review。
