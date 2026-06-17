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

| 目录 | 是什么 | 来源 / 分支 | 状态 |
|---|---|---|---|
| `~/aosp16/` | **目标 base**（上游 android-16.0.0_r4） | `repo sync -c -j8` | 🟡 sync 进行中 |
| `~/android-13/` | **win 定制来源**（guest AOSP fork） | 1056 子模块 → `bluestacks/*-a13.git` | 🟡 子模块初始化中 |
| `~/android-mac/` | **mac 定制来源**（guest AOSP fork） | 1056 子模块 → `bluestacks/*-mac.git` | 🟡 子模块初始化中 |
| `~/kernel-common-a13/` | win guest kernel | `bluestacks/kernel-common-a13.git` @ `aosp13-sync` | ✅ 正确检出 |
| `~/kernel-mac/` | mac guest kernel | `bluestacks/kernel-mac.git` @ `bst-v5.0.0-nxt_mac2` | ✅ 正确检出 |

- **定制清单来源** = `android-13`/`android-mac` 各子模块相对上游 android-13 的 diff（自定义板在 `device/` 子模块里 → 决定 lunch 目标）。
- `android-13` 非 repo 树（无 `.repo/`），用 **git submodules**（1056 条）组装，每条即一个 bluestacks fork。

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

## 分支说明（已澄清，非误报）

- **kernel 仓库用独立分支体系**：`kernel-common-a13`=`aosp13-sync`、`kernel-mac`=`bst-v5.0.0-nxt_mac2` 均为**正确检出**。
- 用户给的 mac/win **产品分支**（`bst-v5.21.700-nxt_mac2` / `bst-v5.22.210-5.22.210.1033`）适用于 `android-13`/`android-mac` 等 fork 树与产品仓库，**不**适用于 kernel。
- 定制 diff 基线：`android-13`/`android-mac` 子模块各自相对上游 android-13 对应仓库；kernel 相对上游 common kernel `android13-*`（`aosp.googlesource.com/kernel/common`）。
