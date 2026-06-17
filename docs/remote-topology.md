# 远程拓扑（Remote Topology）

> Phase 0 探测（2026-06-17）已填实。密码**不**写入本仓库；认证用本地 `~/.ssh/id_ed25519`（已安装到远程 `authorized_keys`，原生 ssh 免密）。

## 远程主机（已确认）

| 项 | 值 |
|---|---|
| 地址 | `markxu@172.16.6.191`（hostname `clouddev`） |
| 系统 | Ubuntu 22.04.5 LTS（kernel 5.15.0-176-generic） |
| 用户 | markxu |
| 认证 | 公钥 `~/.ssh/id_ed25519`（zeqing.xu@bluestacks.com），已装 authorized_keys |
| 大盘 | `/home/clouddev/bst/workspace`（sdb，7.3T，2.6T 可用）—— 够完整 AOSP 树 |
| HOME | `/home/clouddev/bst/workspace/markxu` |
| 工具 | repo 2.40、git 2.34.1 |

## 已有 checkout（HOME 下）

- `~/kernel-common-a13/` — remote `git@github.com:bluestacks/kernel-common-a13.git`，分支 **`aosp13-sync`**（win guest kernel，android-13）。
- `~/kernel-mac/` — remote `git@github.com:bluestacks/kernel-mac.git`，分支 **`bst-v5.0.0-nxt_mac2`**（mac guest kernel）。

## 构建机角色

| 角色 | 主机 | 路径 | 备注 |
|---|---|---|---|
| guest AOSP 全量构建 | `markxu@172.16.6.191` | `<remote-root>` 待定（HOME 下，待 `repo init`） | 完整 AOSP 树**尚未拉取** |
| guest kernel 构建 | 同上 | `~/kernel-common-a13`（win）/ `~/kernel-mac`（mac） | 已 checkout |
| host 构建（win） | 本地 `C:\workspace\app-player` / `app-player-dev` | — | CMake/MSBuild |
| host 构建（mac） | 本地/远程 `C:\workspace\qvm` | — | QEMU fork |
| 调试/启动 | 远程 + 本地 | — | Layer 2 boot oracle（需虚拟化就位） |

## SSH 用法约定（见 ../.claude/rules/remote-build.md）

- 用法：`ssh markxu@172.16.6.191 '...'`（已免密）。
- 长任务 `nohup ... > <log> 2>&1 & echo $!`，记 PID + log。
- `envsetup` + `lunch` 在同一 `bash -lc`。
- 断线恢复：`ssh markxu@172.16.6.191 'ps -p <pid>; tail -n 50 <log>'`。

## ⚠️ 分支出入（待确认）

- 用户给的 win 产品分支 `bst-v5.22.210-5.22.210.1033`，但 `kernel-common-a13` 实际在 **`aosp13-sync`**。
- 用户给的 mac 分支 `bst-v5.21.700-nxt_mac2`，但 `kernel-mac` 实际在 **`bst-v5.0.0-nxt_mac2`**。
- → kernel 仓库可能用独立分支体系；或 checkout 在旧分支。port 前需与人类确认每个仓库的正确 base 分支。
