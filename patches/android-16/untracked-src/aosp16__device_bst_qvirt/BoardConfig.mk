#
# Copyright (C) 2026 The BlueStacks Project
#
# G1：qvirt 板配置。arch 按 TARGET_PRODUCT 分派（win bst_x86_64 / mac bst_arm64）。
#

ifneq ($(filter bst_arm64,$(TARGET_PRODUCT)),)
include device/generic/arm64/BoardConfig.mk
else
include device/generic/x86_64/BoardConfig.mk
endif
