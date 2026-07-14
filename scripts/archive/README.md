# scripts/archive/ — 历史一次性脚本

本目录存放 **A16 boot bringup 过程中已被取代或仅作溯源** 的脚本，**不要**再当作日常流水线入口。

| 类别 | 示例 | 说明 |
|---|---|---|
| 回合补丁 | `patch-round*.sh` | R11–R160 时代 initrd/boot 一次性 patch |
| 早期对齐 | `henry-*`、`apply-henry-*`、`rebuild-henry-align.sh` | 过程文档用名，解法已并入最终树/diff |
| init.sh/stage2 迭代 | `patch-initsh-*`、`patch-stage2-*` | 最终态在 `patches/android-16/bootimage/` |
| SELinux bringup bypass | `patch-selinux-*.py`、`r244-fix-*.py` | 完整源码构建后多数不再需要 |
| NVIDIA 规避（已回退） | `patch-hd-nvidia-*`、`patch-goldfish-egl-sf-fixdrawbuffer*` | 最终用 Intel Iris Xe |
| staging ART | `gen-boot-framework*`、`stage2-good-vhd.sh`、`cache-info-uffd-off.xml` | 战略放弃 runtime-staging |
| 中间 pack | `r229`–`r244`、`hotpatch-*`、`repack-*`、`incremental-*` | 被 `r228`/`r247` 打包链取代 |
| 错误回合 | `r252-patch-auth-services.py` | 误关 AuthService；正解见顶层 `r261-patch-auth-service.py` |

最终流水线与索引：[`../README.md`](../README.md)。
