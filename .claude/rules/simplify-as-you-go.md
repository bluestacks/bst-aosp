# 随手简化（Simplify As You Go）

# 实施中的轻量自审。在复用遗漏、不必要复杂、效率问题累积之前抓住它们——边写边自纠，
# 而不是等到 review 时。

## 完成一个逻辑块后

- **Trigger**：port 完一个定制 / 一段 init/fstab/device overlay 改动，进入下一块前。
- **Check**：回顾刚写的，看：
  1. **Reuse（复用）**——是否漏了上游/参考实现已有的机制？AOSP 几乎每个痛点都有现成解（dm-init、by-name symlink+fstab、apexd、conventional HAL）。**先看上游/cuttlefish 怎么做再决定是否手搓**。android-16 upstream 可能已原生支持 android-13 需手搓的能力——优先采用 upstream，把定制收敛到最小。
  2. **Simplicity（简洁）**——是否引入了已不需要的兼容层？跨版本升级常留下死兼容代码（旧 `#ifdef`、废弃分支）。rebase 时趁机删。
  3. **Efficiency（效率）**——构建效率：能否只 `m <module>` 或运行规范增量入口？当前主线不执行 `installclean`、`m clean` 或全量 `m dist`，除非用户单独明确授权。
  4. **Seam placement（接缝位置，关键）**——定制是否落在**最小侵入接缝**？优先 device/vendor 层（device overlay / `init.<board>.rc` / `fstab` / BoardConfig），**而非**直接改上游框架主干（如 `system/core/init` 主干——rebase 成本爆炸、影响所有设备）。把定制往下推，主干保持 upstream 干净。这一条直接决定后续 rebase 痛苦度。
- **Fix**：继续前先重构。别在一个会话内累积债——现在修比 review 时修便宜。
