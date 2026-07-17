---
description: 移植一个 patch-group——识别→研究→rebase→文档→验证回环→存 patch→checkpoint
allowed-tools: Bash(ssh:*), Bash(scp:*), Read, Write, Edit, Agent, Grep, Glob, WebFetch, WebSearch
---
port 一个 **patch-group**（关联定制）到 android-16，按 `.claude/rules/patch-porting.md`。

## 步骤

1. **识别组**：从 `patches/registry.json` 取一个 `related_group`（如 `G1`），列出组内条目；全部标 `port_status=in-progress`。确认 `unify_group` / `platform` / `temp_debt`。

2. **研究**（research-before-action + dual-platform）：
   ```bash
   ssh markxu@172.16.6.191 'cd <tree>/<project> && git show <source_commit> --stat'
   ```
   读 message + diff；查 android-16.0.0_r4 该子系统 upstream delta。填写 `purpose` / `quality` / `impact`。

3. **移植（fork-diff overlay，非逐 commit）**：大定制项禁止 220 次 cherry-pick。
   ```bash
   # 取 fork 相对上游 android-13 的整包 diff（子路径可选）
   ssh markxu@172.16.6.191 'cd ~/app-player/android-13/<project> && git diff <base_tag>..HEAD -- <subpath> > /tmp/<id>.patch'
   # 落到 a16 对应 project 的 android-16 base 上
   ssh markxu@172.16.6.191 'cd ~/aosp16/<project> && git checkout -b port/android-16/<group-id> <a16-base> && git apply --3way /tmp/<id>.patch'
   ```
   Phase 1 只取 boot-minimal 子集（对齐 `boot-*` 存量），其余 hunk → Phase 2。平台特有用 BoardConfig / product / `#ifdef` 隔离。机械冲突自解；语义冲突 → escalate，`conflict_resolution` + `blocked`。commit 级 cherry-pick 仅用于单一小定制。

4. **埋点 + 测试**：加入 `A16DBG:` 埋点与断言（`.claude/rules/instrumentation-and-tests.md`）。

5. **验证回环**：
   - Layer 1：`/remote-build`，readback exit code + 产物。不过 = 阻塞。
   - Layer 2：并入 boot 镜像时跑 boot 回归 oracle（M1 `RESTORE.md` §7 / `G1-RESTORE.md` §6）。相关组可批量后一次 Layer 2。

6. **文档**：更新 registry 字段 + 追加 `progress/porting-log.md`（原 patch 信息、用途、质量、影响、验证证据）。

7. **存 patch + checkpoint**：
   ```bash
   scp markxu@172.16.6.191:<remote-diff.patch> patches/android-16/patches/
   ```
   untracked → `untracked-src/`；写/更新 `checkpoint_ref`（可指向 `RESTORE.md` 节或 `patches/android-16/checkpoints/<group>.md`）。verify-by-readback：本地 patch 与远程 diff 一致。

8. **完成循环**：`/save-summary` → `/review`（review base = 开分支时的 upstream）→ report。

## 接缝

定制优先 device/vendor；`temp_debt` 不在本组「根治」除非清单有对应真定制。win 验证 / mac 同码见 `platform-win-first-mac-reuse.md`。
