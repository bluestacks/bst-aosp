# host-guest 契约（Host-Guest Contract）

# guest 升级触发 host 适配。guest 绝不能静默破坏 host（mac `qvm` / win `app-player`+`vbox`）。
# 任何改契约的改动 escalate，不自行修。

## Trigger

guest 变更可能影响 host 对它的调用：
- **图形**：host 图形驱动（qemu fork）↔ guest 图形（goldfish-opengl）。
- **虚拟化设备模型**：mac `qvm` / win `vbox`（后者在 `app-player` 的 `hd/` 内）↔ guest kernel/设备模型。
- **框架**：`hd`（host 框架）↔ guest 通道。
- 镜像分区布局、设备/PCI 约定等。

（具体契约面 Phase 0 从 `qvm` / `app-player` 对 guest 的调用关系识别，写入 `progress/host-compat.md`。）

## Check

1. 识别本变更触及的契约面（`progress/host-compat.md` 维护契约清单）。
2. **两端各做一次 smoke**：
   - win 侧 `app-player-dev`（最小）构建 + 用新 guest 镜像启动；
   - mac 侧 `qvm` 构建 + 启动（若本地可构建）。
   - 分别记录结果到 `progress/host-compat.md`。
3. 契约**必然破坏**（升级带来的 breaking change）→ **escalate**，由人决定 host 侧（`hd` / 图形驱动 / `qvm` / `app-player`+`vbox`）改造还是 guest 兼容 shim。

## 强约束

- guest 升级**绝不静默破坏** host。
- 任何 patch 集 Phase 完成前，`progress/host-compat.md` 必须有一行 `ok` 或显式 escalate。

## 当前最小范围

两端 `hd`（win ← `hd.git` / mac ← `hd-mac.git`）+ 图形驱动（可从 mac 分支构建）需随 guest 适配；**虚拟化（`qvm`/`vbox`）暂不纳入**（Phase 2 起 port 进 host 最小实现，见 [SETUP-ROADMAP.md](../SETUP-ROADMAP.md)）。

## guest 镜像产出

guest 就绪后，参考 `app-player` 仓库编译脚本，了解如何把 AOSP 构建产物产出 host 使用的镜像（镜像格式/打包权威，写入 `docs/build-commands.md`）。
