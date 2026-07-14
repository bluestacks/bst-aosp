#
# Copyright (C) 2014-2019 The Android-x86 Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#

ifneq ($(TARGET_NO_KERNEL),true)
ifeq ($(TARGET_PREBUILT_KERNEL),)

# BST/android-x86 可编译内核（自 android-13 迁入），与 AOSP 原生 kernel/{configs,prebuilts,tests} 分离
KERNEL_DIR ?= kernel-a16

ifneq ($(filter x86%,$(TARGET_ARCH)),)
TARGET_KERNEL_ARCH ?= $(TARGET_ARCH)
# Linux Kbuild 使用 ARCH=x86；bzImage 在 arch/x86/boot/
KERNEL_MAKE_ARCH := x86
KERNEL_TARGET := bzImage
TARGET_KERNEL_CONFIG ?= bst-$(TARGET_KERNEL_ARCH)_defconfig
KERNEL_CONFIG_DIR := arch/x86/configs
endif

KTOOLS := prebuilts/ktools
KERN_BUILD_TOOLS_BIN := $(KTOOLS)/kernel-build-tools/linux-x86/bin
KBUILD_OUTPUT := $(TARGET_OUT_INTERMEDIATES)/kernel

# 宿主机脚本(fixdep 等)：须用绝对路径（ninja 子进程 PATH 不含 /usr/bin）
KERNEL_HOST_GCC := /usr/bin/gcc
KERNEL_HOST_GXX := /usr/bin/g++
KERNEL_HOST_FLAGS := HOSTCC=$(KERNEL_HOST_GCC) HOSTCXX=$(KERNEL_HOST_GXX) HOSTLD=$(KERNEL_HOST_GCC)
KERNEL_BUILD_PATH := /usr/bin:/bin:/sbin:$(KERN_BUILD_TOOLS_BIN)
KERNEL_CLANG_CLAGS := $(KERNEL_HOST_FLAGS)
ifeq ($(BUILD_KERNEL_WITH_CLANG),true)
$(info "build kernel with clang")
KERNEL_CLANG_CLAGS += CC=$(abspath $(LLVM_PREBUILTS_PATH)/clang) LD=$(abspath $(LLVM_PREBUILTS_PATH)/ld.lld) CLANG_TRIPLE=x86_64-linux-gnu-
endif

KBUILD_JOBS := $(shell echo $$((1-(`cat /sys/devices/system/cpu/present`))))

mk_kernel := + prebuilts/build-tools/$(HOST_PREBUILT_TAG)/bin/make -j$(KBUILD_JOBS) \
	AR=$(abspath $(LLVM_PREBUILTS_PATH)/llvm-ar) \
	HOSTAR=$(abspath $(LLVM_PREBUILTS_PATH)/llvm-ar) \
	NM=$(abspath $(LLVM_PREBUILTS_PATH)/llvm-nm) \
	STRIP=$(abspath $(LLVM_PREBUILTS_PATH)/llvm-strip) \
	OBJCOPY=$(abspath $(LLVM_PREBUILTS_PATH)/llvm-objcopy) \
	OBJDUMP=$(abspath $(LLVM_PREBUILTS_PATH)/llvm-objdump) \
	READELF=$(abspath $(LLVM_PREBUILTS_PATH)/llvm-readelf) \
	-C $(KERNEL_DIR) O=$(abspath $(KBUILD_OUTPUT)) ARCH=$(KERNEL_MAKE_ARCH)  $(if $(SHOW_COMMANDS),V=1) \
	YACC=prebuilts/build-tools/$(HOST_PREBUILT_TAG)/bin/bison \
	LEX=prebuilts/build-tools/$(HOST_PREBUILT_TAG)/bin/flex \
	M4=prebuilts/build-tools/$(HOST_PREBUILT_TAG)/bin/m4 DEPMOD=/sbin/depmod \
	PATH=$(KERNEL_BUILD_PATH):$$PATH  \
	$(KERNEL_CLANG_CLAGS)

