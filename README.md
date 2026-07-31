# bst-aosp

**Windows + ARM64 Mac Android 模拟器 —— Android guest 13→16 升级（AI 主导、人类辅助）。**

> ⚠️ 本仓库是**本地协调 / 规则 / patch registry 区**，不含可编译 AOSP 源码。guest 源码与编译在远程 Ubuntu 主机，经 SSH 进行。先读 [CLAUDE.md](CLAUDE.md)。

## 这是什么

把 Android guest 从 android-13 升级到 android-16。项目包含两条连续代码线：

- **AOSP16 开发线**：完整移植、bring-up、调试、功能对齐与绿基线。
- **Android-16 主线**：把已验证 AOSP16 开发线 promotion 到 25Q4-evolved 集成树并持续维护。
- **win 先行**、mac 同码跟进；所有完成结论必须有独立 readback。

详见 [architecture.md](architecture.md) / [architecture-brief.md](architecture-brief.md)。

## 阶段状态

| 阶段 | 内容 | 状态 |
|---|---|---|
| M0 | 三端环境设置（win host / mac host / guest clouddev）+ 定制清单重新生成（registry v2） | ✅ |
| M1 | android-16 win boot（临时形态，存档 `patches/android-16/`） | ✅（2026-07-14） |
| Phase 1 | 融合最小 boot 集转正 + 统一板 `device/bst/qvirt` / `bst_x86_64`（**G1 ported，boot 到 launcher**） | ✅（2026-07-17，Root.vhd `2a7a497a`） |
| Phase 2 | AOSP16 guest 全量功能对齐；最终 Root.vhd `02690d11` / system.img `a878d3c8` | ✅ 7/7 @161s（cont.101） |
| Promotion | AOSP16 绿基线合入 Android-16；1016/1016 项目，985 base + 31 merge | ✅ 7/7 @123s（cont.106） |
| Mainline | Android-16 后续维护，base=`aosp16-bst`，work=`aosp16-bst-merge` | 当前 |

见 [.claude/SETUP-ROADMAP.md](.claude/SETUP-ROADMAP.md)。

## 快速入口

- **先读**：[CLAUDE.md](CLAUDE.md)
- **架构**：[architecture.md](architecture.md)
- **进度**：[patches/registry.md](patches/registry.md) · [progress/porting-log.md](progress/porting-log.md)
- **开发历史**：[docs/development-history/](docs/development-history/) · [AOSP16 绿基线](docs/development-history/aosp16/final-green-baseline.md)
- **当前流程**：[docs/development-workflow/](docs/development-workflow/) · [promotion](docs/development-workflow/promotion.md)
- **全项目 review**：[docs/project-review/](docs/project-review/)
- **怎么 build/verify**：[docs/build-commands.md](docs/build-commands.md) · [docs/boot-oracles.md](docs/boot-oracles.md) · [.claude/rules/validation-gate.md](.claude/rules/validation-gate.md)
- **agent 规则/命令**：[.claude/rules/](.claude/rules/) · [.claude/commands/](.claude/commands/)

## 组件角色速查

guest（kernel / goldfish-opengl / frameworks-base 等）· host 图形 = qemu fork（非虚拟化）· host 虚拟化 = mac `qvm` / win `vbox` · host 框架 = `hd`。
