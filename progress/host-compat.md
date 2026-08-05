# host 兼容检查点（Host-Compat）

guest 变更后，host（mac `qvm` / win `app-player`+`vbox`）是否仍兼容的检查点记录。见 [../.claude/rules/host-guest-contract.md](../.claude/rules/host-guest-contract.md)。

## 契约面清单（Phase 0 识别）

- **图形**：host qemu fork ↔ guest goldfish-opengl。【细节待填】
- **虚拟化设备模型**：mac `qvm` / win `vbox` ↔ guest kernel/设备模型。【细节待填】
- **框架**：`hd` ↔ guest 通道。【细节待填】
- **镜像**：分区布局 / 设备 / PCI 约定。【细节待填】

## 当前最小范围

两端 `hd`（win ← `hd.git` / mac ← `hd-mac.git`）+ 图形驱动（可从 mac 分支构建）随 guest 适配；虚拟化（`qvm`/`vbox`）Phase 2 起纳入。

## 检查记录

| 日期 | patch-id / 变更 | 契约面 | win smoke (app-player-dev) | mac smoke (qvm) | 结果 | 备注 |
|---|---|---|---|---|---|---|
| 2026-07-21 | cont.20 BstUtils+BatchC WMS hostcalls | hd HostCall / orientation | Layer2 7/7 Root `d2e35648`（Tiramisu64） | deferred | ok | host 见 `hcallSetAppConfigDbParamsClbk`；mac 不跑 |
| 2026-07-21 | cont.21 DisplayRotation + selinux enabled.c | 图形旋转 / sepolicy | enabled.c → netbpfload-missing（3/7）；已 revert；DisplayRotation 重验中 | deferred | broken→pending | 禁 port `is_selinux_enabled=0` |
| 2026-07-21 | P2-MAC-ARM64 `bst_arm64` | 镜像/板 | lunch only | deferred | ok | 无 mac Layer2；不改 win 契约 |
| 2026-07-23 | FW-SERVICES-1a Clipboard host sync | hd HostCall / clipboard | Layer2 7/7 Root `eeb4f714` | deferred | ok | `BstHostCallManager` lazy-init |
| 2026-07-23 | FW-SERVICES-4a Audio volume + AppOps devicedetails | hd HostCall / volume | Layer2 7/7 Root **`a551d823`** | deferred | ok | `onVolumeChanged`；AppOps synthetic pkg |
| 2026-08-05 | A13 authority completion + A16 SELinux adaptation | APEX labels / netbpfload / hd boot state | Layer2 7/7 @168s Root `8d8afc15` | deferred | ok | Rejected `is_selinux_enabled=0`; root `5c8f8eb`, 39 APEX activated, NetBpfLoad success |

强约束：guest 升级**绝不静默破坏** host；任何 patch 集 Phase 完成前此处必有一行 ok 或显式 escalate。
