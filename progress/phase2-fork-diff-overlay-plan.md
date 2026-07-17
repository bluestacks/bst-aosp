# P2-FRAMEWORK-REST: fork-diff overlay 实施计划

> 第二阶段 Phase 2 · 2026-07-17。把 win/mac frameworks/base + frameworks/native 完整 BST 定制集通过 **fork-diff overlay** 移植到 android-16。
> G5 已做 boot-minimal 子集（对齐 M1 `boot-frameworks-*` 存量）；P2-FRAMEWORK-REST 移植**所有剩余**定制。

## 1. Fork 基线（权威源）

| Fork | 路径（远程） | 分支 | bst 提交数 | upstream tag |
|---|---|---|---|---|
| win frameworks/base | `~/app-player/android-13/frameworks/base` | `bst-v5.22.210` | **220** | `android-13.0.0_r*`（取最近） |
| win frameworks/native | `~/app-player/android-13/frameworks/native` | `bst-v5.22.210` | **71** | 同上 |
| mac frameworks/base | `~/app-player-mac/android-mac/frameworks/base` | `bst-v5.21.700-nxt_mac2` | **68** | 同上 |
| mac frameworks/native | 同上 | 同上 | **10** | 同上 |

## 2. fork-diff overlay 机制（禁止 220 次 cherry-pick）

对整个 fork 取整包 diff，以**单一片 patch** 应用到 android-16：

```bash
cd <fork>/frameworks/base
UPSTREAM_TAG=$(git tag --list 'android-13.0.0_r*' --sort=version:refname | tail -1)
git diff $UPSTREAM_TAG..HEAD -- . > /tmp/frameworks_base_bst_full.patch
cd ~/aosp16/frameworks/base
git checkout android-16.0.0_r4
git apply --3way /tmp/frameworks_base_bst_full.patch  # 三路合并处理
```

## 3. 移植策略（切子集，分批验证）

| 批次 | 子系统 | 预估冲突 | 优先级 |
|---|---|---|---|
| **A** | BST 服务器 native（`com/bluestacks/server/`） | 低（BST 专属，无上游冲突） | P0 |
| **B** | Hostcall/gcall JNI 桥接 | 低 | P0 |
| **C** | ActivityTaskManager/WindowManager hooks（`ActivityDisplayed`、锁屏、过滤应用） | 中（上游重构） | P1 |
| **D** | SystemServer/BstHostCall/BstFilterApps | 中 | P1 |
| **E** | 游戏兼容性修复（ROB-* tickets） | 中-高（跨越多个上游提交） | P2 |
| **F** | 配置数据库 + 全局设置 | 低 | P2 |

## 4. 冲突解决序

1. **机械冲突**（API 重命名、import 变更、方法签名）→ 自动解决
2. **语义冲突**（上游重构改变了 BST 补丁所依赖的逻辑）→ escalate
3. **已废弃代码**（旧 API 移除，BST 仍在引用）→ escalate（需决策回退或重写）

## 5. 每组验证回环

- Layer 1：远程 `m frameworks/base` + `m services`
- Layer 2：Boot oracle 回归（host boot oracle 全绿：Player ready + fUiHideBootProgressBar + ActivityDisplayed；见 G1-RESTORE §6）
- 特组验证（如锁屏、`FilterApps`、游戏兼容性）→ 按需加 oracle

## 6. Mac frameworks (68+10)

Mac fork diff 在 win fork-diff overlay 完成 + 验证后移植。**mac arm64 差异不跑独立 Layer 2**（`platform-win-first-mac-reuse.md`）。

## 7. 临时债关联

- **P2-TEMP-BLAST**：fork-diff overlay 后需验证 BLAST/SF commit callback（若 fork diff 修了 goldfish sync 路径 → 可删 r262 temp patch 并恢复 `ENABLE_SHELL_TRANSITIONS=true`）
- **P2-TEMP-SEPOLICY**：frameworks 定制不直接涉及 sepolicy → 独立处理

## 8. 产出

- 每批次的 `aosp16__frameworks_base__P2-<batch>.patch` + 冲突记录
- `progress/phase2-frameworks-port-log.md`（追加式叙事）
- registry 条目 `port_status=ported` for P2-FRAMEWORK-REST items
