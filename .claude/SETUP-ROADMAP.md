# .claude/ 设置路线图

本仓库 agent 工具如何随升级阶段演进。每项能力的触发是**项目阶段 gate**，不是日历日期——
gate 内容是 AOSP 升级里程碑。阶段开了、且有真东西可做时再加能力；提前搬来 = 维护闲置脚手架。

---

## Phase 0 — 环境设置（三端）+ 定制清单重新生成  ·  **当前**

脚手架已就绪。本阶段聚焦三端环境检查+设置，并重新生成定制清单。

- [x] 脚手架（CLAUDE.md/rules/commands/skill/settings/docs/registry）+ clouddev/aosp16 sync（247G）+ 初版 registry（289 项，待重新生成）。
- [ ] **win host（本机 `C:\workspace\app-player`）**：tag `bst-v5.22.210-5.22.210.1033`（已✅）；按需 init 子模块（host 构建 hd/ggl；android 部分**只需 android-13**）；确认 BlueStacks 已装 + 镜像替换路径。
- [ ] **mac host（`zeqing@172.16.0.204 ~/app-player-mac`）**：免密已设；checkout 到 tag `bst-v5.21.700-nxt_mac2-5.21.700.7526`（先处理 submodule 指针漂移）；android-mac 已 init；按需 init 其他；确认 BlueStacks 已装 + 镜像替换路径。
- [ ] **guest（clouddev）**：android-13/android-mac 子模块递归 init 完成；补 **hd 兄弟目录 + buildscripts + kernel64-hyperv**（buildscripts/Makefile 流程所需）。
- [ ] **定制清单重新生成**：基于 app-player(win)/app-player-mac(mac) 的 android-13 子模块重新 triage（修正 mac 基线/作者过滤），更新 registry。

**Gate→P1**：三端环境就绪、android-13 树可构建、定制清单重新生成。

---

## Phase 1 — android-13 基线（win+mac）· **aosp16 前置 gate**

把**原本 android-13** 完整流水线在两端跑通，验证构建/打包/替换/运行链路：

- [ ] guest 编译（clouddev，buildscripts/Makefile）：android-13 → iso_img/ramdisk + hd 内核模块 + kernel → `Root.vdi`（win vbox/hyperv、mac）。
- [ ] 打包 + 替换：Root.vdi 替换进 win/mac host 已装 BlueStacks 的 guest 镜像位置。
- [ ] 运行 + 测试：两端启动 BlueStacks、guest 到 launcher、基本 smoke（Layer 2 oracle）。
- 解锁：`/remote-build`、`/boot-verify`、host-guest-contract 激活。

**Gate→P2（关键）**：win+mac 两端 android-13 基线 build→package→replace→run/test 全通过。**未通过不做 aosp16。**

---

## Phase 2 — aosp16 guest 升级（基线通过后才开始）

- [ ] port **统一板 `device/bst/qvirt`** 到 android-16（bst_arm64 mac + bst_x86_64 win）。
- [ ] port hardware/bst HAL、external/bluestacks/*、frameworks/bionic 等（按重新生成的 registry）。
- [ ] hd guest 内核模块（vmsg/hcall/gcall/xpl）适配 android-16 内核 API。
- [ ] android-16 guest 构建就绪（Layer 1）。
- 解锁：patch-porting 全功能。

**Gate→P3**：android-16 定制 guest 构建通过（Layer 1）。

---

## Phase 3 — android-16 host 适配 + 虚拟化 + 启动验证

- [ ] host 适配（guest 触发）：hd/图形驱动/虚拟化按需调整。
- [ ] Layer 2 启动验证（android-16 image 经 host 虚拟化启动到 launcher，oracle 全绿）。
- 解锁：role-agents + `/review` 全功能。

**Gate→P4**：android-16 image 启动到 launcher，两端 host 兼容。

---

## Phase 4 — 功能对齐 + 收尾 / CI

- [ ] 功能对齐 android-13 baseline（功能/回归测试）。
- [ ] CI 化回归；deny 收紧；create-pr 流程；复盘剪枝。

**Gate**：进入内部 dogfooding。

---

## 跨阶段主线：自动 review→fix 循环

把 `implement → checkpoint → review → fix` 做成**可闭环**的循环，happy path 无人介入，人作异常处理器（非收敛/高严重度），不做每步 gate。这是整个项目论点的 dev-loop 表达，在此设计一次，跨阶段搭建。

- **P0 前置**（已建）：`/review` 在新子代理跑 `quick-review`，返回结构化 findings，自动修机械集、readback 重验、≤3 轮、升级其余。
- **P1**：把循环接到 Layer 1 gate 作机械通过判据。
- **P2**：把 Layer 2 boot oracle 接入为 pass criterion。
- **P3+**：加 read-only reviewer agent（opus, fresh context），按改动规模 tiered（quick 每改 / thorough feature 级）。

**自主边界（仅机械性）**：自动修 `#ifdef`/platform 宏/fstab 字段/clang-format/死 include/BoardConfig typo/init rc 语法/missing plan items；升级 dm-verity/SELinux/打包/binder-HAL/图形契约/虚拟化设备模型/host↔guest 契约/rebase 语义判断。编码于 `/review`。
