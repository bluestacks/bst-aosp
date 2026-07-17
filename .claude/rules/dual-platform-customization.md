# 双端定制清单获取与分析

# 把 win（`-a13`）与 mac（`-mac`）相对上游 android-13 的定制完整列出，
# **有意识统一**两端同一定制，平台特有的移植时加平台区分。registry v2 是权威。

## Trigger

重生成 / 更新定制清单；评估某项 phase；开一个 patch-group 前对齐两端是否有对应项。

## 获取（远程）

guest 构建机：`markxu@172.16.6.191`。

| 树 | 路径 | 含义 |
|---|---|---|
| win fork | `~/android-13`（或 `~/app-player/android-13`） | `-a13` BlueStacks fork |
| mac fork | `~/android-mac`（或 `~/app-player-mac` 子模块） | `-mac` BlueStacks fork |
| 目标 | `~/aosp16` | `android-16.0.0_r4` |

对每个有意义的子模块：

1. 找最近可用的上游 `android-13.0.0_r*` tag（**勿死钉单个 r 号**——mac 曾因 r83 漂移产大量噪声）。
2. `git log <tag>..HEAD --oneline` + 抓 message / 作者；**不要只靠 `--author=bluestacks`**（漏非 bluestacks 邮箱的 mac 提交）。
3. 对 device / frameworks / hardware / system 等关键区：**即便 bst 作者计数为 0 也人工复查**（对照 dir 是否有 `bst`/`BlueStacks`/`qvirt` 关键字）。

## 分析与统一

1. **同一定制归一组**：同一意图（如同一 HAL、同一 framework 钩子）的 win/mac 项归入同一 `unify_group`，`platform=both`。
2. **平台特有标区分**：仅一端有的标 `platform=win` 或 `platform=mac`；移植时用 product 变体 / `#ifdef` / BoardConfig 隔离，**禁止**把 mac-only 改动无条件打进 win 镜像（反之亦然）。
3. **关联分组**：相互依赖的定制（sepolicy 各域、HAL+VINTF、framework+JNI）标同一 `related_group`（= patch-group id，如 `G1`/`G8`）；**一组一起移植**。
4. **phase**：P1 = 当前可 boot 最小集融合；P2 = 其余按优先级；P3 = prebuilts / 低优先。
5. **boot 存量**：已在 `patches/android-16/` 的改动必须映射进 registry；临时 hack 标 `temp_debt=true`。

## 产出

- 更新 `patches/registry.json`（v2 schema）+ `patches/registry.md` 汇总。
- 每组在 `progress/phase1-port-plan.md` / `progress/phase2-port-plan.md` 有一行计划。
- 追加 `progress/porting-log.md` 记「清单重新生成」事件。

## 禁止

- 用错位树（非目标 tag/分支 tip）生成清单后当权威。
- 只扫 win 漏 mac，或把 mac r 漂移噪声全当真定制。
- 静默合并 win/mac 冲突语义而不 escalate。
