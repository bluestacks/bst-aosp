SHELL := /bin/bash
BUILD_SCRIPT_PATH := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
export PATH := $(BUILD_SCRIPT_PATH)bin:$(PATH)
BASEPATH := $(shell dirname $(BUILD_SCRIPT_PATH))
ANDROID_SDK_PATH := /home/build/workspace/android-sdk/sdk
MAKE_TARGET_BOOT_ISO := Boot.iso MAKEFLAGS=
IS_HYPERV_BUILD := $(IS_HYPERV_BUILD)
OUTPUTDIR := $(ANDROIDOUTPUTLOC)/$(IMAGE)
OUT_PATH := out_$(OEM)_$(IMAGE)
ifneq (,$(findstring Nougat,$(IMAGE)))
ANDROID_VERSION := nougat
ANDROIDHOME := $(BASEPATH)/android
GOLDFISH_OPENGL := ggl/goldfish-opengl/
else ifneq (,$(findstring Pie,$(IMAGE)))
ANDROID_VERSION := pie
ANDROIDHOME := $(BASEPATH)/android-9
GOLDFISH_OPENGL := ggl/goldfish-opengl-pie/
else ifneq (,$(findstring Rvc,$(IMAGE)))
ANDROID_VERSION := rvc
ANDROIDHOME := $(BASEPATH)/android-11
GOLDFISH_OPENGL := ggl/goldfish-opengl-pie/
else ifneq (,$(findstring Baklava,$(IMAGE)))
ANDROID_VERSION := baklava
ANDROIDHOME := $(BASEPATH)/android-16
GOLDFISH_OPENGL := ggl/goldfish-opengl-pie/
else
ANDROID_VERSION := tiramisu
ANDROIDHOME := $(BASEPATH)/android-13
GOLDFISH_OPENGL := ggl/goldfish-opengl-pie/
endif
ifneq (,$(findstring 64,$(IMAGE)))
IS_64_BUILD := 1
ANDROIDOUT := $(ANDROIDHOME)/$(OUT_PATH)/target/product/x86_64
x86_64_SRC_LIBS_DIR := $(ANDROIDOUT)/system/lib64
OUTPUTDIR_x86_64_LIBS := $(OUTPUTDIR)/system/lib64
PROPFILES := $(BASEPATH)/scratch-gaurav/misc_x86_64/$(ANDROID_VERSION)
THIRD_PARTY_BT_LIBS_DIR := $(BASEPATH)/3bt/$(ANDROID_VERSION)64/
G_P_STUFF := $(BASEPATH)/scratch-gaurav/gapps_$(ANDROID_VERSION)64/
ANDROID_TARGET := android_x86_64
LOCATION := amd64
BST_USE_JEMALLOC := true
CPUINFO_DIR := $(BASEPATH)/3bt/cpuinfo/$(ANDROID_VERSION)64/
ifeq ($(IS_HYPERV_BUILD),1)
TARGET := android_x86_64-eng_hyperv
else ifeq ($(ANDROID_VERSION),baklava)
TARGET := android_x86_64-trunk_staging-eng
else
TARGET := android_x86_64-eng
endif
ifeq ($(ANDROID_VERSION),nougat)
ROOTSIZE := 2621440
else ifeq ($(ANDROID_VERSION),baklava)
ROOTSIZE := 6291456
else
ROOTSIZE := 2621440
MAKE_TARGET += all VBOX_KBUILD_TARGET_ARCH=x86_64 ARCH=x86_64
endif
else
IS_64_BUILD := 0
ANDROIDOUT := $(ANDROIDHOME)/$(OUT_PATH)/target/product/x86
ROOTSIZE := 1945600
PROPFILES := $(BASEPATH)/scratch-gaurav/misc_x86/$(ANDROID_VERSION)
THIRD_PARTY_BT_LIBS_DIR := $(BASEPATH)/3bt/$(ANDROID_VERSION)/
G_P_STUFF := $(BASEPATH)/scratch-gaurav/gapps_$(ANDROID_VERSION)/
TARGET := android_x86-eng
ANDROID_TARGET := android_x86
LOCATION := x86
MAKE_TARGET_BOOT_ISO += VBOX_KBUILD_TARGET_ARCH=x86 
BST_USE_JEMALLOC := false
CPUINFO_DIR := $(BASEPATH)/3bt/cpuinfo/$(ANDROID_VERSION)/
ifeq ($(ANDROID_VERSION),nougat)
MAKE_TARGET += VBOX_KBUILD_TARGET_ARCH=x86
else
MAKE_TARGET += all VBOX_KBUILD_TARGET_ARCH=x86 ARCH=x86
endif
endif

ifeq ($(ANDROID_VERSION),tiramisu)
CLANG_PREBUILT_BIN := $(ANDROIDHOME)/prebuilts/clang/host/linux-x86/clang-r450784d/bin
else ifeq ($(ANDROID_VERSION),baklava)
CLANG_PREBUILT_BIN := $(ANDROIDHOME)/prebuilts/clang/host/linux-x86/clang-r563880/bin
else
CROSS_COMPILER := $(ANDROIDHOME)/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.11-4.6/bin/x86_64-linux-
endif
x86_SRC_LIBS_DIR := $(ANDROIDOUT)/system/lib
OUTPUTDIR_x86_LIBS := $(OUTPUTDIR)/system/lib
VBOX_GUEST_ADDITIONS_LOC := $(BASEPATH)/vbox-guest-additions
IMAGE_TO_LOWER := $(shell echo $(IMAGE) | tr '[:upper:]' '[:lower:]')
APPCONFFILE := $(BASEPATH)/bst/apks/$(ANDROID_VERSION)/$(ANDROID_VERSION)_appPlayerApksToInstall_$(OEM)_$(IMAGE_TO_LOWER)
TOYBOX := $(ANDROIDHOME)/external/toybox
SENSORS_DEFAULT := $(ANDROIDHOME)/external/bluestacks/sensors
HD_SOURCE_TOP_PATH := $(BASEPATH)/hd
OPENGL_DIR := $(BASEPATH)/opengl/Client
BSTTOOLS := $(BASEPATH)/tools
BSTBIN := $(BASEPATH)/bst/bin
BUILDPROPFILE := $(PROPFILES)/$(ANDROID_VERSION).bluestacks.prop.us
OLD_THIRD_PARTY_BT_LIBS_DIR := $(BASEPATH)/3bt/nougat_old/
HOUDINI_7_1_1c_50033 := $(BASEPATH)/3bt/bt_7.1.1c.50033/
APKFOLDER := $(BASEPATH)/bst/apks_$(IMAGE)
BSTMODULES := $(BASEPATH)/hd/Linux/Modules
SCRATCH_ROSEN := $(BASEPATH)/scratch-rosen
NOWGG_COMMON := $(BASEPATH)/nowgg-common
FEATUREFILES := $(BASEPATH)/scratch-gaurav/feature_files
GGL_LIBS := $(BASEPATH)/ggl/external/qemu/
BIONIC_LIBC := $(ANDROIDHOME)/bionic/libc
FRAMEWORKS_AV := $(ANDROIDHOME)/frameworks/av

DATASIZE := 720896
ifeq ($(ANDROID_VERSION),baklava)
DATASIZE := 1572864
endif
MOUNT_POINT := dataFS

ifndef PARALLEL_NX_PROC
	numproc := $(shell expr `nproc` \* 3 / 2)
else
	numproc := $(shell echo "$$(nproc) * $(PARALLEL_NX_PROC) / 1" | bc)
endif

BST_BUILD_WITH_DEXPREOPT := $(ENABLE_DEXOPT)
PKG_DEBUG=$(PKG)-debug

OEM_nxt_ROOTED_BIND := 1
OEM_nxt_cn_ROOTED_BIND := 1

DATA_FS := datafs

ifeq ($(OEM_$(OEM)_MACHOST),1)
VBOX_VERSION := 5.2.20
IS_MAC_BUILD := 1
else
VBOX_VERSION := 7.0.8
IS_MAC_BUILD := 0
endif

.PHONY: apks android hyperv vbox

hyperv: Root.vdi kernel_and_initrd
	@echo "Target hyperv has started $$(date +%H:%M:%S)"
	@echo "Compressing target files : $(OUTPUTDIR)/$(PKG)"
	@echo "Target hyperv has been completed $$(date +%H:%M:%S)"

