#
# BoardConfig.mk for x86 platform
#

TARGET_BOARD_PLATFORM := android-x86
# the following variables could be overridden
TARGET_PRELINK_MODULE := false
TARGET_NO_KERNEL ?= false
TARGET_NO_RECOVERY ?= true
#TARGET_EXTRA_KERNEL_MODULES := tp_smapi
ifneq ($(filter efi_img,$(MAKECMDGOALS)),)
TARGET_KERNEL_ARCH ?= x86_64
endif

DEVICE_MANIFEST_FILE := device/generic/common/manifest.xml
BOARD_KERNEL_CMDLINE := root=/dev/ram0$(if $(filter x86_64,$(TARGET_ARCH) $(TARGET_KERNEL_ARCH)),, vmalloc=192M)

BOARD_USES_GENERIC_KERNEL_IMAGE := false
# BOARD_BUILD_SYSTEM_ROOT_IMAGE removed in A16; keep android-x86 root/ layout in boot ramdisk (Tiramisu/BST second stage).
TARGET_COPY_OUT_RAMDISK := root

BUILD_BROKEN_USES_BUILD_HOST_EXECUTABLE := true
BUILD_BROKEN_USES_BUILD_HOST_STATIC_LIBRARY := true
# BST hd/ lives at ../hd relative to android tree (same as Tiramisu app-player layout).
BUILD_BROKEN_OUTSIDE_INCLUDE_DIRS := true
# libndk_baklava64 预编译 .so 仍通过 PRODUCT_COPY_FILES 安装（android-13 方式）
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
BUILD_BROKEN_PREBUILT_ELF_FILES := true
BOARD_SYSTEMIMAGE_PARTITION_RESERVED_SIZE := 33554432

BUILD_KERNEL_WITH_CLANG := true
KERNEL_DIR := kernel-a16
# BST bzImage does not embed IKCFG; point VINTF at the out-of-tree .config (see android-13 Makefile patch)
BOARD_KERNEL_CONFIG_FILE := $(PRODUCT_OUT)/obj/kernel/.config
# kati $(shell) has no `make` in PATH; parse kernel Makefile directly
BOARD_KERNEL_VERSION := $(shell awk '/^VERSION =/{v=$$3} /^PATCHLEVEL =/{p=$$3} /^SUBLEVEL =/{s=$$3} END{printf "%s.%s.%s", v, p, s}' $(KERNEL_DIR)/Makefile)

COMPATIBILITY_ENHANCEMENT_PACKAGE := true
PRC_COMPATIBILITY_PACKAGE := true
ZIP_OPTIMIZATION_NO_INTEGRITY := true


BOARD_SEPOLICY_DIRS += device/generic/common/sepolicy/nonplat \
                       system/bt/vendor_libs/linux/sepolicy


# Temporarily remove configs below, will check later if they are needed

# Some framework code requires this to enable BT
BOARD_HAVE_BLUETOOTH := true
BOARD_HAVE_BLUETOOTH_LINUX := true
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := device/generic/common/bluetooth

# Don't build emulator
BUILD_EMULATOR ?= false
BUILD_STANDALONE_EMULATOR ?= false
BUILD_EMULATOR_QEMUD ?= false
BUILD_EMULATOR_OPENGL ?= false
BUILD_EMULATOR_OPENGL_DRIVER ?= false
BUILD_EMULATOR_QEMU_PROPS ?= false
BUILD_EMULATOR_CAMERA_HAL ?= false
BUILD_EMULATOR_GPS_MODULE ?= false
BUILD_EMULATOR_LIGHTS_MODULE ?= false
BUILD_EMULATOR_SENSORS_MODULE ?= false

USE_OPENGL_RENDERER := true
NUM_FRAMEBUFFER_SURFACE_BUFFERS ?= 3
BOARD_USES_DRM_GRALLOC := false
BOARD_USES_DRM_HWCOMPOSER ?= true
USE_CAMERA_HAL3 ?= true
