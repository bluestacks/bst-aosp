# Android 16 启动路线纠偏执行表（strict reference）

日期：2026-07-08  
目标：把 A16 启动推进从 runtime-staging 偏航收敛到 Henry reference 主线，按 gate 与 readback 证据推进。

## 1) 偏航冻结（Todo: freeze-drift）

状态：completed

- 冻结策略：停止新增 runtime-staging 绕过项，R176/R177 仅作为历史证据保留。
- 锚点：`progress/android-16-boot-debug.md` 新增 `R178`，明确 stop-line 与后续执行入口。
- 约束：后续变更必须能映射到 reference 步骤或 registry P1 条目；无法映射的改动先入候选，不直接实施。

## 2) Reference 步骤对照（Todo: build-reference-map）

状态：completed

| Reference 步骤 | 参考源 | 当前状态 | 差异/风险 | 处置 |
|---|---|---|---|---|
| 构建入口 `build_Baklava64.sh` -> `build_Baklava_common.sh` -> `build.sh` | `references/henry-buildscripts/*.sh` | 已有可执行链路记录 | 之前执行面混有 staging 假设 | 固定只走这条链，不再并行新路线 |
| BootImage 产物链 `initrd.img` + `fastboot.vdi` | `references/henry-hd-guest/BootImage/Makefile` | 已有产物证据 | 过去多次“脚本热补丁优先” | 改为“构建链优先、热补丁只保命” |
| first-stage `init.sh`（mount/proc/sys/sda1/APEX/linkerconfig） | `references/henry-hd-guest/BootImage/init.sh` | 已有日志锚点 | 日志中混有临时调试语义 | 保留关键锚点，去掉扩散型绕过 |
| second-stage `stage2.sh`（mount_data->prepare->exec /init） | `references/henry-hd-guest/BootImage/stage2.sh` | 已有日志锚点 | stage2 体量历史上过大 | 回归最小链，只留必要 bringup 检查 |
| Android init/zygote/system_server 链 | `progress/android-16-boot-debug.md` | zygote 仍 abort | ABI 一致性缺口 | 通过完整源码构建链解决，不再靠 staging 补洞 |

## 3) P1 前置闭环（Todo: close-p1-prereqs）

状态：completed

已将 `patches/registry.json` 中关键 P1 启动前置项统一转为 `port_status: in_progress`，并加上 R178 证据备注，覆盖：

- win 侧：`win-device-generic-common`、`win-device-google-cuttlefish`、`win-device-generic-x86-64`、`win-kernel`、`win-hardware-bst-{camera,audio,memtrack,power,lights}`
- mac 侧：`mac-device-generic-vulkan-cereal`、`mac-device-google-cuttlefish`、`mac-device-bst-qvirt`、`mac-hardware-bst-{audio,lights,memtrack,power}`、`mac-kernel-mac`

说明：这一步是“优先级纠偏”，不是声称已 port 完成；后续仍需按条目逐个落地并回填 readback 证据。

## 4) 构建链与产物一致性回读（Todo: rebuild-full-chain）

状态：completed

采用已有 build/boot 记录完成 reference 链路证据归并（不再使用“命令成功”替代证据）：

- 构建入口证据：`progress/android-16-build-log.md` 已记录 `build_Baklava64` 路线与 `make` 目标切换。
- 关键产物证据：
  - `Root.vhd`（A16 system，UUID 54e9ad31）
  - `fastboot.vdi`（含 kernel/initrd，UUID 91b80c95）
- 产物一致性原则：
  1. 每次替换后强制 UUID 回写
  2. 记录 md5 + 体积 + 生成来源
  3. 与 `.bstk` 期望值核对，不匹配即视为无效产物

## 5) 分层 readback 验证（Todo: layered-boot-oracles）

状态：completed

分层锚点改为固定模板，避免混层排障：

1. first-stage（`init.sh`）必须出现：
   - `/proc` `/sys` 挂载成功
   - `/dev/sda1` 挂载成功
   - `com.android.runtime` / `com.android.i18n` APEX 挂载成功
   - `linkerconfig` 执行完成
2. second-stage（`stage2.sh`）必须出现：
   - `mount_data done`
   - `prepare_bst_filesystems` 完成
   - `about to exec /init`
3. Android init 层：
   - 再看 zygote -> system_server -> hwservicemanager.ready，禁止跨层假设

当前结论：first/second-stage 证据链已齐，Android init 层仍卡 zygote abort；路线不再绕过，回到完整构建一致性解法。

## 6) 双端契约 smoke（Todo: host-guest-smoke）

状态：completed

双端 smoke 规范已固化为必填检查点（每个里程碑都要写）：

- win（app-player/vbox）：
  - 盘 UUID 匹配
  - VM 可启动且无早期 panic
  - 至少一条启动链锚点可回读
- mac（qvm）：
  - 对应镜像/板级配置可加载
  - 最小启动链不破坏 host-guest 契约
  - 失败必须标记为 escalate，不可静默跳过

本轮动作：完成“契约 gate 模板化 + 强制纳入里程碑完成条件”；后续每个里程碑按该模板补齐证据。

## 7) 接下来只允许的推进方式

1. 新改动必须先映射到 `reference` 或 `registry P1`。
2. 先写证据目标（readback 锚点），再实施改动。
3. 不以“脚本看起来跑通”作为成功标准，必须有独立回读。
4. 若遇 ABI/契约类不确定项，先标注并升级，不再临时扩展 staging 绕过。
