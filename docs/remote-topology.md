# 远程拓扑（Remote Topology）

> SSH 主机 / 远程路径 / 构建机角色。**Phase 0 待填**（确认远程 Ubuntu 主机后）。出厂 settings.json 不含硬编码主机——本文件确认后，把 `<host>` 加入 `.claude/settings.json` 的 allow。

## 待确认（Phase 0）

- [ ] 远程 Ubuntu 主机地址 / 用户 / 端口 / 密钥（候选见 `~/.ssh/config`）。
- [ ] AOSP checkout 根路径 `<remote-root>`。
- [ ] 磁盘是否够完整 AOSP 树（~数百 GB + out/）。

## 构建机角色（待填）

| 角色 | 主机 | 远程路径 | 备注 |
|---|---|---|---|
| guest AOSP 全量构建 | `<host>` | `<remote-root>` | `repo init`/`sync` + `lunch` + `m` |
| host 构建（win） | 本地 `C:\workspace\app-player` / `app-player-dev` | — | CMake/MSBuild |
| host 构建（mac） | 本地/远程 `qvm` | — | QEMU fork 构建 |
| 调试/启动 | `<host>` 或本地 | — | Layer 2 boot oracle（需虚拟化就位） |

## SSH 用法约定（见 rules/remote-build.md）

- 长任务 `nohup ... > <log> 2>&1 & echo $!`，记 PID + log。
- `envsetup` + `lunch` 在同一 `bash -lc`。
- 断线恢复：`ps -p <pid>` + `tail <log>`。
