# .claude/ 设置路线图

本仓库 agent 工具如何随升级阶段演进。每项能力的触发是**项目阶段 gate**，不是日历日期——
gate 内容是 AOSP 升级里程碑。阶段开了、且有真东西可做时再加能力；提前搬来 = 维护闲置脚手架。

---

## Phase 0 — 环境就绪 + 定制清单（构建前）  ·  **当前**

- [x] `CLAUDE.md`、`README.md`、`architecture.md`/`-brief.md`
- [x] `.claude/rules/`（6 适配 + remote-build/patch-porting/host-guest-contract）
- [x] `.claude/commands/`（review/quick-review/save-summary + remote-build/port-patch/boot-verify）
- [x] `.claude/skills/docs-navigator/`
- [x] `.claude/settings.json`（allow/deny/prompt，SSH 白名单出厂为空）
- [x] `patches/registry.*` 骨架、`progress/`、`docs/`（含 Phase 0 待填项）
- [x] **Phase 0 已完成**：远程主机 `markxu@clouddev` 确认（docs/remote-topology + settings allowlist）；`repo init`/`sync` 完整 AOSP 树 `~/aosp16`（android-16.0.0_r4，247G，exit 0）；**自动 diff `-a13`/`-mac` vs 上游 android-13** 录入 `patches/registry.json`（289 项，标 phase）。
- [ ] **Phase 0 收尾 / Phase 1 前置**：确认 lunch 目标（registry 已识别 mac 板 `device/bst/qvirt`、win `device/google/cuttlefish`+`device/generic/x86_64`）；vanilla android-16 build 一次（Layer 1 readback）。

**Gate→P1**：定制清单就绪、vanilla android-16 能构建。

---

## Phase 1 — 最小 guest 就绪（win 先行；统一板方案）

- [ ] port **单一 `device/bst/qvirt`** 到 android-16（从 `android-mac/device/bst/qvirt`），产出 `bst_arm64`(mac) + `bst_x86_64`(win 新增) 双 product；板配置(`device.mk`/`BoardConfig`/`init.bst.rc`/`fstab.bst`) arch 无关、共享，arch 由 BoardConfig 定。
- [ ] win guest kernel（`kernel-common-a13`→android-16）含 `bstvmsg`/`bstpgaipc` 驱动（源在 mac `kernel-mac` 22 bst 提交或 hd 模块）。
- [ ] 按清单评估选**最小 guest 改动集**（让 android-16 能构建的最小定制）。
- [ ] guest 构建就绪（Layer 1 全量 `m`：win 先 `bst_x86_64`，mac `bst_arm64`）。
- 此阶段 host 最小实现仅含两端 `hd` + 图形驱动（不含虚拟化）。
- 解锁：patch-porting 全功能 + `/remote-build`。

**Gate→P2**：最小 guest 改动集构建通过（Layer 1）。

---

## Phase 2 — host 镜像产出 + 虚拟化 port + guest 启动验证

- [ ] 参考 `app-player` 编译脚本，把 AOSP 产物产出 host 使用的镜像（写 `docs/build-commands.md`）。
- [ ] 把虚拟化（win `vbox` / mac `qvm`）port 进 host 最小实现。
- [ ] **此时才** Layer 2 启动验证（`/boot-verify`，oracle 全绿）。
- 解锁：`/boot-verify` + host-guest-contract 规则激活。

**Gate→P3**：定制 image 经 host 虚拟化启动到 launcher，oracle 全绿。

---

## Phase 3 — 功能对齐 android-13 + 两端 host 兼容

- [ ] port 完剩余定制项（框架/HAL/图形等），行为对齐 android-13 baseline。
- [ ] 两端 host（mac `qvm` / win `app-player`+`vbox`）全流程可用。
- 解锁：role-agents（architect/implementer/verifier/reviewer）+ `/review` 全功能 + workflow tiers。

**Gate→P4**：功能/回归测试 + bootanim+渲染 对齐 baseline。

---

## Phase 4 — 收尾 / CI

- [ ] CI 化回归；deny 收紧（force-push/hard reset/destructive rm）；create-pr 流程。
- [ ] 复盘：哪些脚手架没挣到 keep，剪掉。

**Gate**：进入内部 dogfooding。

---

## 跨阶段主线：自动 review→fix 循环

把 `implement → checkpoint → review → fix` 做成**可闭环**的循环，happy path 无人介入，人作异常处理器（非收敛/高严重度），不做每步 gate。这是整个项目论点的 dev-loop 表达，在此设计一次，跨阶段搭建。

- **P0 前置**（已建）：`/review` 在新子代理跑 `quick-review`，返回结构化 findings，自动修机械集、readback 重验、≤3 轮、升级其余。
- **P1**：把循环接到 Layer 1 gate 作机械通过判据。
- **P2**：把 Layer 2 boot oracle 接入为 pass criterion。
- **P3+**：加 read-only reviewer agent（opus, fresh context），按改动规模 tiered（quick 每改 / thorough feature 级）。

**自主边界（仅机械性）**：自动修 `#ifdef`/platform 宏/fstab 字段/clang-format/死 include/BoardConfig typo/init rc 语法/missing plan items；升级 dm-verity/SELinux/打包/binder-HAL/图形契约/虚拟化设备模型/host↔guest 契约/rebase 语义判断。编码于 `/review`。
