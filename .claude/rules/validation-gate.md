# 验证网关（Validation Gate）

# 确保改动编译通过、能启动、行为正确后，才声明完成。跳过验证 = 提交坏代码、浪费 review
# 周期。本项目 gate 双重重要：验证是设计支柱，「done」=「已验证」，不只是「写完了」。

## 声明实施完成前

- **Trigger**：一个定制 port / bugfix / refactor 完成、rebase 解决完冲突、或任何「准备声明本单元完成」的时刻（completion-loop 的 checkpoint/review 前，或交付最终结果前）。
- **Check**：两层都必过。

### Layer 1 — 编译验证（远程，完整 AOSP 树）

当前 mainline 的 `<remote-root>` 必须解析为 `~/android-16`。先执行
`bash ~/bst-aosp/scripts/g1_build_android16.sh --check`；保存 tree、branch、
HEAD、OUT_DIR 和 product readback。历史 AOSP16 绿基线只证明 development
阶段，不替代 Android-16 target build。

```bash
ssh <host> 'cd <remote-root> && bash -lc "source build/envsetup.sh && lunch <target> && m <module>"'
# 全量镜像: m dist → out/dist/*.img；迭代清理: installclean（比 m clean 轻）
```

回读：真实 exit code（`echo $?`）+ 产物
`ls -la out/target/product/<device>/*.img`（mtime）+ SHA-256 + identity
sidecar。**绝不信任「m 跑完没报错」。**

### Layer 2 — 启动/行为 readback oracle 套件

**当前（Phase 2）**：win BlueStacks 路径 Layer 2 已跑通（Phase 1 G1 boot 到 launcher，host oracle 全绿，见 `progress/porting-log.md` cont.4 / `patches/android-16/checkpoints/G1-RESTORE.md` §6）。Layer 1 每 patch-group 强制；Layer 2 在「并入 boot 镜像」节点跑（相关组可批量后一次验证）。

> **stale-oracle 教训（2026-07-17 G1 bringup）**：oracle 字符串/取数通道本身要先验真格式，再据它下判断。`g1_boot_verify.ps1` 旧 `Player state: ready` 短语永不命中（HD-Player 实际用 `[Ready]` 行内 tag）→ 成功 boot 也判 FAIL（假阴性）；`VBoxManage showhdinfo` 的 UUID 是注册表缓存值、非文件 footer 实际。**verify-by-readback 适用于 readback 通道本身** —— 先确认通道/字符串对，再读数。

oracle 清单与取数见 [docs/boot-oracles.md](../../docs/boot-oracles.md) + boot-guide：kernel/串口、`system mounted from sfs`、init、odsign/boot.art、`boot_completed`、`Player state: ready`、Settings、优雅关机。

- **陷阱条款**：Layer 1 通过**不构成 done**。并入 boot 的组须 Layer 2 至少覆盖挂载 + init + launcher/ready。
- 若 Layer 2 因耗时本会话跑不完，summary 标 `verification: build-only, boot-pending` 并登记 `progress/`。
- **mac 不做 Layer 2**（见 `platform-win-first-mac-reuse.md`）。
- **绝不未跑就声称 gate 通过。**
- stage/pack/deploy/boot 使用的 identity HEAD 不一致时，即使各命令单独
  返回 0，也视为验证失败。

## 以 readback 验证，而非信任确认（Verify by readback）

- **Trigger**：任何「改动达到了预期效果」的断言——测试过了、构建成功了、状态更新了。
- **Check**：通过独立取数确认（命令真实 exit code 与输出、对结果状态的单独查询），**绝不**信任变更动作「应该奏效了」。这镜像了架构核心验证原则，也适用于你自己的汇报：**先有证据，再有断言**。

## UI / 渲染输出验证（不做单像素检查）

- **Trigger**：验证某个渲染元素（bootanim 画面、launcher 截图等）真的渲染对了。
- **Check**：把捕获区域与**期望图**（源资产叠在已知背景上、缩放到屏幕尺寸）做结构容差比对（降采样到小网格，断言低均方通道差）。
- **绝不**用「采样单像素 ≠ 背景」来验证渲染元素——那只证明「画了东西」，不证明「画对了」。单像素/背景色断言**仅**适用于纯色填充区域（颜色本身就是断言）。
- **独立 oracle**：期望图从源资产**本征属性**（原生尺寸/宽高比）推导，**不**复用被测 renderer 自己的布局参数——否则错布局会被烘进两侧，检查看不见。

## 安全网

远程构建机的 CI / pre-commit（后续阶段引入，见 [SETUP-ROADMAP.md](../SETUP-ROADMAP.md)）是兜底，**不**替代你自己跑 gate。
