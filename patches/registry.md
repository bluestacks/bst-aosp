# 定制 Registry

把 `-a13`（win）/`-mac`（mac）BlueStacks fork 相对**上游 android-13** 的定制，port 到 **android-16.0.0_r4** 的权威进度表。机器可读同数据：[registry.json](registry.json)。

- **base_from**：android-13（`-a13`/`-mac` fork）
- **base_to**：android-16.0.0_r4
- **平台**：win 先行、mac 跟进
- **初始定制集**：Phase 0 由**自动 diff fork vs 上游 android-13** 导入。

## 定制表

> 占位——Phase 0 diff 导入后填充。每行一条定制。

| id | platform | area | summary | phase | port_status | verified_layers | host_compat | notes |
|---|---|---|---|---|---|---|---|---|
| _（待 Phase 0 导入）_ | | | | | | | | |

## 字段说明（registry.json 每条 patch）

| 字段 | 含义 |
|---|---|
| `id` | 定制标识（如 `kernel-0001-<slug>`） |
| `platform` | `win` / `mac` |
| `area` | 子系统（kernel / goldfish-opengl / frameworks-base / device-overlay / ...） |
| `project_path` | 远程 AOSP project 路径 |
| `source_commit` | `-a13`/`-mac` fork 上的源 commit |
| `summary` | 一句话定制意图 |
| `phase` | 该项应在哪个阶段做（P1/P2/P3） |
| `port_status` | `pending` / `in-progress` / `ported` / `blocked` / `dropped` |
| `port_branch` | 远程 port 分支（`port/android-16/<id>`） |
| `review_base` | upstream ref（android-16.0.0_r4 在该 project 的 commit） |
| `conflicts` | rebase 冲突清单 |
| `conflict_resolution` | 冲突如何解（保留 BS 语义 vs 采用 upstream）+ 原因 |
| `verified_layers` | `[]` / `["build"]` / `["build","boot"]` |
| `host_compat` | `unknown` / `ok` / `broken` |
| `owner` | `agent` / `human` |
| `notes` | 备注 |

## 顺序约束（来自 patch-porting 规则）

1. 自定义板（device/board overlay）最先（构建前提）。
2. kernel → guest 图形 goldfish-opengl → frameworks-base → 其余 AOSP 仓库。
3. guest 就绪后：两端 `hd` + 图形驱动 + 虚拟化进 host 最小实现。