bk_kernel := + prebuilts/build-tools/$(HOST_PREBUILT_TAG)/bin/make -j$(KBUILD_JOBS)  CC=$(abspath $(LLVM_PREBUILTS_PATH)/clang) \
	LD=$(abspath $(LLVM_PREBUILTS_PATH)/ld.lld) \
	AR=$(abspath $(LLVM_PREBUILTS_PATH)/llvm-ar) \
	HOSTAR=$(abspath $(LLVM_PREBUILTS_PATH)/llvm-ar) \
	NM=$(abspath $(LLVM_PREBUILTS_PATH)/llvm-nm) \
	STRIP=$(abspath $(LLVM_PREBUILTS_PATH)/llvm-strip) \
	OBJCOPY=$(abspath $(LLVM_PREBUILTS_PATH)/llvm-objcopy) \
	OBJDUMP=$(abspath $(LLVM_PREBUILTS_PATH)/llvm-objdump) \
	READELF=$(abspath $(LLVM_PREBUILTS_PATH)/llvm-readelf) \
	-C $(KERNEL_DIR) O=$(abspath $(KBUILD_OUTPUT)) ARCH=$(KERNEL_MAKE_ARCH)  $(if $(SHOW_COMMANDS),V=1)  \
	YACC=prebuilts/build-tools/$(HOST_PREBUILT_TAG)/bin/bison \
	LEX=prebuilts/build-tools/$(HOST_PREBUILT_TAG)/bin/flex \
	M4=prebuilts/build-tools/$(HOST_PREBUILT_TAG)/bin/m4 DEPMOD=/sbin/depmod \
	PATH=$(KERNEL_BUILD_PATH):$$PATH \
	$(KERNEL_CLANG_CLAGS)

KERNEL_CONFIG_FILE := $(if $(wildcard $(TARGET_KERNEL_CONFIG)),$(TARGET_KERNEL_CONFIG),$(KERNEL_DIR)/$(KERNEL_CONFIG_DIR)/$(TARGET_KERNEL_CONFIG))
$(info KERNEL_CONFIG_FILE: $(KERNEL_CONFIG_FILE))

MOD_ENABLED := $(shell grep ^CONFIG_MODULES=y $(KERNEL_CONFIG_FILE))
FIRMWARE_ENABLED := $(shell grep ^CONFIG_FIRMWARE_IN_KERNEL=y $(KERNEL_CONFIG_FILE))

