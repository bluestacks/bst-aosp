# bst-aosp

**Windows + ARM64 Mac Android 模拟器 —— Android guest 13→16 升级（AI 主导、人类辅助）。**

> ⚠️ 本仓库是**本地协调 / 规则 / patch registry 区**，不含可编译 AOSP 源码。guest 源码与编译在远程 Ubuntu 主机，经 SSH 进行。先读 [CLAUDE.md](CLAUDE.md)。

## 这是什么

把 Android guest 从 android-13 升级到 android-16（`android-16.0.0_r4`）。开发模式参考 [bst-scout](../bst-scout)：可验证、可自动跑完、可跨会话恢复。

- **guest** = 完整 AOSP 树；定制由 diff `-a13`/`-mac` fork vs 上游 android-13 识别。
- **win 先行**、mac 跟进；guest 就绪后 port 虚拟化进 host 最小实现再启动验证。

详见 [architecture.md](architecture.md) / [architecture-brief.md](architecture-brief.md)。

## 阶段状态

| Phase | 内容 | 状态 |
|---|---|---|
| P0 | 环境就绪 + 定制清单（构建前 diff） | ✅ 远程连通 / 全树 sync(247G) / 定制清单(289项) 就绪；lunch 目标 + vanilla build 待 |
| P1 | 自定义板 + 最小 guest 改动集（Layer 1） | ⬜ |
| P2 | host 镜像产出 + 虚拟化 port + Layer 2 启动验证 | ⬜ |
| P3 | 功能对齐 android-13 + 两端 host 兼容 | ⬜ |
| P4 | 收尾 / CI | ⬜ |

见 [.claude/SETUP-ROADMAP.md](.claude/SETUP-ROADMAP.md)。

## 快速入口

- **先读**：[CLAUDE.md](CLAUDE.md)
- **架构**：[architecture.md](architecture.md)
- **进度**：[patches/registry.md](patches/registry.md) · [progress/porting-log.md](progress/porting-log.md)
- **怎么 build/verify**：[docs/build-commands.md](docs/build-commands.md) · [docs/boot-oracles.md](docs/boot-oracles.md) · [.claude/rules/validation-gate.md](.claude/rules/validation-gate.md)
- **agent 规则/命令**：[.claude/rules/](.claude/rules/) · [.claude/commands/](.claude/commands/)

## 组件角色速查

guest（kernel / goldfish-opengl / frameworks-base 等）· host 图形 = qemu fork（非虚拟化）· host 虚拟化 = mac `qvm` / win `vbox` · host 框架 = `hd`。
