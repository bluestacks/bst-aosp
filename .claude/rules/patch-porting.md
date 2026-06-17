# 定制移植工作流（Patch Porting）

# 本项目核心工作单元：把 `-a13`/`-mac` BlueStacks fork 相对上游 android-13 的定制 port
# 到 android-16。跨 3 个大版本，rebase 冲突多。registry 是跨会话恢复「port 到哪了」的唯一
# 权威。

## Trigger

port 一个定制，或评估定制清单分阶段。

## 全局顺序（写进 architecture.md/plan.md）

1. **先 diff 出完整定制清单**（构建前）：自动 diff `-a13`/`-mac` fork vs 上游 android-13。
2. **评估每项阶段**：registry 标 `phase`（哪一项在 P1/P2/P3 做）。
3. **自定义板最先做**（device/board overlay，构建前提，如 `-mac` 的自定义板）。
4. 按启动依赖 port 其余：kernel → guest 图形 goldfish-opengl → frameworks-base → 其余 AOSP 仓库。
5. **最小 guest 改动集由清单评估得出**（让 android-16 能构建的最小子集）。
6. **guest 就绪后**：port 两端 `hd`（win ← `hd.git`、mac ← `hd-mac.git`）+ 图形驱动（可从 mac 分支构建）+ 虚拟化（`qvm`/`vbox`）进 host 最小实现，再 Layer 2 启动验证。

## 移植单步（`/port-patch`）

1. **识别**：从 diff 取一条定制，登记 registry `port_status=in-progress`。
2. **研究**：读 commit message + android-16 该子系统 upstream delta（research-before-action）。
3. **Rebase**：远程 `cd <project> && git checkout -b port/android-16/<id> <upstream-tag>` → `git cherry-pick` / `git apply`。
4. **冲突**：机械冲突（上下文漂移、include 路径、platform 宏）自动解；**语义冲突**（upstream 改了语义、二选一）→ escalate 并记 `conflict_resolution`。
5. **Layer 1**：远程 `m <module>`，readback exit code + 产物。
6. **记录**：更新 registry（status / conflicts / resolution / verified_layers）+ 追加 `progress/porting-log.md`。
7. **副本**：`scp` 远程 patch 回 `patches/<area>/<id>.patch`，verify-by-readback 与远程 commit diff 一致。

## registry 字段（`patches/registry.json`）

`base_from=android-13`（`-a13`/`-mac` fork）、`base_to=android-16.0.0_r4`、按 `platform`(mac/win) 分组；每条：`id`、`area`、`source_commit`、`project_path`、`summary`、`port_status`(pending/in-progress/ported/blocked/dropped)、`phase`、`port_branch`、`review_base`、`conflicts`、`conflict_resolution`、`verified_layers`、`host_compat`(unknown/ok/broken)、`owner`、`notes`。

## 接缝原则（来自 simplify-as-you-go）

定制优先落在 device/vendor 层（device overlay / `init.<board>.rc` / `fstab` / BoardConfig），**而非**上游框架主干。主干保持 upstream 干净——直接决定后续 rebase 痛苦度。
