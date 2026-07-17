# bst-aosp

**Windows + ARM64 Mac Android 模拟器 —— Android guest 13→16 升级（AI 主导、人类辅助）。**

> ⚠️ 本仓库是**本地协调 / 规则 / patch registry 区**，不含可编译 AOSP 源码。guest 源码与编译在远程 Ubuntu 主机，经 SSH 进行。先读 [CLAUDE.md](CLAUDE.md)。

## 这是什么

把 Android guest 从 android-13 升级到 android-16（`android-16.0.0_r4`）。开发模式参考 [bst-scout](../bst-scout)：可验证、可自动跑完、可跨会话恢复。

- **guest** = 完整 AOSP 树；定制由 diff `-a13`/`-mac` fork vs 上游 android-13 识别。
- **win 先行**、mac 跟进；guest 就绪后 port 虚拟化进 host 最小实现再启动验证。

详见 [architecture.md](architecture.md) / [architecture-brief.md](architecture-brief.md)。

## 阶段状态

| 阶段 | 内容 | 状态 |
|---|---|---|
| M0 | 三端环境设置（win host / mac host / guest clouddev）+ 定制清单重新生成（registry v2） | ✅ |
| M1 | android-16 win boot（临时形态，存档 `patches/android-16/`） | ✅（2026-07-14） |
| Phase 1 | 融合最小 boot 集转正 + 统一板 `device/bst/qvirt` / `bst_x86_64`（**G1 ported，boot 到 launcher**） | ✅（2026-07-17，Root.vhd `2a7a497a`） |
| Phase 2 | 其余定制（G2-G10）+ temp_debt 收口（service.cpp→VINTF、gralloc→init.sh、r262 BLAST…） | 🔄 当前 |
| Phase 3 | mac 同码（`bst_arm64`）+ host 适配 + 功能对齐 + CI | ⬜ |

见 [.claude/SETUP-ROADMAP.md](.claude/SETUP-ROADMAP.md)。

## 快速入口

- **先读**：[CLAUDE.md](CLAUDE.md)
- **架构**：[architecture.md](architecture.md)
- **进度**：[patches/registry.md](patches/registry.md) · [progress/porting-log.md](progress/porting-log.md)
- **怎么 build/verify**：[docs/build-commands.md](docs/build-commands.md) · [docs/boot-oracles.md](docs/boot-oracles.md) · [.claude/rules/validation-gate.md](.claude/rules/validation-gate.md)
- **agent 规则/命令**：[.claude/rules/](.claude/rules/) · [.claude/commands/](.claude/commands/)

## 组件角色速查

guest（kernel / goldfish-opengl / frameworks-base 等）· host 图形 = qemu fork（非虚拟化）· host 虚拟化 = mac `qvm` / win `vbox` · host 框架 = `hd`。
