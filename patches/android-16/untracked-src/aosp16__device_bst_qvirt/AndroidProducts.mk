#
# Copyright (C) 2026 The BlueStacks Project
#
# 统一板 device/bst/qvirt 的产品入口。
# Phase 1 / G1：win 先行的 bst_x86_64；mac 后续在此加 bst_arm64（同板、arch 差异下沉）。
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/bst_x86_64.mk

COMMON_LUNCH_CHOICES := \
    bst_x86_64-trunk_staging-eng \
    bst_x86_64-trunk_staging-user \
    bst_x86_64-trunk_staging-userdebug