# I understand Android build system discourage to use submake,
# but I don't want to write a complex Android.mk to build kernel.
# This is the simplest way I can think.
KERNEL_DOTCONFIG_FILE := $(KBUILD_OUTPUT)/.config
ifneq ($(filter 0,$(shell grep -s ^$(if $(filter x86,$(TARGET_KERNEL_ARCH)),\#.)CONFIG_64BIT $(KERNEL_DOTCONFIG_FILE) | wc -l)),)
KERNEL_ARCH_CHANGED := $(KERNEL_DOTCONFIG_FILE)-
$(KERNEL_ARCH_CHANGED):
		@touch $@
endif

$(KERNEL_DOTCONFIG_FILE): $(KERNEL_CONFIG_FILE) $(wildcard $(TARGET_KERNEL_DIFFCONFIG)) $(KERNEL_ARCH_CHANGED)
	mkdir -p $(@D) && cat $(wildcard $^) > $@
	ln -sf ../../../../../../prebuilts $(@D)
	rm -f $(KERNEL_ARCH_CHANGED)

	$(info debug-> mk_kernel: $(mk_kernel))
	$(info debug-> LLVM_PREBUILTS_PATH: $(LLVM_PREBUILTS_PATH))
BUILT_KERNEL_TARGET := $(KBUILD_OUTPUT)/arch/$(KERNEL_MAKE_ARCH)/boot/$(KERNEL_TARGET)
$(BUILT_KERNEL_TARGET): $(KERNEL_DOTCONFIG_FILE)
	# A dirty hack to use ar & ld
	$(hide) mkdir -p $(OUT_DIR)/.path; ln -sf ../../$(LLVM_PREBUILTS_PATH)/llvm-ar $(OUT_DIR)/.path/ar; ln -sf ../../$(LLVM_PREBUILTS_PATH)/ld.lld $(OUT_DIR)/.path/ld
ifeq ($(BUILD_KERNEL_WITH_CLANG),true)
	$(info TARGET_TOOLS_PREFIX=$(TARGET_TOOLS_PREFIX))
	cd $(OUT_DIR)/.path; ln -sf ../../$(dir $(TARGET_TOOLS_PREFIX))x86_64-linux-androidkernel-* .; ln -sf x86_64-linux-androidkernel-as x86_64-linux-gnu-as
endif

	$(mk_kernel) olddefconfig
	$(info debug-> bk_kernel: $(bk_kernel) $(KERNEL_TARGET))
	$(bk_kernel) $(KERNEL_TARGET) $(if $(MOD_ENABLED),modules)
	$(if $(FIRMWARE_ENABLED),$(bk_kernel) INSTALL_MOD_PATH=$(abspath $(TARGET_OUT)) firmware_install)

ifneq ($(MOD_ENABLED),)
KERNEL_MODULES_DEP := $(firstword $(wildcard $(TARGET_OUT)/lib/modules/*/modules.dep))
KERNEL_MODULES_DEP := $(if $(KERNEL_MODULES_DEP),$(KERNEL_MODULES_DEP),$(TARGET_OUT)/lib/modules)

ALL_EXTRA_MODULES := $(patsubst %,$(TARGET_OUT_INTERMEDIATES)/kmodule/%,$(TARGET_EXTRA_KERNEL_MODULES))
$(ALL_EXTRA_MODULES): $(TARGET_OUT_INTERMEDIATES)/kmodule/%: $(BUILT_KERNEL_TARGET) | $(ACP)
	@echo Building additional kernel module $*
	$(hide) mkdir -p $(@D) && $(ACP) -fr $(EXTRA_KERNEL_MODULE_PATH_$*) $(@D)
	$(bk_kernel) M=$(abspath $@) modules || ( rm -rf $@ && exit 1 )

$(KERNEL_MODULES_DEP): $(BUILT_KERNEL_TARGET) $(ALL_EXTRA_MODULES)
	$(hide) rm -rf $(TARGET_OUT)/lib/modules
	$(bk_kernel) INSTALL_MOD_PATH=$(abspath $(TARGET_OUT)) modules_install
	+ $(hide) for kmod in $(TARGET_EXTRA_KERNEL_MODULES) ; do \
		echo Installing additional kernel module $${kmod} ; \
		$(subst +,,$(subst $(hide),,$(bk_kernel))) INSTALL_MOD_PATH=$(abspath $(TARGET_OUT)) M=$(abspath $(TARGET_OUT_INTERMEDIATES))/kmodule/$${kmod} modules_install ; \
	done
	$(hide) rm -f $(TARGET_OUT)/lib/modules/*/{build,source}
endif

installclean: FILES += $(KBUILD_OUTPUT) $(INSTALLED_KERNEL_TARGET)

TARGET_PREBUILT_KERNEL := $(BUILT_KERNEL_TARGET)

.PHONY: kernel
kernel: $(INSTALLED_KERNEL_TARGET) $(KERNEL_MODULES_DEP)

endif # TARGET_PREBUILT_KERNEL

ifndef LINEAGE_BUILD
$(INSTALLED_KERNEL_TARGET): $(TARGET_PREBUILT_KERNEL) | $(ACP)
	$(copy-file-to-new-target)
ifdef TARGET_PREBUILT_MODULES
	mkdir -p $(TARGET_OUT)/lib
	$(hide) cp -r $(TARGET_PREBUILT_MODULES) $(TARGET_OUT)/lib
endif
endif # LINEAGE_BUILD
endif # KBUILD_OUTPUT
