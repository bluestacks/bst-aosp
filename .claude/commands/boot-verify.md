---
description: 取 kernel/串口 log，跑 Layer 2 启动 readback oracle 套件
allowed-tools: Bash(ssh:*), Bash(adb:*), Read, Write, Edit, Grep, Glob
---
跑 Layer 2 启动/行为验证（`.claude/rules/validation-gate.md`）。**时序前提**：host 最小实现已 port 入虚拟化（`qvm`/`vbox`）；否则报「Layer 2 不可用 — 虚拟化未就位，Phase 1 仅 Layer 1」并停。

## 取数通道（Phase 0 在 docs/boot-oracles.md 确定具体）

- kernel boot log：串口 console（`qvm`/`vbox` 串口）或 `adb shell dmesg`。
- logcat：`adb logcat`。
- 分区/挂载：`adb shell ls -l /dev/block/by-name/`、`adb shell mount`、`/proc/mounts`。
- 渲染：`adb shell dumpsys SurfaceFlinger`、截图。

## oracle 套件（逐项 pass/fail，结果写入 progress）

| Oracle | 正常态 | 异常=未通过 |
|---|---|---|
| Kernel boot log | 走过 second_stage_init | 卡 first_stage_init / panic |
| 分区 by-name symlink | 各分区名有链接 | "partition not found" |
| 动态分区创建 | system/vendor/product 等创建成功 | super 元数据不匹配 |
| 分区挂载 | 关键分区全挂载 | dm-verity 失败 / fs 不匹配 |
| init rc 解析 | zygote/servicemanager 启动 | 解析/exec 失败 |
| SELinux 域转换 | 无阻塞关键域的 enforce 拒绝 | 域转换 denied / label 错误 |
| vbmeta/verity | 校验通过或按策略跳过 | verity 挂起 |
| bootanim→launcher | 渲染出画面（结构容差比对，非单像素） | 黑屏 / 反复重启 |

## 完成判据

至少覆盖「分区挂载 + init 关键服务 + 无 SELinux 阻塞 + 启动到 launcher」才算 Layer 2 过。截图 oracle 按结构容差比对期望图，禁单像素≠背景。

## 记录

把每项 oracle 的取数片段与 pass/fail 写入 `progress/porting-log.md`（或该 patch 的 host-compat 行）；对应 registry 条目 `verified_layers` 加 `boot`。未跑全 → 标 boot-pending。
