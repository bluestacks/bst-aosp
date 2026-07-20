# 定制移植工作流（Patch Porting）

# 核心工作单元 = **patch-group**（关联定制一起移植）。把 `-a13`/`-mac` 相对上游
# android-13 的定制 port 到 android-16；跨 3 大版本冲突多。registry v2 是跨会话
# 恢复的唯一权威。每组须：完整验证回环 + 详细文档 + 存 patch + 可恢复 checkpoint。

## Trigger

port 一个 patch-group，或评估清单分阶段。

## 全局顺序

1. **双端清单重生成 + 统一分析**（`dual-platform-customization.md`）。
2. **boot 存量映射**（`patches/android-16/` → registry，标 `temp_debt`）。
3. **Phase 1**：融合（临时 boot patch + 清单最小 patch），统一板 `device/bst/qvirt` 最先（G1）。
4. **Phase 2**：其余按优先级；关联组一起移植；临时债真实修复。
5. **mac**：win 验证通过后基于同份代码开发（`platform-win-first-mac-reuse.md`）。

## 移植机制：fork-diff overlay（**不做 220 次 cherry-pick**）

registry 多为**项目级**条目（无单一 `source_commit`）。大定制项（如 `frameworks/base` win bst=220）**禁止**逐 commit cherry-pick——冲突面爆炸、不可收敛。统一走 **fork-diff overlay**：

1. 定 base：fork 分支相对的**上游 android-13 tag**（registry `base_tag`）。
2. 取整包 diff：`git -C <fork> diff <base_tag>..HEAD -- <子路径>` = 该项全部定制。
3. 在 a16 对应 project `git checkout <android-16 base>`，`git apply`/`3way` 落 overlay。
4. **切最小子集**：Phase 1 只取 boot-minimal 子路径/hunk（对齐 `boot-*` 存量）；其余 hunk 归 Phase 2。
5. 冲突：机械自解；语义 → escalate。
6. 存 patch = 该 overlay 的 `git diff HEAD`（与 M1 `patches/android-16/patches/aosp16__*.patch` 同形态）。

commit 级 cherry-pick **仅**用于「单一小定制、需保留作者/message」的场景。

## 移植单步（`/port-patch`）——以 group 为单位

1. **识别组**：从 registry 取一个 `related_group`（如 G1），组内所有 `port_status=pending` 项标 `in-progress`。
2. **研究**：每项读源 commit message + android-16 upstream delta；写**用途**；评估**质量**与**影响**（见下方文档模板）。
3. **统一 / 平台区分**：`platform=both` 落共享路径；`win`/`mac` 特有用 product/BoardConfig/`#ifdef` 隔离。
4. **Rebase**：远程开 `port/android-16/<group-id>`；cherry-pick / apply；机械冲突自解，语义冲突 → escalate + `conflict_resolution`。
5. **埋点 + 测试**：按 `instrumentation-and-tests.md` 加入 `A16DBG:` 与断言。
6. **验证回环**：
   - Layer 1 强制（`/remote-build`，readback exit + 产物）。
   - Layer 2：本组改动并入 boot 镜像时跑 boot 回归 oracle；相关组可批量并入后一次 Layer 2（保留每组 Layer 1 证据）。
7. **文档**：在 `progress/porting-log.md` + registry 字段写完整说明（模板见下）。
8. **存 patch + checkpoint + 合规 commit**（见 [change-compliance.md](change-compliance.md)）：
   - **远程各 project git commit**（合规 message：source/temp_debt/A16DBG/verification/可恢复），清 `.bak` 噪音。
   - **重生成本地 patch** 从 `git diff <base>..HEAD` → `patches/android-16/patches/aosp16__<project>.patch`；untracked scaffold 进 `untracked-src/`。
   - **验证一致**：远程 commit diff == 本地 patch（字节级，干净 aosp16 git apply 可恢复）。
   - 更新 `RESTORE.md` 式说明或 group 的 `CHECKPOINT.md`，使**仅凭存档可恢复到本组验证通过态**。
   - registry：`port_status=ported`、`verification`、`checkpoint_ref`、`host_compat`、`temp_debt`、`boot_artifact`。
9. **完成循环**：validate → checkpoint（`/save-summary`）→ `/review`（对每条改动跑 [change-compliance.md](change-compliance.md) 5 条清单）→ report。

## 每组文档模板（必填）

| 字段 | 含义 |
|---|---|
| 原 patch 信息 | `source_commit`、仓库/`project_path`、fork（win/mac）、upstream tag |
| 用途 | 解决什么问题 / 提供什么能力（一行意图 + 细节） |
| 质量评估 | 清晰度、是否应落 device 层、是否含 hack、`temp_debt`？ |
| 影响评估 | 构建面、启动面、host-guest 契约、与其他组依赖 |
| 验证 | Layer1/Layer2 命令 + readback 证据 |
| checkpoint_ref | 存档路径（patch 文件 / RESTORE 节） |

## registry 字段（v2）

见 `patches/registry.schema.md`。关键：`unify_group`、`platform`、`related_group`、`temp_debt`、`source_commit`、`purpose`、`quality`、`impact`、`verification`、`checkpoint_ref`、`phase`、`port_status`、`host_compat`。

## 接缝原则

定制优先落在 device/vendor 层（device overlay / `init.<board>.rc` / `fstab` / BoardConfig），**而非**上游框架主干。临时 bypass 必须标 `temp_debt=true` 并挂 Phase 2 收口项。
