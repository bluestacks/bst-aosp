# 架构简述

**项目**：Windows + ARM64 Mac Android 模拟器，把 Android guest 从 android-13 升级到 android-16（`android-16.0.0_r4`）。AI 主导、人类辅助，开发模式参考 bst-scout。

## 一句话

先在 r4-based AOSP16 development 线完成定制移植与验证，再 promotion 到
Android-16 25Q4-evolved mainline；**win 先行验证、mac 同码复用**；统一板
`device/bst/qvirt`。

## 组件角色

- **guest**：kernel + goldfish-opengl（图形）+ frameworks-base 等（完整 AOSP 树）。
- **host 图形驱动**：qemu fork（**非虚拟化**）。
- **host 虚拟化**：mac `qvm` / win `vbox`（`app-player` 的 `hd/` 内）。
- **host 框架**：`hd`（win `hd.git` / mac `hd-mac.git`）。

## 验证（两层）

- **Layer 1 编译**：远程 `lunch` + `m`，回读 exit code + 产物。
- **Layer 2 启动**：boot oracle（sfs 挂载 → `boot_completed` → `Player state: ready` → Settings → 优雅关机）。
- 原则：**Verify by readback**；每次修改加埋点（`A16DBG:`）与测试。

## 阶段

| 里程碑 | 状态 |
|---|---|
| M1 android-16 win boot | **完成** |
| Phase 1 清单融合 + qvirt | **完成** |
| Phase 2 AOSP16 全量功能对齐 | **完成，cont.101 7/7** |
| AOSP16 → Android-16 promotion | **完成，cont.106 7/7** |
| Android-16 mainline maintenance | **当前** |

当前分支模型：base=`aosp16-bst`，work=`aosp16-bst-merge`。活动构建只从
`~/android-16` 取源码和产物。

详情：[architecture.md](architecture.md) · [SETUP-ROADMAP.md](.claude/SETUP-ROADMAP.md) · [phase2-port-plan.md](progress/phase2-port-plan.md) · [summary](.claude/summary.md)。