vbox: Root.vdi fastboot.vdi
	@echo "Target vbox has started $$(date +%H:%M:%S)"
	@echo "Compressing target files : $(OUTPUTDIR)/$(PKG)"
	@echo "Target vbox has been completed $$(date +%H:%M:%S)"

Root.vdi: android libs apks $(DATA_FS)
	@echo "Target Root.vdi has started, $$(date +%H:%M:%S)"
	$(call  copy_android_files_to_outputdir)
ifeq ($(ANDROID_VERSION),nougat)
	$(call 	build_alternate_memalloc)
	$(call	remove_debug_tools_and_apps_from_outputdir)
endif
	$(call	copy_system_apks)
#$(call	copy_misc_system_framework_files)
ifneq (,$(filter pie baklava,$(ANDROID_VERSION)))
	$(call	copy_gms_permission_files)
endif
	$(call	create_setuid_su_binary)
	$(call	copy,$(BSTTOOLS)/cpu,$(OUTPUTDIR)/system/etc/.cpu/)
	$(call	copy,$(BSTTOOLS)/power_supply,$(OUTPUTDIR)/system/etc/power_supply/)
	$(call	copy,$(BSTTOOLS)/mounts,$(OUTPUTDIR)/system/etc/mounts)
	$(call  copy,$(BSTTOOLS)/zerofree,$(OUTPUTDIR)/system/bin/)
	$(call  copy,$(BSTBIN)/mountsf,$(OUTPUTDIR)/system/bin/)
	$(call  copy,$(BSTBIN)/mount.vboxsf,$(OUTPUTDIR)/system/bin/mountvsf)
	$(call  copy,$(BSTBIN)/logcat_redirection,$(OUTPUTDIR)/system/bin/)
	$(call  copy,$(BSTBIN)/install_studio_zip,$(OUTPUTDIR)/system/bin/)
	$(call  copy,$(BSTBIN)/bst_getevents,$(OUTPUTDIR)/system/bin/)
	$(call  copy,$(BSTBIN)/jq,$(OUTPUTDIR)/system/bin/)
	$(call  copy,$(BUILDPROPFILE),$(OUTPUTDIR)/system/build.prop)
	$(call	copy_3bt_libs)
	@echo "Prebundled component has started for OEM=$(OEM), $$(date +%H:%M:%S)"
	$(shell mkdir -p $(OUTPUTDIR))
	$(call create_dataFS_dir_structure,$(MOUNT_POINT))
	$(call copy_data_apks,$(MOUNT_POINT))
	$(call copy_propfiles,$(MOUNT_POINT))
ifeq ($(ANDROID_VERSION),tiramisu)
	$(call	copy,$(BSTTOOLS)/security/config_a13/.swl.cfg,$(OUTPUTDIR)/system/etc/)
	$(call	copy,$(BSTTOOLS)/security/config_a13/.swl.cfg.sig,$(OUTPUTDIR)/system/etc/)
else ifeq ($(ANDROID_VERSION),baklava)
	$(call	copy,$(BSTTOOLS)/security/config_a13/.swl.cfg,$(OUTPUTDIR)/system/etc/)
	$(call	copy,$(BSTTOOLS)/security/config_a13/.swl.cfg.sig,$(OUTPUTDIR)/system/etc/)
else
	$(call	copy,$(BSTTOOLS)/security/config/.swl.cfg,$(OUTPUTDIR)/system/etc/)
	$(call	copy,$(BSTTOOLS)/security/config/.swl.cfg.sig,$(OUTPUTDIR)/system/etc/)
endif
ifeq ($(ANDROID_VERSION),rvc)
	$(call  copy,$(PROPFILES)/additional_system_props,$(OUTPUTDIR)/$(MOUNT_POINT)/propfiles)
endif
ifeq ($(ANDROID_VERSION),tiramisu)
	$(call  copy,$(PROPFILES)/additional_system_props,$(OUTPUTDIR)/$(MOUNT_POINT)/propfiles)
endif
ifeq ($(ANDROID_VERSION),baklava)
	$(call  copy,$(PROPFILES)/additional_system_props,$(OUTPUTDIR)/$(MOUNT_POINT)/propfiles)
endif
	$(call copy_feature_files,$(MOUNT_POINT))
	$(call copy_appdetails,$(MOUNT_POINT))
	$(call copy_misc_data_downloads_files,$(MOUNT_POINT))
ifeq ($(OEM_$(OEM)_ROOTED_BIND),1)
	@echo "Copying xbin folder for rooted OEM=$(OEM), $$(date +%H:%M:%S)"
	$(call copy,$(OUTPUTDIR)/system/xbin,$(OUTPUTDIR)/$(MOUNT_POINT)/downloads/.xb)
	$(call copy,$(OUTPUTDIR)/$(MOUNT_POINT)/downloads/.xb/bstk/su,$(OUTPUTDIR)/$(MOUNT_POINT)/downloads/.xb/)
