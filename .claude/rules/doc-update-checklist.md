# 文档更新清单（Doc Update Checklist）

# 随项目推进保持已有文档同步的单一事实源。在完成循环（checkpoint 和 `/review` 步骤）里对
# diff 机械执行——是对改动跑的清单，不是手动步骤。

## 何时更新

- **定制状态变化**（pending→ported / blocked / dropped）→ 更新 `patches/registry.md` + `patches/registry.json` + `progress/porting-log.md`。
- **base ref / manifest revision 变化**（如跟进 android-16 r5）→ 更新 `architecture.md` + `docs/remote-topology.md` + `CLAUDE.md`。
- **新增一条 boot oracle**（新取数方式/新异常态）→ 更新 `docs/boot-oracles.md` + `.claude/rules/validation-gate.md` 的 oracle 引用。
- **host-guest 契约面变化**（新契约项/契约破坏决策）→ 更新 `progress/host-compat.md` + `.claude/rules/host-guest-contract.md`。
- **远程主机/路径/构建命令落实**（Phase 0 确认）→ 更新 `docs/remote-topology.md` + `docs/build-commands.md` + `.claude/settings.json` allowlist。
- **阶段推进**（Phase 0→1→…）→ 更新 `CLAUDE.md`（当前 Phase）+ `.claude/SETUP-ROADMAP.md` 勾选 + `README.md` 状态表。
- **新增/删除 `.claude/` 规则或命令** → 更新 `CLAUDE.md` 与 `docs-navigator` 的相关引用。

## 约定

- **只做针对性编辑**——不整文件重写；改 diff 需要的。
- **链接 readback 验证**——文档引用路径/文件时，确认目标存在（别信任它存在）。同一改动里修坏引用。
- **顺手修经过的坑**——读文档发现过期 phase 标签、死链、错交叉引用，顺手修；别留已知坑。
- **无操作是合法结果**——本清单无项适用时，明说并继续。

## 如何应用

在完成循环的 checkpoint 和 review 步骤，对 `git diff`（+ 新增未跟踪文件）跑此清单。编辑前先读文档。这些编辑落进正常 diff，与其它改动同方式验证——见 [rule-maintenance.md](rule-maintenance.md) 为何它替代手动审批步骤。
