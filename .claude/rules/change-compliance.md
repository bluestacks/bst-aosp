# 改动合规规范（Change Compliance）

# 每一个改动（patch-group / fix / 定制 / bringup bypass）必须满足以下 5 条硬要求。
# 适用于 guest AOSP 树、host 源、device overlay、打包脚本——所有后续移植（G2-G10、Phase 2、mac）。
# review/quick-review 时对每条改动机械执行此清单。不满足 = 不算 done。

## Trigger

任何 guest/host/device 改动准备声明「完成」/ checkpoint / commit 之前（completion-loop 的 validate + review 步骤）。

## 五条硬要求

### 1. 远程 commit（不留 dirty）

- **先标阶段**：AOSP16 development 的历史工作位于
  `~/aosp16/<project>`；promotion/mainline 的当前工作位于
  `~/android-16/<project>`。不得用一棵树的构建结果证明另一棵树。
- 每个涉及的 project 在其所属树中**远程 git commit**，不留
  dirty/未跟踪散落。
  - `git add -A` + `git commit`（合规 message，见下）。
  - `device/*` untracked scaffold（非 git repo）→ 存 `bst-aosp/patches/android-16/untracked-src/`。
- **commit 前清噪音**：`.bak`/`.bak.rXXX`/`.disabled`/`.bak-r*` 等中间态文件**不入 commit**（`git rm` 或 amend 移除）；否则 `git diff`/`repo status` 噪声 + 一致性缺口。
- promotion/mainline 还必须记录根 gitlink、组件 HEAD、base/work branch
  以及目标 remote；根仓提交不能引用只存在于本地的组件 SHA。

### 2. 正式 + temp_debt 双重标注

- **正式改动**：走上游/canonical 机制（PRODUCT_PACKAGES / Android.bp / init rc / BoardConfig），非硬编码 bypass。
- **hack/temp_debt**：若必须 bypass（bringup），**双重标注**：
  - **代码内**：注释带字面 `temp_debt` + `TODO(restore)` + 正式修法（如 `/* BlueStacks DIAG temp_debt 2026-07-20: ...; formal fix = ... */`）。
  - **commit message + registry**：`temp_debt: <what>; Phase 2 fix: <how>`，registry `temp_debt: true` + quality 字段写正式修法。
- 禁止：未标注的 hack / 静默 bypass。

### 3. 关键打点（A16DBG，可 grep 回读）

- **关键 runtime 路径必须打点**（对齐 `instrumentation-and-tests.md`）：bypass 分支、HAL 注册、boot 阶段、mount/init/crash 关键点。
- 打点字符串 `A16DBG:<area>:` 前缀，**可 grep**（串口 / bs_bootlog / Player.log / logcat）。
- **死代码陷阱**：打点不要放在 `if(false)`/常量分支内（编译器死代码消除 → 二进制无该串）。放在分支**外**（always-emitted）或条件会真命中的分支内。
- build-config / data 文件（Android.bp/.rc/manifest.xml）无天然打点点 → readback 兜底 + `bst_x86_64.mk` build-time `$(warning A16DBG:G1: ...)` 子项标记。
- 语言对应：C/C++ `ALOGI/LOG(INFO)`、Rust `info!`（确保 `log` crate import）、Java `Log.i`。

### 4. BST 可溯源

- **commit message 注明 source**：`Source: <BST -a13/-mac fork（commit/分支） | G1 Phase 1 (2026-07) | M1 boot | 本会话原创>`。
- **registry 条目**：每条改动有 registry entry（`id`/`purpose`/`quality`/`boot_artifact`/`checkpoint_ref`）。
- 全树无 BST git remote 时，「溯源」= registry + patch 头 + commit message + porting-log（不强求 fork commit hash，但须有一句话出处 + patch 路径）。

### 5. 与本地 patch 一致（干净 AOSP 可恢复）

- 远程 commit 的 `git diff <base>..HEAD` **== 本地** `patches/android-16/patches/aosp16__<project>.patch`（**字节级**，+/- 内容行一致）。
- `base` = `patches/android-16/patches/aosp16__<project>.base`（上游 commit）。
- **干净 aosp16.0.0_r4 + `git apply` 本地 patch == 远程 commit 态**（可恢复，G1-RESTORE 机制依赖）。
- 每次改动后**重生成本地 patch**（`git diff <base>..HEAD` → patch）+ 验证一致（grep +/- 行数对比）。远程 commit 与本地 patch 漂移 = bug。

## 合规 commit message 模板

```
BlueStacks android-16 (aosp16) port: <project>

Source: <BST -a13/-mac fork | G1 Phase 1 | M1 | 原创>.
<formal | temp_debt: <what>; Phase 2 fix: <how>>.
Key change: <一句话>.
A16DBG 打点: <yes(where)/no(data file, readback 兜底)>.
Verification: <Layer1 build / Layer2 boot / readback 证据>.
Restorable via bst-aosp/patches/android-16/patches/aosp16__<patch> (git apply on clean aosp16.0.0_r4).

Co-Authored-By: Claude <noreply@anthropic.com>
```

## 合规检查清单（review 时逐条）

每个改动 / 每个 patch-group 完成循环的 review 步：
- [ ] 远程各 project 已 git commit（无 dirty 散落；.bak 已清）？
- [ ] 正式 or temp_debt 双重标注（代码 + commit + registry）？
- [ ] 关键 runtime 路径有 A16DBG 打点（分支外/真命中分支，非死代码）？
- [ ] commit message + registry 有 BST source + patch 路径？
- [ ] 远程 `git diff <base>..HEAD` == 本地 patch（字节一致）？干净 AOSP git apply 可恢复？

任一 ✗ = 不合规，不声明 done。

## 引用

- 打点细节：[instrumentation-and-tests.md](instrumentation-and-tests.md)
- 移植工作流（patch-group）：[patch-porting.md](patch-porting.md)（§移植单步末加「合规 commit + regen patch」）
- registry 字段：[patch-porting.md](patch-porting.md) §registry 字段 + [registry.schema.md](../../patches/registry.schema.md)
- 完成循环：[completion-loop.md](completion-loop.md)（review 步执行此清单）
