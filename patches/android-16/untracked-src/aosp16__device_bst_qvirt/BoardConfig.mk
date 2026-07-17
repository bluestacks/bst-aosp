#
# Copyright (C) 2026 The BlueStacks Project
#
# G1（Phase 1）：qvirt 板配置。
# PRODUCT_DEVICE=qvirt → 构建在此解析 BoardConfig；直接复用已验证的 a16 generic x86_64 板配置，
# 保证与 android_x86_64 板参数一致（TARGET_ARCH=x86_64、kernel-a16、ext4、sepolicy dirs 等）。
# arch 差异（arm64）后续在此下沉：改为按 TARGET_ARCH 分派 generic/{x86_64,arm64} 板配置。
#

include device/generic/x86_64/BoardConfig.mk
