# 环境拓扑（Topology）

> 三套环境（2026-06-18 路线修订）。密码不入库；guest 与 mac host 均用本地 `~/.ssh/id_ed25519` 免密。

## 三套环境

| 角色 | 环境 | 位置 | 仓库 / tag | 状态 |
|---|---|---|---|---|
| **win host** | 本机 Windows | `C:\workspace\app-player` | tag `bst-v5.22.210-5.22.210.1033` ✅ | BlueStacks 已装；android 子模块未 init |
| **mac host** | macOS Mac mini | `zeqing@172.16.0.204`（`~/app-player-mac`） | 需切到 tag `bst-v5.21.700-nxt_mac2-5.21.700.7526`（tag 存在；当前 Fortnite-4103） | BlueStacks 已装；android-mac 已 init；工作区有 submodule 指针漂移 |
| **guest 构建** | Ubuntu | `markxu@172.16.6.191`（clouddev） | android-13/android-mac 子模块（递归 init 中） | aosp16 已 sync；缺 hd/buildscripts |

> mac 另有 `~/workspace/app-player-mac`（ai-worker 5.22.999 开发用），非本项目规范目录。

## 各环境细节

### win host（本机）
- 仓库 `C:\workspace\app-player`（detached HEAD @ `bst-v5.22.210-5.22.210.1033`）。
- `.gitmodules`：`android`(kitkat-master)、`android-9/11/13`、`hd`、`ggl/{qemu,astc-encoder,goldfish-opengl}` 等。**android/android-13 未 init**；host 构建需 hd/ggl 等（视情况 init）。
- 构建：`build.bat`（VS+Qt+vcpkg+cmake/msbuild）→ HD-Player.exe。
- 运行/测试：本机已装 BlueStacks，替换其 guest 镜像后跑。

### mac host（172.16.0.204）
- `ssh zeqing@172.16.0.204`（免密已设）。macOS 26.4.1，Mac mini `bstdeMac-mini`，~95G 可用。
- 仓库 `~/app-player-mac`：当前 `bst-v5.21.700-nxt_mac2`（Fortnite-4103）；**需 checkout 到 tag `bst-v5.21.700-nxt_mac2-5.21.700.7526`**（先处理 submodule 指针漂移）。
- `android-mac` 子模块（`bluestacks/android-mac.git`）已 init（完整 AOSP 树 + kernel）。
- 构建：`build.sh` + `buildscripts/mac_build.sh`（clang+Qt）→ BlueStacks.app。

### guest 构建（clouddev 172.16.6.191）
- `ssh markxu@172.16.6.191`（免密已设）。Ubuntu 22.04，7.3T 工作盘。
- `~/android-13`（win guest，`bluestacks/android-13.git`）、`~/android-mac`（mac guest）——**递归 init 子模块中**。
- `~/aosp16`（上游 android-16.0.0_r4，247G，sync 完成）——aosp16 阶段用。
- `~/kernel-common-a13`、`~/kernel-mac`。
- **缺口**：buildscripts 流程需 `hd` 兄弟目录 + `kernel64-hyperv` + buildscripts 本体——clouddev 暂无（待补）。

## SSH 用法

- guest：`ssh markxu@172.16.6.191 '...'`
- mac：`ssh zeqing@172.16.0.204 '...'`
- 长任务 nohup + log + PID；envsetup/lunch 同一 bash -lc；断线靠 `ps -p <pid>` + `tail` 恢复。

## 流程（路线）

① 检查+完成环境设置（三端）→ ② **android-13 基线**：guest 编译(clouddev)→打包→替换 win+mac host 已装 BlueStacks→运行测试，两端通过 → ③ 才开始 aosp16 工作。定制清单重新生成（等子模块）。详见 [.claude/SETUP-ROADMAP.md](../.claude/SETUP-ROADMAP.md)。