endif
ifeq ($(ANDROID_VERSION),nougat)
	@echo "Copying older_3bt folder"
	$(call copy, $(OLD_THIRD_PARTY_BT_LIBS_DIR)/*,$(OUTPUTDIR)/$(MOUNT_POINT)/downloads/.oh/)
ifeq ($(IS_64_BUILD),0)
	@echo "Removing lib64 folder for 32 bit builds, IS_64_BUILD = $(IS_64_BUILD)"
	rm -rf $(OUTPUTDIR)/$(MOUNT_POINT)/downloads/.oh/lib64
else
	@echo "Copying 7.1.1c.50033 3bt libs for 64 bit build"
	$(shell mkdir -p $(OUTPUTDIR)/$(MOUNT_POINT)/downloads/.ohi/ || (sudo umount -d $(OUTPUTDIR)/$(MOUNT_POINT) > /dev/null; exit 1))
	$(shell chmod 775 $(OUTPUTDIR)/$(MOUNT_POINT)/downloads/.ohi/ ||  (sudo umount -d $(OUTPUTDIR)/$(MOUNT_POINT)> /dev/null; exit 1))
	$(call copy, $(HOUDINI_7_1_1c_50033)/*,$(OUTPUTDIR)/$(MOUNT_POINT)/downloads/.ohi/)
endif
endif
	$(call create_cpuinfo_files)
	$(call copy, $(CPUINFO_DIR)/*,$(OUTPUTDIR)/$(MOUNT_POINT)/downloads/.oh/)
	$(call set_ownership_for_dataFS_dirs,$(MOUNT_POINT))
ifeq ($(BST_BUILD_WITH_DEXPREOPT),true)
	(cd $(BUILD_SCRIPT_PATH) && bash -x odex_script.sh $(OUTPUTDIR) $(OEM) $(MOUNT_POINT) $(IMAGE) $(IS_64_BUILD) || exit 1)
endif
ifeq ($(ANDROID_VERSION),baklava)
	# BS-A16: Fix permissions on soong-generated text files (default to 600).
	# Without this, non-root processes cannot read llndk.libraries.txt -> abort.
	sudo -n chmod 644 $(OUTPUTDIR)/system/etc/llndk.libraries.txt 2>/dev/null || true
	sudo -n chmod 644 $(OUTPUTDIR)/system/etc/sanitizer.libraries.txt 2>/dev/null || true
	# BS-A16: Fix permissions on soong-generated permission XML files (default to 600).
	# Without this, SystemConfig cannot read <library> declarations (e.g.
	# org.apache.http.legacy.xml) -> shared libraries not registered -> apps
	# get NoClassDefFoundError. A13 had these as 664 system:system.
	sudo -n chmod 644 $(OUTPUTDIR)/system/etc/permissions/*.xml 2>/dev/null || true
	sudo -n chown -R 1000:1000 $(OUTPUTDIR)/system $(OUTPUTDIR)/boot 2>/dev/null || true
endif
	@echo "Prebundled component has been completed for OEM=$(OEM), $$(date +%H:%M:%S)"
	$(call  create_rootfs,Root.fs,rootFS,system,$(MOUNT_POINT))
	$(call	copy,$(OUTPUTDIR)/root,$(OUTPUTDIR)/rooted_root)
	$(call	copy,$(OUTPUTDIR)/system,$(OUTPUTDIR)/rooted_system)
	$(call  create_rootfs,Root.fs.debug,rootFSDebug,rooted_system,$(MOUNT_POINT))
	@echo "Packaging completed for Root.fs"
ifeq ($(OEM_$(OEM)_ROOTED),1)
	@echo "creating Root.fs.rooted for OEM: $(OEM)"
	$(call	create_rootfs,Root.fs.rooted,rootFS,rooted_system,$(MOUNT_POINT))
	@echo "Packaging completed for Root.fs.rooted"
	@echo "Making Rooted vdi for OEM: $(OEM)"
	$(call	make_vdi_file,Root.fs.rooted,root,$(OUTPUTDIR)/$(PKG))
	mv $(OUTPUTDIR)/$(PKG)/Root.rooted.vhd $(OUTPUTDIR)/$(PKG)/Root.vhd
	@echo "Rooted vdi completed for OEM: $(OEM)"
else
	@echo "Making Non-Rooted vdi for OEM: $(OEM)"
	$(call	make_vdi_file,Root.fs,root,$(OUTPUTDIR)/$(PKG))
	$(call	make_vdi_file,Root.fs.debug,root,$(OUTPUTDIR)/$(PKG_DEBUG))
	@echo "Non-Rooted vdi completed for OEM: $(OEM)"
endif
	@echo "Target Root.vdi has been completed, $$(date +%H:%M:%S)"

Boot.iso: android
	@echo "Target Boot.iso has started, $$(date +%H:%M:%S)"
	#(cd $(ANDROIDOUT)/obj/kernel && $(MAKE) modules SUBDIRS=drivers/media/v4l2-core -j$(numproc) || exit 1)
	(cd $(BASEPATH)/hd/guest && export KDIR=$(ANDROIDOUT)/obj/kernel \
		&& export VBOX_GUEST_ADDITIONS=$(VBOX_GUEST_ADDITIONS_LOC)/$(LOCATION)/src/vboxguest-$(VBOX_VERSION)  \
		&& export KERN_DIR=$(ANDROIDOUT)/obj/kernel \
		&& export OEM=$(OEM) \
		&& export IMAGE=$(IMAGE) \
		&& export IS_64_BUILD=$(IS_64_BUILD) \
		&& export HD_SOURCE_TOP=$(BASEPATH)/hd \
		&& $(MAKE) clean && $(MAKE) $(MAKE_TARGET) || exit 1)
	mkdir -p $(OUTPUTDIR)/$(PKG)
	$(call	copy,$(BASEPATH)/hd/guest/BootImage/Boot.iso,$(OUTPUTDIR)/$(PKG)/Boot.iso)
	@echo "Target Boot.iso has been completed, $$(date +%H:%M:%S)"

fastboot.vdi: libs
	@echo "Target fastboot.vdi has started, $$(date +%H:%M:%S)"
	cp $(ANDROIDOUT)/system/out_bstconf/bstconf $(BASEPATH)/hd/guest/BootImage/ || exit 1
	cp $(ANDROIDOUT)/system/out_bstchkdata/bstchkdata $(BASEPATH)/hd/guest/BootImage/ || exit 1
ifeq ($(ANDROID_VERSION),nougat)
	(cd $(BASEPATH)/hd/guest && export KDIR=$(ANDROIDOUT)/obj/kernel \
		&& export VBOX_GUEST_ADDITIONS=$(VBOX_GUEST_ADDITIONS_LOC)/$(LOCATION)/src/vboxguest-$(VBOX_VERSION) \
		&& export KERN_DIR=$(ANDROIDOUT)/obj/kernel \
		&& export OEM=$(OEM) \
		&& export IMAGE=$(IMAGE) \
		&& export IS_64_BUILD=$(IS_64_BUILD) \
		&& export HD_SOURCE_TOP=$(BASEPATH)/hd \
		&& $(MAKE) clean && $(MAKE) $(MAKE_TARGET) || exit 1)
else ifeq ($(ANDROID_VERSION),tiramisu)
	(cd $(BASEPATH)/hd/guest && export KDIR=$(ANDROIDOUT)/obj/kernel \
		&& export VBOX_GUEST_ADDITIONS=$(VBOX_GUEST_ADDITIONS_LOC)/$(LOCATION)/src/vboxguest-$(VBOX_VERSION) \
		&& export KERN_DIR=$(ANDROIDOUT)/obj/kernel \
		&& export OEM=$(OEM) \
		&& export IMAGE=$(IMAGE) \
		&& export IS_64_BUILD=$(IS_64_BUILD) \
		&& export HD_SOURCE_TOP=$(BASEPATH)/hd \
		&& export PATH=$(shell echo "$(CLANG_PREBUILT_BIN):$(PATH)") \
		&& $(MAKE) MAKEFLAGS= $(MAKE_TARGET) LLVM=1 -j$(numproc) || exit 1)
else ifeq ($(ANDROID_VERSION),baklava)
	(cd $(BASEPATH)/hd/guest && export KDIR=$(ANDROIDOUT)/obj/kernel \
		&& export VBOX_GUEST_ADDITIONS=$(VBOX_GUEST_ADDITIONS_LOC)/$(LOCATION)/src/vboxguest-$(VBOX_VERSION) \
		&& export KERN_DIR=$(ANDROIDOUT)/obj/kernel \
		&& export OEM=$(OEM) \
		&& export IMAGE=$(IMAGE) \
		&& export IS_64_BUILD=$(IS_64_BUILD) \
		&& export HD_SOURCE_TOP=$(BASEPATH)/hd \
		&& export PATH=$(shell echo "$(CLANG_PREBUILT_BIN):$(PATH)") \
		&& $(MAKE) MAKEFLAGS= $(MAKE_TARGET) LLVM=1 -j$(numproc) || exit 1)
else
	(cd $(BASEPATH)/hd/guest && export KDIR=$(ANDROIDOUT)/obj/kernel \
		&& export VBOX_GUEST_ADDITIONS=$(VBOX_GUEST_ADDITIONS_LOC)/$(LOCATION)/src/vboxguest-$(VBOX_VERSION) \
		&& export KERN_DIR=$(ANDROIDOUT)/obj/kernel \
		&& export OEM=$(OEM) \
		&& export IMAGE=$(IMAGE) \
		&& export IS_64_BUILD=$(IS_64_BUILD) \
		&& export HD_SOURCE_TOP=$(BASEPATH)/hd \
		&& $(MAKE) clean && $(MAKE) MAKEFLAGS= $(MAKE_TARGET) CROSS_COMPILE=$(CROSS_COMPILER) || exit 1)
endif
	mkdir -p $(OUTPUTDIR)/$(PKG)
	$(call	copy,$(BASEPATH)/hd/guest/BootImage/fastboot/fastboot.vdi,$(OUTPUTDIR)/$(PKG)/fastboot.vdi)
	@echo "Target fastboot.vdi has been completed, $$(date +%H:%M:%S)"

fastboot.vhd: kernel
	@echo "Target fastboot.vhd has started, $$(date +%H:%M:%S)"
	#(cd $(ANDROIDOUT)/obj/kernel && $(MAKE) modules SUBDIRS=drivers/media/v4l2-core -j$(numproc) || exit 1)
#(cd $(BASEPATH)/hd/guest && export KDIR=$(ANDROIDOUT)/obj/kernel \
		&& export OEM=$(OEM) && IS_64_BUILD=$(IS_64_BUILD) && $(MAKE) clean && $(MAKE) $(MAKE_TARGET) || exit 1)
	export KDIR=$(ANDROIDOUT)/kout; cd $(BASEPATH)/hd/guest; make clean all
	mkdir -p $(OUTPUTDIR)/$(PKG)
	$(call copy,$(BASEPATH)/hd/guest/BootEFI/fastboot.vhd,$(OUTPUTDIR)/$(PKG)/fastboot.vhd)
	@echo "Target fastboot.vhd has been completed, $$(date +%H:%M:%S)"

kernel_and_initrd: kernel
	@echo "Target kernel_and_initrd has started, $$(date +%H:%M:%S)"
	$(call export_env); \
	export KDIR=$(ANDROIDOUT)/kout; cd $(BASEPATH)/hd/guest; make clean hyperv
	mkdir -p $(OUTPUTDIR)/$(PKG)
	KDIR=$(ANDROIDOUT)/kout; \
	cp $$KDIR/arch/x86/boot/bzImage $(OUTPUTDIR)/$(PKG)/bzImage_hyperv
	$(call copy,$(BASEPATH)/hd/guest/BootImage/initrd.img,$(OUTPUTDIR)/$(PKG)/initrd_hyperv.img)
	@echo "Target kernel_and_initrd has completed, $$(date +%H:%M:%S)"

kernel:
	@echo "Target kernel has started, $$(date +%H:%M:%S)"
	mkdir -p $(ANDROIDOUT)/kout
ifeq ($(ANDROID_VERSION),nougat)
	$(call export_env); \
	KDIR=$(ANDROIDHOME)/kernel64-hyperv ; cd $(BASEPATH)/hd/guest/BootImage ; \
	cp $$KDIR/arch/x86/configs/bst-x86_64_voluntary_defconfig $(ANDROIDOUT)/kout/.config ; \
	make -j$(numproc) -C $$KDIR O=$(ANDROIDOUT)/kout ARCH=x86_64 oldnoconfig ; \
	make -j$(numproc) -C $$KDIR O=$(ANDROIDOUT)/kout ARCH=x86_64 bzImage modules
else
	$(call export_env); \
	KDIR=$(ANDROIDHOME)/kernel64-hyperv ; cd $(BASEPATH)/hd/guest/BootImage ; \
	cp $$KDIR/arch/x86/configs/bst-x86_64_voluntary_defconfig $(ANDROIDOUT)/kout/.config ; \
	make -j$(numproc) -C $$KDIR O=$(ANDROIDOUT)/kout ARCH=x86_64 CROSS_COMPILE=$(CROSS_COMPILER) olddefconfig ; \
	make -j$(numproc) -C $$KDIR O=$(ANDROIDOUT)/kout ARCH=x86_64 CROSS_COMPILE=$(CROSS_COMPILER) bzImage modules
endif
	@echo "Target kernel has completed, $$(date +%H:%M:%S)"


android: force-aidl-check force-kernel-clean
	@echo "Target android has started, $$(date +%H:%M:%S)"
	if [ -d $(ANDROIDOUT) ]; then cd $(ANDROIDOUT) && rm -f `find . -iname \*.img` && rm -f `find . -iname \*.iso` && rm -f `find . -iname \*.sfs`; fi
ifeq ($(ANDROID_VERSION),pie)
	($(call export_env) \
		&& cd $(ANDROIDHOME)/ \
		&& OUT_PATH=$(OUT_PATH) OEM=$(OEM) IMAGE=$(IMAGE) APP_PLAYER_DIR=$(BASEPATH) ANDROIDHOME=$(ANDROIDHOME) bash $(BUILD_SCRIPT_PATH)bin/wrap_build_sepolicy_py3.sh \
		&& make iso_img -j$(numproc) showcommands \
		&& make ramdisk || exit 1)
else ifeq ($(ANDROID_VERSION),baklava)
	($(call export_env) \
		&& cd $(ANDROIDHOME)/ \
		&& make iso_img -j$(numproc) \
		&& make ramdisk || exit 1)
else
	($(call export_env) \
		&& cd $(ANDROIDHOME)/ \
		&& make iso_img -j$(numproc) showcommands \
		&& make ramdisk || exit 1)
endif
	@echo "Target android has been completed, $$(date +%H:%M:%S)"

datafs: apks
	@echo "Target datafs has started, $$(date +%H:%M:%S)"
	$(call copy_g_p_all)
	@echo "Datafs completed"
	@echo "Target datafs has been completed, $$(date +%H:%M:%S)"

libs: android
	@echo "Target libs has been started, $$(date +%H:%M:%S)"
	$(call hostcall_gcall_libs)
ifeq ($(ANDROID_VERSION),nougat)
	$(call opengl_libs)
endif
	$(call goldfish_opengl)
	@echo "Target libs has been completed, $$(date +%H:%M:%S)"

apks:
	@echo "Target apks has been started for OEM=$(OEM), $$(date +%H:%M:%S)"
	$(call create_apk_folder)
#	(cd $(BUILD_SCRIPT_PATH) && export ANDROID_HOME=$(ANDROID_SDK_PATH) && export OEM=$(OEM) && bash -x build_bluestacks_apks.sh || exit 1)
#	(cd $(BUILD_SCRIPT_PATH) && export ANDROID_HOME=$(ANDROID_SDK_PATH) && export OEM=$(OEM) && bash -x build_nowgg_common_apks.sh || exit 1)
	$(call copy,$(SCRATCH_ROSEN)/apks/*apk,$(APKFOLDER)/)
	@echo "Target apks has been completed for OEM=$(OEM), $$(date +%H:%M:%S)"


force-aidl-check:
ifeq ($(ANDROID_VERSION),rvc)
        $(call check_android11_aidl_order)
        @echo "Target force-aidl-check for android 11 has completed, OEM=$(OEM), $$(date +%H:%M:%S)"
endif

force-kernel-clean:
	@echo "Target force-kernel-clean has started, $$(date +%H:%M:%S)"
ifeq ($(ANDROID_VERSION),baklava)
	@echo "Skipping force-kernel-clean for baklava (use incremental kernel build)"
else
	@echo "Cleaning kernel component for $(ANDROIDHOME) branch"
	rm -rf $(ANDROIDOUT)/kernel
ifeq ($(IS_HYPERV_BUILD),1)
	rm -rf $(ANDROIDOUT)/kout
endif
	rm -rf $(ANDROIDOUT)/system/lib/modules/
	rm -rf $(ANDROIDOUT)/obj/kernel/
	rm -rf $(ANDROIDOUT)/obj/EXECUTABLES/boot_img_intermediates/
	rm -rf $(ANDROIDOUT)/obj/PACKAGING/target_files_intermediates/$(ANDROID_TARGET)-target_files-eng.build/SYSTEM/lib/modules/
	rm -rf $(ANDROIDOUT)/obj/PACKAGING/target_files_intermediates/$(ANDROID_TARGET)-target_files-eng.build/BOOT/
	rm -rf $(ANDROIDOUT)/obj/PACKAGING/target_files_intermediates/$(ANDROID_TARGET)-target_files-eng.build/RECOVERY/
endif
	@echo "Target force-kernel-clean has completed, $$(date +%H:%M:%S)"

test:
	$(call hostcall_gcall_libs)
	@echo "Test completed"

define copy
	sudo cp -ar $(1) $(2) || (sudo umount -d $(2) > /dev/null; sudo umount -d $(2)/../ > /dev/null; \
	sudo umount -d $(2)/../../ > /dev/null; sudo mount -a; echo "Error in copying... "; exit 1)
endef

define copy_g_p_all
	echo "In copy_g_p_all function, copying apks and libs"
	cd $(G_P_STUFF) && for apk in `cat apks_to_push_in_priv_app`; do \
		echo $$apk; \
		$(call copy,$(G_P_STUFF)/$$apk,$(APKFOLDER)/) \
		done \
		&& for apks in `cat apks_to_push_in_system_app`; do \
		echo $$apks; \
		$(call copy,$(G_P_STUFF)/$$apks,$(APKFOLDER)/) \
		done \
		&& for f in `cat lib_to_be_pushed`; do \
		echo $$f; \
		$(call copy,$(G_P_STUFF)/$$f,$(APKFOLDER)/) \
		done
	echo "Exiting copy_g_p_all function"
endef

define copy_data_apks
echo "In copy_data_apks function"
echo $(APPCONFFILE)
		while read line; \
		do if [ "$$line" == "System:" ]; then continue; \
		elif [ "$$line" == "SystemPrivApp:" ]; then continue; \
		elif [ "$$line" == "Data:" ]; then copy_loc="app"; \
		elif [ "$$line" == "Priv-Downloads:" ]; then copy_loc="priv-downloads"; \
		elif [ "$$line" == "Downloads:" ]; then copy_loc="downloads"; \
		elif [ "$$line" == "" ]; then continue; \
		elif [ "$$copy_loc" != "" ] && [[ "$$line" == *.apk ]]; then \
		DIR=`basename -s .apk $$line`; \
		sudo mkdir -p $(OUTPUTDIR)/$(1)/$$copy_loc/$$DIR || (sudo umount -d $(OUTPUTDIR)/$(1) > /dev/null; exit 1); \
		$(call copy,$(APKFOLDER)/$$line,$(OUTPUTDIR)/$(1)/$$copy_loc/$$DIR); \
		sudo chmod 664 $(OUTPUTDIR)/$(1)/$$copy_loc/$$DIR/$$line; \
		elif [ "$$copy_loc" != "" ]; then $(call copy,$(APKFOLDER)/$$line,$(OUTPUTDIR)/$(1)/$$copy_loc); \
		else continue; \
		fi; \
	done < $(APPCONFFILE)
		echo "Exiting copy_data_apks function"
endef

define create_disk_file
	echo "In create_disk_file function"
    dd if=/dev/zero of=$(3)/$(1) bs=1024 count=$(2) \
		&& mkfs.ext4 -m 1 -L root -F $(3)/$(1)
	echo "Exiting create_disk_file function"
endef

define mount_disk_file
	echo "In mount_disk_file function"
	sudo umount -d $(3)/$(2) 2>/dev/null; true
    rm -rf $(3)/$(2)
    sudo mkdir -p $(3)/$(2)
	sudo mount -o loop $(3)/$(1) $(3)/$(2) || exit 1
	sudo chown -R 1000:1000 $(3)/$(2) || exit 1
	echo "Exiting mount_disk_file function"
endef

define create_dataFS_dir_structure
	echo "In create_dataFS_dir_structure function"
	sudo mkdir -p $(OUTPUTDIR)/$(1) || exit 1
	sudo chown -R 1000:1000 $(OUTPUTDIR)/$(1) || exit 1
	(sudo mkdir -p $(OUTPUTDIR)/$(1)/app/ || (sudo umount -d $(OUTPUTDIR)/$(1) > /dev/null; exit 1)) \
		&& (sudo chmod 771 $(OUTPUTDIR)/$(1)/app/ ||  (sudo umount -d $(OUTPUTDIR)/$(1)> /dev/null; exit 1)) \
		&& (sudo mkdir -p $(OUTPUTDIR)/$(1)/priv-downloads/ || (sudo umount -d $(OUTPUTDIR)/$(1) > /dev/null; exit 1)) \
		&& (sudo chmod 775 $(OUTPUTDIR)/$(1)/priv-downloads/ ||  (sudo umount -d $(OUTPUTDIR)/$(1)> /dev/null; exit 1)) \
		&& (sudo mkdir -p $(OUTPUTDIR)/$(1)/downloads/ || (sudo umount -d $(OUTPUTDIR)/$(1) > /dev/null; exit 1)) \
		&& (sudo chmod 775 $(OUTPUTDIR)/$(1)/downloads/ ||  (sudo umount -d $(OUTPUTDIR)/$(1)> /dev/null; exit 1)) \
		&& (sudo mkdir -p $(OUTPUTDIR)/$(1)/downloads/.sc/ || (sudo umount -d $(OUTPUTDIR)/$(1) > /dev/null; exit 1)) \
		&& (sudo chmod 775 $(OUTPUTDIR)/$(1)/downloads/.sc/ ||  (sudo umount -d $(OUTPUTDIR)/$(1)> /dev/null; exit 1)) \
		&& (sudo mkdir -p $(OUTPUTDIR)/$(1)/downloads/.dp/ || (sudo umount -d $(OUTPUTDIR)/$(1) > /dev/null; exit 1)) \
		&& (sudo chmod 775 $(OUTPUTDIR)/$(1)/downloads/.dp/ ||  (sudo umount -d $(OUTPUTDIR)/$(1)> /dev/null; exit 1)) \
		&& (sudo mkdir -p $(OUTPUTDIR)/$(1)/downloads/.oh/ || (sudo umount -d $(OUTPUTDIR)/$(1) > /dev/null; exit 1)) \
		&& (sudo chmod 775 $(OUTPUTDIR)/$(1)/downloads/.oh/ ||  (sudo umount -d $(OUTPUTDIR)/$(1)> /dev/null; exit 1)) \
		&& (sudo mkdir -p $(OUTPUTDIR)/$(1)/downloads/.tmp/ || (sudo umount -d $(OUTPUTDIR)/$(1) > /dev/null; exit 1)) \
		&& (sudo chmod 777 $(OUTPUTDIR)/$(1)/downloads/.tmp/ ||  (sudo umount -d $(OUTPUTDIR)/$(1)> /dev/null; exit 1)) \
		&& (sudo mkdir -p $(OUTPUTDIR)/$(1)/propfiles/ || (sudo umount -d $(OUTPUTDIR)/$(1) > /dev/null; exit 1)) \
		&& (sudo mkdir -p $(OUTPUTDIR)/$(1)/permissions/ || (sudo umount -d $(OUTPUTDIR)/$(1) > /dev/null; exit 1)) \
		&& (sudo mkdir -p $(OUTPUTDIR)/$(1)/system-app/ || (sudo umount -d $(OUTPUTDIR)/$(1) > /dev/null; exit 1)) \
		&& (sudo mkdir -p $(OUTPUTDIR)/$(1)/system-priv-app/ || (sudo umount -d $(OUTPUTDIR)/$(1) > /dev/null; exit 1)) \
		&& (sudo mkdir -p $(OUTPUTDIR)/$(1)/system-lib/ || (sudo umount -d $(OUTPUTDIR)/$(1) > /dev/null; exit 1));
		$(call array_declaration); \
			cd $(PROPFILES) && for i in $${COUNTRIES[@]}; do \
			sudo mkdir -p $(OUTPUTDIR)/$(1)/propfiles/$$i || (sudo umount -d $(OUTPUTDIR)/$(1) > /dev/null; exit 1); \
			done
		echo "Exiting create_dataFS_dir_structure function"
endef

define hostcall_gcall_libs
	echo "Inside hostcall_libs function"
	($(call export_env) && cd $(ANDROIDHOME) \
		&& (mmm ../hd/Source/xpl -j$(numproc) || exit 1) \
		&& (mmm ../hd/Source/vmsg/guest -j$(numproc) || exit 1) \
		&& (mmm ../hd/Source/hcall/guest -j$(numproc) || exit 1) \
		&& (mmm ../hd/Source/gcall/guest -j$(numproc) || exit 1) \
		&& (mmm packages/apps/BstCommandProcessor/jni -j$(numproc) || exit 1) \
		&& (mmm frameworks/base/services/java/com/bluestacks/server/native || exit 1) \
		&& (mmm ../hd/Source/tools/bstconf || exit 1) \
		&& (mmm ../hd/Source/tools/bstchkdata || exit 1) \
		&& cd $(SENSORS_DEFAULT) \
		&& (mm -j$(numproc) BUILD_EXTERNAL_BLUESTACKS_SENSORS=true || exit 1) \
		&& cd $(TOYBOX) \
		&& (mma -j$(numproc) || exit 1))
	echo "Exiting hostcall_gcall_libs function"
endef

define opengl_libs
	echo "Inside opengl_libs"
	($(call export_env) \
		&& cd $(OPENGL_DIR) \
		&& (mm -B -j$(numproc) || exit 1))
endef

define ggl_libs
	echo "Inside ggl libs"
	($(call export_env) \
		&& cd $(GGL_LIBS) \
		&& (bash -x build-setup.sh || exit 1) \
		&& cd $(GGL_LIBS)/android \
		&& (make -j$(numproc) || exit 1))
	sudo mkdir -p $(OUTPUTDIR)/$(PKG)
	$(call copy,$(GGL_LIBS)/android/objs/lib,$(OUTPUTDIR)/$(PKG)/x86)
	$(call copy,$(GGL_LIBS)/android/objs/lib64,$(OUTPUTDIR)/$(PKG)/amd64)
endef

define goldfish_opengl
	echo "Start building goldfish opengl"
	($(call export_env) \
		&& cd $(ANDROIDHOME) \
		&& (mmm ../$(GOLDFISH_OPENGL) BUILD_EMULATOR_OPENGL=true BUILD_EMULATOR_OPENGL_DRIVER=true -j$(numproc) || exit 1))
endef

define build_alternate_memalloc
@echo "Target memalloc_libs has been started, $$(date +%H:%M:%S)"
if [ -f $(OUTPUTDIR_x86_LIBS)/libc_je.so ] && [ -f $(OUTPUTDIR_x86_LIBS)/libc_dl.so ] && [ -f $(OUTPUTDIR_x86_LIBS)/libmemunreachable.so ]; then \
	echo "Skipping memalloc_libs rebuild; artifacts already present in $(OUTPUTDIR_x86_LIBS)"; \
elif [ $(IS_64_BUILD) == 1 ]; then $(call save_memalloc_libs,$(x86_SRC_LIBS_DIR),$(OUTPUTDIR_x86_LIBS),je) \
	&& $(call save_memalloc_libs,$(x86_64_SRC_LIBS_DIR),$(OUTPUTDIR_x86_64_LIBS),je) \
	&& $(call build_memalloc_libs,false) \
	&& $(call save_memalloc_libs,$(x86_SRC_LIBS_DIR),$(OUTPUTDIR_x86_LIBS),dl) \
	&& $(call save_memalloc_libs,$(x86_64_SRC_LIBS_DIR),$(OUTPUTDIR_x86_64_LIBS),dl); \
else $(call save_memalloc_libs,$(x86_SRC_LIBS_DIR),$(OUTPUTDIR_x86_LIBS),dl) \
	&& $(call build_memalloc_libs,true) \
	&& $(call copy,$(x86_SRC_LIBS_DIR)/libmemunreachable.so,$(OUTPUTDIR_x86_LIBS)/libmemunreachable.so) \
	&& $(call save_memalloc_libs,$(x86_SRC_LIBS_DIR),$(OUTPUTDIR_x86_LIBS),je); \
fi
@echo "Target memalloc_libs has been completed, $$(date +%H:%M:%S)"
endef

define save_memalloc_libs
echo "Save mem alloc libs separately" \
&& $(call copy,$(1)/libc.so,$(2)/libc_$(3).so) \
&& $(call copy,$(1)/libstdc++.so,$(2)/libstdc++_$(3).so) \
&& $(call copy,$(1)/libmedia.so,$(2)/libmedia_$(3).so) \
&& $(call copy,$(1)/libmediaplayerservice.so,$(2)/libmediaplayerservice_$(3).so) \
&& $(call copy,$(1)/libaudioflinger.so,$(2)/libaudioflinger_$(3).so) \
&& $(call copy,$(1)/libcameraservice.so,$(2)/libcameraservice_$(3).so)
endef

define build_memalloc_libs
echo "Build memalloc libs" && \
($(call export_env) \
	&& cd $(BIONIC_LIBC) \
	&& echo "Build bionic/libc" \
	&& (mma BST_USE_JEMALLOC=$(1) -j$(numproc) || exit 1) \
	&& cd $(FRAMEWORKS_AV)/media/libmedia \
	&& echo "Build frameworks/av/media/libmedia" \
	&& (mma BST_USE_JEMALLOC=$(1) -j$(numproc) || exit 1) \
	&& cd $(FRAMEWORKS_AV)/media/libmediaplayerservice \
	&& echo "Build frameworks/av/media/libmediaplayerservice" \
	&& (mma BST_USE_JEMALLOC=$(1) -j$(numproc) || exit 1) \
	&& cd $(FRAMEWORKS_AV)/services/audioflinger \
	&& echo "Build frameworks/av/services/audioflinger" \
	&& (mma BST_USE_JEMALLOC=$(1) -j$(numproc) || exit 1) \
	&& cd $(FRAMEWORKS_AV)/services/camera/libcameraservice \
	&& echo "Build frameworks/av/services/camera/libcameraservice" \
	&& (mma BST_USE_JEMALLOC=$(1) -j$(numproc) || exit 1))
endef

define copy_android_files_to_outputdir
echo "Inside copy_android_files_to_outputdir function"
sudo mkdir -p $(OUTPUTDIR)/$(PKG)
$(call copy,$(ANDROIDOUT)/system,$(OUTPUTDIR)/)
$(call copy,$(ANDROIDOUT)/installer,$(OUTPUTDIR)/)
$(call copy,$(ANDROIDOUT)/root,$(OUTPUTDIR)/)
$(call copy,$(ANDROIDOUT)/ramdisk.img,$(OUTPUTDIR)/)
$(call copy,$(ANDROIDOUT)/obj/kernel/Module.symvers,$(OUTPUTDIR)/$(IMAGE)-Module.symvers)
echo "Exiting copy_android_files_to_outputdir function"
endef

define copy_system_apks
	echo "In copy_system_apks function"
	while read line; \
		do if [ "$$line" == "System:" ]; then copy_loc="system/app"; \
		elif [ "$$line" == "SystemPrivApp:" ]; then copy_loc="system/priv-app"; \
		elif [ "$$line" == "Data:" ]; then break; \
		elif [ "$$line" == "Priv-Downloads:" ]; then break; \
		elif [ "$$line" == "Downloads:" ]; then break; \
		elif [ "$$line" == "" ]; then continue; \
		elif [ "$$copy_loc" != "" ] && [[ "$$line" == *.apk ]]; then \
		DIR=`basename -s .apk $$line`; \
		sudo mkdir -p $(OUTPUTDIR)/$$copy_loc/$$DIR ; \
		$(call copy,$(APKFOLDER)/$$line,$(OUTPUTDIR)/$$copy_loc/$$DIR); \
		sudo chmod 664 $(OUTPUTDIR)/$$copy_loc/$$DIR/$$line; \
		elif [ "$$copy_loc" != "" ]; then $(call copy,$(APKFOLDER)/$$line,$(OUTPUTDIR)/$$copy_loc); \
		else continue; \
		fi; \
	done < $(APPCONFFILE)
	echo "Exiting copy_system_apks function"
endef

define copy_3bt_libs
echo "Inside copy_3bt_libs function"
sudo mkdir -p $(OUTPUTDIR)/system/lib
echo "Copying 3bt library in $(OUTPUTDIR)/system/lib"
if [ $(IS_64_BUILD) == 1 ]; then $(call copy, $(THIRD_PARTY_BT_LIBS_DIR)/arm,$(OUTPUTDIR)/system/lib/) \
	&& $(call copy, $(THIRD_PARTY_BT_LIBS_DIR)/arm/libhoudini.so,$(OUTPUTDIR)/system/lib/) \
	&& mkdir -p $(OUTPUTDIR)/system/lib64 \
	&& echo "Copying 3bt library in $(OUTPUTDIR)/system/lib64" \
	&& $(call copy, $(THIRD_PARTY_BT_LIBS_DIR)/arm64,$(OUTPUTDIR)/system/lib64/) \
	&& $(call copy, $(THIRD_PARTY_BT_LIBS_DIR)/arm64/libhoudini.so,$(OUTPUTDIR)/system/lib64/); \
	else $(call copy, $(THIRD_PARTY_BT_LIBS_DIR)/*,$(OUTPUTDIR)/system/lib/) \
	&& echo "Exiting copy_3bt_libs function"; \
fi; \
if [ $(IMAGE) == Pie32 ]; then \
        $(call copy, $(THIRD_PARTY_BT_LIBS_DIR)/bin/*, $(OUTPUTDIR)/system/bin/)  \
        && $(call copy, $(THIRD_PARTY_BT_LIBS_DIR)/etc/ld.config.arm.txt, $(OUTPUTDIR)/system/etc/) \
        && $(call copy, $(THIRD_PARTY_BT_LIBS_DIR)/etc/binfmt_misc, $(OUTPUTDIR)/system/etc/) \
        && $(call copy, $(THIRD_PARTY_BT_LIBS_DIR)/etc/init/*, $(OUTPUTDIR)/system/etc/init/); \
fi
endef

define create_setuid_su_binary
echo "Inside create_setuid_su_binary function"
sudo mkdir -p $(OUTPUTDIR)/system/xbin/bstk
sudo chmod 755 $(OUTPUTDIR)/system/xbin/bstk/ || exit 1
sudo rm -f $(OUTPUTDIR)/system/xbin/bstk/su || exit 1
$(call copy,$(OUTPUTDIR)/system/xbin/su,$(OUTPUTDIR)/system/xbin/bstk/)
sudo chown 0:0 $(OUTPUTDIR)/system/xbin/bstk/su || exit 1
sudo chmod 06755 $(OUTPUTDIR)/system/xbin/bstk/su || exit 1
sudo chmod 0511 $(OUTPUTDIR)/system/xbin/bstk/ || exit 1
sudo -n rm -f $(OUTPUTDIR)/system/xbin/su || exit 1
echo "Exiting create_setuid_su_binary function"
endef

define create_rootfs
echo "inside create_rootfs function."
$(call create_disk_file,$(1),$(ROOTSIZE),$(OUTPUTDIR))
$(call mount_disk_file,$(1),$(2),$(OUTPUTDIR))
$(call create_rootFS_dir_structure,$(2))
if [ $(1) == "Root.fs.debug" ]; then \
	if [ $(ANDROID_VERSION) == "nougat" ]; then \
		$(call copy,$(BSTTOOLS)/$(ANDROID_VERSION)/adbd_rooted_$(ANDROID_VERSION),$(OUTPUTDIR)/rooted_root/sbin/adbd); \
	else $(call copy,$(BSTTOOLS)/$(ANDROID_VERSION)/adbd_rooted_$(ANDROID_VERSION),$(OUTPUTDIR)/rooted_system/bin/adbd); \
	fi \
	&& $(call create_rooted_ramdisk_img_file) \
	&& $(call copy,$(OUTPUTDIR)/ramdisk.img.rooted,$(OUTPUTDIR)/$(2)/android/ramdisk.img) \
	&& $(call copy,$(OUTPUTDIR)/$(3)/xbin/bstk/su,$(OUTPUTDIR)/$(3)/xbin/su); \
	else $(call copy,$(OUTPUTDIR)/ramdisk.img,$(OUTPUTDIR)/$(2)/android/ramdisk.img); \
fi
$(call copy,$(OUTPUTDIR)/$(3),$(OUTPUTDIR)/$(2)/android/system)
$(call copy,$(OUTPUTDIR)/$(4),$(OUTPUTDIR)/$(2)/)
sudo chown 0:0 $(OUTPUTDIR)/$(2)/android/system/xbin/bstk/su || exit 1
sudo chmod 06755 $(OUTPUTDIR)/$(2)/android/system/xbin/bstk/su || exit 1
sudo chmod 0111 $(OUTPUTDIR)/$(2)/android/system/xbin/bstk/ || exit 1
if [ -f $(OUTPUTDIR)/$(2)/dataFS/downloads/.xb/su ]; then \
	(sudo chown 0:0 $(OUTPUTDIR)/$(2)/dataFS/downloads/.xb/su || exit 1) \
	&& (sudo chmod 06755 $(OUTPUTDIR)/$(2)/dataFS/downloads/.xb/su || exit 1) \
	&& (sudo chown 0:0 $(OUTPUTDIR)/$(2)/dataFS/downloads/.xb/bstk/su || exit 1) \
	&& (sudo chmod 06755 $(OUTPUTDIR)/$(2)/dataFS/downloads/.xb/bstk/su || exit 1); \
fi
if [[ $(1) == "Root.fs.debug" || $(1) == "Root.fs.rooted" ]]; then \
	(sudo chown 0:0 $(OUTPUTDIR)/$(2)/android/system/xbin/su || exit 1) \
	&& (sudo chmod 06755 $(OUTPUTDIR)/$(2)/android/system/xbin/su || exit 1); \
fi
sleep 5
sudo umount -d $(OUTPUTDIR)/$(2) 2>/dev/null; true
echo "Exiting create_rootfs function."
endef

define create_rootFS_dir_structure
sudo mkdir -p $(OUTPUTDIR)/$(1)/android || (echo "Error in create_rootFS_dir_structure"; sudo umount -d $(OUTPUTDIR)/$(1) > /dev/null; exit 1)
endef

define copy_misc_system_framework_files
echo "Inside copy_misc_system_framework_files function"
$(call copy,`find $(G_P_STUFF) -name '*.jar'`,$(OUTPUTDIR)/system/framework/)
sudo chmod 664 $(OUTPUTDIR)/system/framework/*.jar || exit 1
echo "Exiting copy_misc_system_framework_files function"
endef

define remove_debug_tools_and_apps_from_outputdir
echo "Inside remove_debug_tools_and_apps_from_outputdir function"
for f in `cat $(BSTTOOLS)/files_to_remove_$(ANDROID_VERSION).txt`; do \
	sudo rm -rf $(OUTPUTDIR)/system/$$f \
	&& echo $$f ; \
	done
echo "Inside remove_debug_tools_and_apps_from_outputdir function"
endef

define copy_propfiles
echo "Inside copy_propfiles function"
$(call array_declaration); \
	cd $(PROPFILES) \
	&& for i in `ls $(ANDROID_VERSION).bluestacks.prop.* | grep -v default`; do \
	echo $$i; b=`echo $$i | sed 's/$(ANDROID_VERSION).//'`; \
	echo "b is $$b"; x=`echo $$b | cut -d '.' -f 3 | tr '[a-z]' '[A-Z]'`; \
	echo "x is $$x"; y=$${COUNTRIES["$$x"]}; \
	echo "y is  $$y";  \
	z=`echo $$b | cut -d '.' -f 4`; \
	echo "z is $$z"; \
	if [ -z $$z ]; then \
	$(call copy,$(PROPFILES)/$$i,$(OUTPUTDIR)/$(1)/bluestacks.prop.orig.$$y) \
	else \
	$(call copy,$(PROPFILES)/$$i,$(OUTPUTDIR)/$(1)/propfiles/$$y/$$b) fi \
	done
echo "Exiting copy_propfiles function"
endef

define copy_misc_data_downloads_files
echo "Inside copy_misc_data_downloads_files function"
echo "Copying config.db file"
$(call copy,$(APKFOLDER)/config.db,$(OUTPUTDIR)/$(1)/downloads/config.db)

echo "Copying Houdini hook library file"
$(call copy,$(APKFOLDER)/libstagefright_httpcommon.so,$(OUTPUTDIR)/$(1)/downloads/libstagefright_httpcommon.so)
if [ $(ANDROID_VERSION) != "nougat" ]; then \
    echo "Copying Houdini hook libinary for $(IMAGE)"; \
    $(call copy,$(APKFOLDER)/xp,$(OUTPUTDIR)/$(1)/downloads/.xp) \
fi

if [[ $(ANDROID_VERSION) == "pie" || $(ANDROID_VERSION) == "rvc" ]]; then \
    echo "Copying Promotion shielf fix libinary libpmf.so"; \
    $(call copy,$(APKFOLDER)/libpmf.so,$(OUTPUTDIR)/$(1)/downloads/libpmf.so); \
fi

echo "Copying Gama setting file"
$(call copy,$(APKFOLDER)/GameFrameworkSetting.dat,$(OUTPUTDIR)/$(1)/downloads/GameFrameworkSetting.dat)

echo "Copying GMS admob user-agent config file"
$(call copy,$(APKFOLDER)/admob_user_agent.xml, $(OUTPUTDIR)/$(1)/downloads/admob_user_agent.xml)

if [ $(ANDROID_VERSION) == "nougat" ]; then \
	echo "Copying mycpuinfo executable binary"; \
	$(call copy,$(APKFOLDER)/mycpuinfo,$(OUTPUTDIR)/$(1)/downloads/mycpuinfo) \
fi
echo "Copying allowed adb commands file"
if [ -f $(BSTTOOLS)/adb_allowed_cmds_$(OEM)_$(IMAGE) ]; then \
	$(call copy,$(BSTTOOLS)/adb_allowed_cmds_$(OEM)_$(IMAGE),$(OUTPUTDIR)/$(1)/downloads/.adbcmd) \
elif [ "$(BST_BUILD_WITH_DEXPREOPT)" = "false" ]; then \
	$(call copy,$(BSTTOOLS)/adb_allowed_cmds_debug,$(OUTPUTDIR)/$(1)/downloads/.adbcmd) \
else \
	$(call copy,$(BSTTOOLS)/adb_allowed_cmds,$(OUTPUTDIR)/$(1)/downloads/.adbcmd) \
fi

echo "Copying default-permissions.xml file"
$(call copy,$(BSTTOOLS)/default-permissions.xml,$(OUTPUTDIR)/$(1)/downloads/.dp/system.xml)
if [ -f $(SCRATCH_ROSEN)/apps_$(OEM)_$(IMAGE).xml ]; then \
	$(call copy,$(SCRATCH_ROSEN)/apps_$(OEM)_$(IMAGE).xml,$(OUTPUTDIR)/$(1)/downloads/.dp/apps.xml) \
else \
	$(call copy,$(SCRATCH_ROSEN)/apps.xml,$(OUTPUTDIR)/$(1)/downloads/.dp/apps.xml) \
fi
echo "Copying google.xml file"
$(call copy,$(BSTTOOLS)/google.xml,$(OUTPUTDIR)/$(1)/downloads/.sc/google.xml)

echo "Exiting copy_misc_data_downloads_files function"
endef

define set_ownership_for_dataFS_dirs
echo "Inside set_ownership_for_dataFS_dirs function"
sudo chown -R 1000:1000 $(OUTPUTDIR)/$(1)/app/ || (sudo umount -d $(OUTPUTDIR)/$(1) > /dev/null; exit 1)
sudo chmod 771 $(OUTPUTDIR)/$(1)/app/ || (sudo umount -d $(OUTPUTDIR)/$(1) > /dev/null; exit 1)
sudo chown -R 1000:1000 $(OUTPUTDIR)/$(1)/priv-downloads/ || (sudo umount -d $(OUTPUTDIR)/$(1) > /dev/null; exit 1)
sudo chmod -R 775 $(OUTPUTDIR)/$(1)/priv-downloads/ || (sudo umount -d $(OUTPUTDIR)/$(1) > /dev/null; exit 1)
sudo chown -R 1000:1000 $(OUTPUTDIR)/$(1)/downloads/	|| (sudo umount -d $(OUTPUTDIR)/$(1) > /dev/null; exit 1)
sudo chmod -R 775 $(OUTPUTDIR)/$(1)/downloads || (sudo umount -d $(OUTPUTDIR)/$(1) > /dev/null; exit 1)
sudo chown -R 1000:1000 $(OUTPUTDIR)/$(1)/propfiles/ || (sudo umount -d $(OUTPUTDIR)/$(1) > /dev/null; exit 1)
if [ -f $(OUTPUTDIR)/$(1)/downloads/.xb/su ]; then \
	(sudo chown 0:0 $(OUTPUTDIR)/$(1)/downloads/.xb/su || exit 1) \
	&& (sudo chmod 06755 $(OUTPUTDIR)/$(1)/downloads/.xb/su || exit 1) \
	&& (sudo chown 0:0 $(OUTPUTDIR)/$(1)/downloads/.xb/bstk/su || exit 1) \
	&& (sudo chmod 06755 $(OUTPUTDIR)/$(1)/downloads/.xb/bstk/su || exit 1); \
fi
echo "Exiting set_ownership_for_dataFS_dirs function"
endef

define copy_appdetails
echo "Inside copy_appdetails function"
cd $(APKFOLDER)/$(ANDROID_VERSION) \
	&& for i in `ls $(ANDROID_VERSION)_appdetails*`; do \
	j=$$i; \
	b=$${j/$(ANDROID_VERSION)/bst}; \
	echo "i is $$i j is $$j b is $$b"; \
	$(call copy,$(APKFOLDER)/$(ANDROID_VERSION)/$$i,$(OUTPUTDIR)/$(1)/$$b); \
	done
echo "Exiting copy_appdetails function"
endef

define make_vdi_file
echo "Inside make_vdi_file function"
sudo mkdir -p $(3)
VDI_FILE=$(shell echo $(1) | sed "s/.fs/.vdi/g"); \
		 VHD_FILE=$(shell echo $(1) | sed -E 's/(.*)(.fs)(.*)/\1\3.vhd/'); \
		 FS_FILE=$(1); \
		 VDI_OUTPUT_LOC=$(3); \
		 if [ -f $(OUTPUTDIR)/$$FS_FILE ]; then \
		 export PKG=$(PKG) IMAGE=$(IMAGE) && bash -x $(BUILD_SCRIPT_PATH)/create_vdi.sh -t $(2) -v $$VDI_OUTPUT_LOC/$$VDI_FILE -f $(OUTPUTDIR)/$$FS_FILE || exit 1; \
		 fi; \
		 echo "Making vdi file $$VDI_FILE from fs file $$FS_FILE and output location for vdi $$VDI_OUTPUT_LOC" ; \
		 sed -i "/Root./d" ~/.config/VirtualBox/VirtualBox.xml > /dev/null ; \
		 vboxmanage internalcommands sethduuid $$VDI_OUTPUT_LOC/$$VDI_FILE > /dev/null ; \
		 vboxmanage internalcommands sethduuid $$VDI_OUTPUT_LOC/$$VHD_FILE > /dev/null ; \
		 vboxmanage clonehd $$VDI_OUTPUT_LOC/$$VDI_FILE $$VDI_OUTPUT_LOC/$$VHD_FILE --format VHD --variant Standard ;
		 echo "Exiting make_vdi_file function"
endef

define create_rooted_ramdisk_img_file
(cd $(ANDROIDHOME) && $(OUT_PATH)/host/linux-x86/bin/mkbootfs $(OUTPUTDIR)/rooted_root | gzip -n > $(OUTPUTDIR)/ramdisk.img.rooted)
endef

define array_declaration
declare -A COUNTRIES=( ["US"]="840" ["JAPAN"]="392" ["CANADA"]="124" ["UK"]="826" ["IE"]="372" ["NZ"]="554" ["AU"]="036" ["BR"]="076" ["KR"]="410" ["DE"]="276" ["FR"]="250" ["TW"]="158" ["SG"]="702" ["RU"]="643" ["HK"]="344" ["CN"]="156" ["IN"]="356" ["SE"]="752" ["ES"]="724" ["TR"]="792" ["PL"]="616" ["IT"]="380" ["UA"]="804" ["VN"]="704" ["TH"]="764" ["LB"]="422" ["PE"]="604" )
endef

define copy_feature_files
echo "Copying different feature files over $(OUTPUTDIR)/$(1)"
cd $(FEATUREFILES) && $(call copy,$(FEATUREFILES)/*,$(OUTPUTDIR)/$(1)/permissions/)
endef

define create_cpuinfo_files
echo "Creating cpuinfo files in $(CPUINFO_DIR)"
bash -x $(BUILD_SCRIPT_PATH)/create_cpuinfo_files.sh $(CPUINFO_DIR)
endef

define check_android11_aidl_order
if [ ! -f $(ANDROIDHOME)/$(OUT_PATH)/host/linux-x86/bin/aidl ]; then \
        ($(call export_env) \
                && echo "start to build aidl binary" \
                && cd $(ANDROIDHOME)/ \
                && make aidl -j$(numproc) || exit 1); \
fi
        (bash -x $(ANDROIDHOME)/frameworks/base/unit-test.sh $(ANDROIDHOME) $(OUT_PATH) || exit 1)
        echo "android 11 aidl order checking successful"
endef

define create_apk_folder
	echo "deleting old $(APKFOLDER)"
	sudo rm -rf $(APKFOLDER);
	echo "Creating new  ApkFolder $(APKFOLDER)"
	(sudo mkdir -p $(APKFOLDER)|| exit 1)
	$(call copy,$(BASEPATH)/bst/apks/*,$(APKFOLDER)/)
endef

define copy_gms_permission_files
echo "Inside copy_gms_permission_files function"
$(call copy,$(BSTTOOLS)/privapp-permissions-google.xml,$(OUTPUTDIR)/system/etc/permissions/)
$(call copy,$(BSTTOOLS)/google.xml,$(OUTPUTDIR)/system/etc/sysconfig/)
echo "Exiting copy_gms_permission_filesfunction"
endef

define export_env
echo "exporting environment variables" \
	&& cd $(ANDROIDHOME)/ \
	&& export OEM="$(OEM)" \
	&& export OUT_DIR="$(OUT_PATH)" \
	&& export HD_SOURCE_TOP=$(HD_SOURCE_TOP_PATH) \
	&& export IS_64_BUILD=$(IS_64_BUILD) \
	&& export BST_USE_JEMALLOC=$(BST_USE_JEMALLOC) \
	&& export APP_PLAYER_DIR=$(BASEPATH) \
	&& export IMAGE="$(IMAGE)" \
	&& export USE_OPENGL_RENDERER=true \
	&& export BST_BUILD_WITH_DEXPREOPT=$(BST_BUILD_WITH_DEXPREOPT) \
	&& export IS_MAC_BUILD=$(IS_MAC_BUILD) \
	&& export ALLOW_MISSING_DEPENDENCIES=true \
	&& source build/envsetup.sh \
	&& lunch $(TARGET) \
	&& export LC_ALL=C \
	&& export LANG=C \
	&& export JAVA_TOOL_OPTIONS="$${JAVA_TOOL_OPTIONS:+$${JAVA_TOOL_OPTIONS} }-Dfile.encoding=UTF-8" \
	&& export PATH="$(BUILD_SCRIPT_PATH)bin:$$PATH" \
	&& export PYTHONPATH="$(BUILD_SCRIPT_PATH)python2_site$${PYTHONPATH:+:$$PYTHONPATH}" \
	&& export TOP=$(ANDROIDHOME) \
	&& cd -
endef
