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

## ⚠️ 分支出入（待确认，已部分核实）

- **kernel-common-a13 (win)**：checkout 在 `aosp13-sync`；origin 另有 `aosp13-bst`、`bst-v5.20.0-android13` 分支与产品标签 `bst-v5.20.0-android13-5.22.0.4028/4029`。用户给的 win 产品分支 `bst-v5.22.210-5.22.210.1033` 可能对应其中某标签——待确认正确 win base。
- **kernel-mac (mac)**：checkout 停在**旧分支** `bst-v5.0.0-nxt_mac2`；但 origin 有更新的 `bst-v5.21.680-nxt_mac2`（及 .650/.670/.675/-vulkan 等）。用户给的 `bst-v5.21.700-nxt_mac2` 此处未见、最接近 `.680`——**定制 diff 前需切到正确 mac base 分支**（很可能 .680/.700）。
- 定制 diff 须以「每个 fork 相对上游 android-13 基线」计算：上游基线 = AOSP common kernel 的 `android13-*`（`aosp.googlesource.com/kernel/common`）。
