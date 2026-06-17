---
description: 移植一条定制——diff 识别→研究→rebase→记冲突→更新 registry
allowed-tools: Bash(ssh:*), Bash(scp:*), Read, Write, Edit, Agent, Grep, Glob, WebFetch, WebSearch
---
port 一条 BlueStacks 定制到 android-16，按 `.claude/rules/patch-porting.md`。

## 步骤

1. **识别**（diff 取一条定制）：对某 project，diff `-a13`/`-mac` fork vs 上游 android-13，取一条尚未 port 的定制：
   ```bash
   ssh <host> 'cd <remote-root>/<project> && git log --oneline <upstream-android-13-tag>..<fork-branch>'
   ```
   选一条，记 `source_commit`；在 `patches/registry.json` 登记 `port_status=in-progress`、`area`、`project_path`、`phase`。

2. **研究**（research-before-action）：读该 commit 的 message + diff；查 android-16 该子系统 upstream delta（`cs.android.com` / `android.googlesource.com` 按 `android-16.0.0_r4`）。判断定制意图与 android-16 是否仍需。

3. **Rebase**：
   ```bash
   ssh <host> 'cd <remote-root>/<project> && git checkout -b port/android-16/<id> <upstream-android-16-tag> && git cherry-pick <source_commit>'
   # 或 git apply <patch>
   ```
   记 `port_branch`、`review_base=<upstream-android-16-tag>`。

4. **冲突**：机械冲突（上下文漂移、include、platform 宏）自动解；**语义冲突**（upstream 改了语义、二选一）→ **escalate**，把决策与原因记 `conflict_resolution`，`port_status=blocked`。

5. **Layer 1**（readback）：`/remote-build` 远程 `m <module>`，读 exit code + 产物。Layer 1 不过 = 下一步阻塞。

6. **记录**：更新 `patches/registry.json` + `registry.md`（status / conflicts / resolution / verified_layers=build）+ 追加 `progress/porting-log.md`。

7. **副本**：`scp` 远程 `git show <commit>` patch 回 `patches/<area>/<id>.patch`，verify-by-readback 与远程 diff 一致。

## 接缝

定制优先 device/vendor 层（device overlay / init rc / fstab / BoardConfig），非上游主干。每步遵循完成循环（validate→checkpoint→review→report）。
