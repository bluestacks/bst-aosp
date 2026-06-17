# 架构简述

**项目**：Windows + ARM64 Mac Android 模拟器，把 Android guest 从 android-13 升级到 android-16（`android-16.0.0_r4`）。AI 主导、人类辅助，开发模式参考 bst-scout。

## 一句话

guest 是基于 android-16.0.0_r4 的完整 AOSP 树；把 `-a13`/`-mac` BlueStacks fork 相对上游 android-13 的定制 port 过来；win 先行、mac 跟进；guest 就绪后 port 虚拟化（`qvm`/`vbox`）进 host 最小实现再启动验证。

## 组件角色

- **guest**：kernel + goldfish-opengl（图形）+ frameworks-base 等（完整 AOSP 树）。两端统一。
- **host 图形驱动**：qemu fork（**非虚拟化**，可从 mac 分支构建）。
- **host 虚拟化**：mac `qvm` / win `vbox`（在 `app-player` 的 `hd/` 内）。
- **host 框架**：`hd`（win `hd.git` / mac `hd-mac.git`）。

## 验证（两层）

- **Layer 1 编译**：远程 `lunch` + `m`，回读 exit code + 产物。
- **Layer 2 启动**：kernel log / 分区挂载 / init / SELinux / verity / bootanim。需虚拟化就位后跑。
- 原则：**Verify by readback** —— `m` 成功 ≠ 能启动。

## 阶段

P0 环境就绪 + 定制清单（构建前 diff） → P1 自定义板 + 最小 guest 改动集（Layer 1） → P2 host 镜像产出 + port 虚拟化 + Layer 2 启动验证 → P3 功能对齐 + 两端 host 兼容 → P4 收尾/CI。

详见 [architecture.md](architecture.md)。
