# 研究优先（Research Before Action）

# 当权威文档/源码已存在时，避免对架构决策、定制意图、构建行为瞎猜。最常见的失败模式：
# grep 源码（或凭训练数据猜），而不去读描述该系统的文档/上游源码。
#
# 格式：每条规则有 Trigger（识别情境）和 Check（动手前做什么）。

用 **`docs-navigator`** skill 快速找到对的文档，再做下面的检查。

## 上游 AOSP 源码 / 构建行为

- **Trigger**：任何关于 base ref、子系统行为、API、build/Soong/init/fstab/dm-verity/SELinux 行为的问题。
- **Check**：先读上游 AOSP 源码（`cs.android.com` / `android.googlesource.com`），按 tag（`android-16.0.0_r4` / `android-13`）核对，**再**回答或设计。以源码为准，不以训练数据为准。

## BlueStacks 定制意图

- **Trigger**：任何「BlueStacks 在 android-13 上为什么这么改」「这段定制想做什么」的问题。
- **Check**：读 `-a13`/`-mac` fork 的 git log + 各定制 commit 的 message/diff（远程 fork）。**自动 diff fork vs 上游 android-13** 确认定制边界。不得凭训练数据断言定制意图。

## 参考实现 / 标准做法

- **Trigger**：任何关于启动流程、动态分区/super、fstab、dm-verity、SELinux 等标准做法的问题。
- **Check**：先看 AOSP 上游与参考实现怎么做，按版本核对，再决定是否手搓。

## host 镜像产出

- **Trigger**：任何关于「guest 产物如何变成 host 使用的镜像」的问题。
- **Check**：以 `app-player` 仓库编译脚本为权威（guest 就绪后参考其打包方式）。

## 本仓库积累的结果

- **Trigger**：先前会话跑过的 oracle 结果、试过放弃的方案、已知 gotcha。
- **Check**：读 `progress/` 与 `docs/boot-oracles.md`。这些是 measured results，不得用训练数据覆盖。

## 记忆/笔记

- **Trigger**：某条 memory/note 点名了具体文件、函数、flag、commit。
- **Check**：推荐前**先验证它还在**（读文件、grep 符号、`git log` commit）。记忆是时间快照，代码库不是。

## 硬规则

权威源存在时，不依赖假设、训练数据或片面信息。**下结论前先验证。** 找不到覆盖它的文档/源码时，**明说**，不要编造。
