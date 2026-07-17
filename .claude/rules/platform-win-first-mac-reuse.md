# 平台策略：win 先行验证 · mac 同码复用

# android-16 guest 升级：**只在 win 上做构建与启动验证**；mac 在 win 收敛后
# 基于**同一份代码**（统一源 + 平台差异）开发，**不做独立 Layer 1/Layer 2 验证**。

## Trigger

选验证目标、开 patch-group、评估是否需要跑 mac build/boot、写 host-compat。

## 规则

1. **验证只跑 win**：Layer 1（远程 `m`）+ Layer 2（Windows BlueStacks / Root.vhd 替换 / boot oracle）均在 win 路径。
2. **mac 不做验证**：不为 mac 单独跑 lunch/m/boot 作为 gate；不为「mac 也过一下」拖延 Phase 门控。
3. **同份代码**：guest 源码统一（frameworks/system/hardware/bst 共享部分）；arch/平台差异落在：
   - `device/bst/qvirt` 的 `bst_x86_64` vs `bst_arm64` product / BoardConfig；
   - `#ifdef` / `TARGET_ARCH` / 条件 mk；
   - 仅一端需要的 patch 标 `platform=mac` 或 `platform=win`，移植时隔离。
4. **mac 开发时序**：win Phase 1（及后续相关 Phase 2 组）验证通过并 **存 patch + checkpoint** 后，再基于该检查点给 mac 加 arm64 差异；不并行两套 guest 树。
5. **host 侧**：mac host（`qvm` / `hd-mac`）适配属后续；本规则只管 **guest 代码与验证**。

## 例外（须显式记录）

- mac-only 定制（仅 `-mac` 有、win 无）在移植进统一树时，Layer 1 仍在 win 树编译验证「不破坏 win」；行为验证可标 `verification: win-build-only, mac-behavior-deferred`。
- 人类明确要求跑 mac smoke 时，当作额外任务，不改变默认 gate。

## 分歧风险（P6，须警觉）

「同码」不等于「同行为」——mac 是 **arm64 + qvm**，win 是 **x86_64 + vbox**：
- arm64 NDK 翻译层、goldfish arm64 GLES、qvm 设备模型可能与 x86 路径分歧，**win 验证不覆盖这些**。
- 因此 mac 差异（`platform=mac` / arm64 BoardConfig / arch HAL）虽不设 gate，但**必须显式登记**为 `mac-behavior-deferred`，并在 Phase 3 host 阶段集中验证——**不可默认「win 过了 mac 就过」**。
- 触及 host-guest 契约（图形/虚拟化/通道）的改动，即使 win 过，也要在 registry `host_compat` 标 `pending` 直到 mac/host 侧确认。

## 接缝

与 `dual-platform-customization.md`（清单统一）互补：清单双端都采，**落地与验证以 win 为 oracle**。
