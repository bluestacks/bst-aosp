# 架构简述

**项目**：Windows + ARM64 Mac Android 模拟器，把 Android guest 从 android-13 升级到 android-16（`android-16.0.0_r4`）。AI 主导、人类辅助，开发模式参考 bst-scout。

## 一句话

guest 是基于 android-16.0.0_r4 的完整 AOSP 树；把 `-a13`/`-mac` 定制 port 过来；**win 先行验证、mac 同码复用**；统一板 `device/bst/qvirt`（x86_64/arm64 各自定制）。

## 组件角色

- **guest**：kernel + goldfish-opengl（图形）+ frameworks-base 等（完整 AOSP 树）。
- **host 图形驱动**：qemu fork（**非虚拟化**）。
- **host 虚拟化**：mac `qvm` / win `vbox`（`app-player` 的 `hd/` 内）。
- **host 框架**：`hd`（win `hd.git` / mac `hd-mac.git`）。

## 验证（两层）

- **Layer 1 编译**：远程 `lunch` + `m`，回读 exit code + 产物。
- **Layer 2 启动**：boot oracle（sfs 挂载 → `boot_completed` → `Player state: ready` → Settings → 优雅关机）。
- 原则：**Verify by readback**；每次修改加埋点（`A16DBG:`）与测试。

## 阶段（当前）

| 里程碑 | 状态 |
|---|---|
| M1 android-16 win boot | **完成** |
| Phase 1 清单融合 + qvirt | **完成** |
| Phase 2 guest **全量功能对齐**（含 frameworks；SELinux=a13 permissive；Shell←`performance_hint` ✅） | **当前 · 唯一活跃** |
| Phase 3 host/CI | **暂不规划** |

当前要点：FW-CORE-APP **9/22** ✅；权威 Root `4ba4bdd3` Layer2 7/7 @597s。工作单元 = **patch-group**。

详情：[architecture.md](architecture.md) · [SETUP-ROADMAP.md](.claude/SETUP-ROADMAP.md) · [phase2-port-plan.md](progress/phase2-port-plan.md) · [summary](.claude/summary.md)。
