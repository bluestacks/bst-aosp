#
# Copyright 2022-2023 BlueStack Systems, Inc.
# All Rights Reserved
#
# THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF BLUESTACK SYSTEMS, INC.
# The copyright notice above does not evidence any actual or intended
# publication of such source code.
#

# Enable native bridge
WITH_NATIVE_BRIDGE := true

# Native Bridge ABI List
NATIVE_BRIDGE_ABI_LIST_32_BIT := armeabi-v7a armeabi
NATIVE_BRIDGE_ABI_LIST_64_BIT := arm64-v8a

PRODUCT_COPY_FILES := \
    $(LOCAL_PATH)/OEMBlackList:$(TARGET_COPY_OUT_VENDOR)/etc/misc/.OEMBlackList \
    $(LOCAL_PATH)/OEMWhiteList:$(TARGET_COPY_OUT_VENDOR)/etc/misc/.OEMWhiteList \
    $(LOCAL_PATH)/ThirdPartySO:$(TARGET_COPY_OUT_VENDOR)/etc/misc/.ThirdPartySO \

PRODUCT_PROPERTY_OVERRIDES += \
    ro.dalvik.vm.isa.arm=x86 \
    ro.enable.native.bridge.exec=1 \

ifeq ($(TARGET_SUPPORTS_64_BIT_APPS),true)
PRODUCT_PROPERTY_OVERRIDES += \
    ro.dalvik.vm.isa.arm64=x86_64 \
    ro.enable.native.bridge.exec64=1
endif

PRODUCT_PROPERTY_OVERRIDES += \
    ro.dalvik.vm.native.bridge=libnb.so \
    persist.sys.nativebridge=1

PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.dalvik.vm.native.bridge=libnb.so

PRODUCT_PACKAGES := libnb

