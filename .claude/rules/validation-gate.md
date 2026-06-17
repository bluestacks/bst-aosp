# 验证网关（Validation Gate）

# 确保改动编译通过、能启动、行为正确后，才声明完成。跳过验证 = 提交坏代码、浪费 review
# 周期。本项目 gate 双重重要：验证是设计支柱，「done」=「已验证」，不只是「写完了」。

## 声明实施完成前

- **Trigger**：一个定制 port / bugfix / refactor 完成、rebase 解决完冲突、或任何「准备声明本单元完成」的时刻（completion-loop 的 checkpoint/review 前，或交付最终结果前）。
- **Check**：两层都必过。

### Layer 1 — 编译验证（远程，完整 AOSP 树）

```bash
ssh <host> 'cd <remote-root> && bash -lc "source build/envsetup.sh && lunch <target> && m <module>"'
# 全量镜像: m dist → out/dist/*.img；迭代清理: installclean（比 m clean 轻）
```

回读：真实 exit code（`echo $?`）+ 产物 `ls -la out/target/product/<device>/*.img`（mtime）。**绝不信任「m 跑完没报错」。**

### Layer 2 — 启动/行为 readback oracle 套件

**时序前提**：需 host 最小实现已 port 入虚拟化（`qvm`/`vbox`）。**guest 构建就绪 ≠ 可启动验证**；按 Phase 2 顺序：guest 就绪 → port 虚拟化进 host → 启动验证。Phase 1 仅达 Layer 1。

oracle 清单与取数见 [docs/boot-oracles.md](../../docs/boot-oracles.md)：kernel boot log（串口/`adb shell dmesg`）、分区 by-name symlink、动态分区创建、分区挂载、init rc 解析、SELinux 域转换、vbmeta/verity、bootanim→launcher。

- **陷阱条款**：Layer 1 通过**不构成 done**。只有 Layer 2 至少覆盖「分区挂载 + init 关键服务 + 无 SELinux 阻塞 + 启动到 launcher」才算完成。
- 若 Layer 2 因耗时本会话跑不完，summary 标 `verification: build-only, boot-pending` 并登记 `progress/`。
- **开发中不必每改必跑**：批量改动完成后跑一次即可，不必每个小 edit 都跑。
- **若跳过**：说明原因并列出补救步骤。**绝不未跑就声称 gate 通过。**

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
