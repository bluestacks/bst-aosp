# 启动 readback Oracle（Boot Oracles）

Layer 2 启动/行为验证的取数方式（见 [../.claude/rules/validation-gate.md](../.claude/rules/validation-gate.md)）。**时序前提**：host 最小实现已 port 入虚拟化（`qvm`/`vbox`），否则 Layer 2 不可用（Phase 1 仅 Layer 1）。

> 取数通道具体形态（adb / 串口 console / VMM 日志）**Phase 0 确认**后填。

| Oracle | 取数 | 正常态 | 异常=未通过 |
|---|---|---|---|
| Kernel boot log | 串口 console / `adb shell dmesg` | 走过 second_stage_init | 卡 first_stage_init / panic / oops |
| 分区 by-name symlink | `adb shell ls -l /dev/block/by-name/` | 各分区名有链接 | "partition not found" |
| 动态分区创建 | kernel log grep `CreateLogicalPartitions` | system/vendor/product 等创建成功 | super 元数据不匹配 |
| 分区挂载 | `adb shell mount` / `/proc/mounts` | 关键分区全挂载 | dm-verity 失败 / fs 不匹配 |
| init rc 解析 | `adb logcat` grep init/service | zygote/servicemanager/bootanim 启动 | 解析/exec 失败 |
| SELinux 域转换 | `adb logcat` grep `avc:` / `denied` | 无阻塞关键域的 enforce 拒绝 | 域转换 denied / label 错误 |
| vbmeta/verity | kernel log grep dm-verity/vbmeta | 校验通过或按策略跳过 | verity 校验失败挂起 |
| bootanim→launcher | `adb shell dumpsys SurfaceFlinger` / 截图 | 渲染出画面（结构容差比对，非单像素） | 黑屏 / 反复重启 |

## 完成判据

至少覆盖「分区挂载 + init 关键服务 + 无 SELinux 阻塞 + 启动到 launcher」才算 Layer 2 过。未跑全 → summary 标 `verification: build-only, boot-pending`。

## 截图 oracle 原则

禁单像素≠背景；期望图从源资产本征属性推导（不复用被测 renderer 布局参数），降采样到小网格做结构容差比对。
