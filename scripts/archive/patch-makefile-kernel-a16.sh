#!/usr/bin/env python3
"""Point baklava fastboot/kernel build at ~/aosp16/kernel-a16 (not ANDROIDOUT/obj/kernel)."""
from pathlib import Path

mk = Path.home() / "app-player/buildscripts/Makefile"
text = mk.read_text()

old_fastboot = """else ifeq ($(ANDROID_VERSION),baklava)
\t(cd $(BASEPATH)/hd/guest && export KDIR=$(ANDROIDOUT)/obj/kernel \\
\t\t&& export VBOX_GUEST_ADDITIONS=$(VBOX_GUEST_ADDITIONS_LOC)/$(LOCATION)/src/vboxguest-$(VBOX_VERSION) \\
\t\t&& export KERN_DIR=$(ANDROIDOUT)/obj/kernel \\"""

new_fastboot = """else ifeq ($(ANDROID_VERSION),baklava)
\t(cd $(BASEPATH)/hd/guest && export KDIR=$(ANDROIDHOME)/kernel-a16 \\
\t\t&& export VBOX_GUEST_ADDITIONS=$(VBOX_GUEST_ADDITIONS_LOC)/$(LOCATION)/src/vboxguest-$(VBOX_VERSION) \\
\t\t&& export KERN_DIR=$(ANDROIDHOME)/kernel-a16 \\"""

if old_fastboot not in text:
    if "KDIR=$(ANDROIDHOME)/kernel-a16" in text:
        print("fastboot KDIR already points at kernel-a16")
    else:
        raise SystemExit("fastboot baklava KDIR anchor not found")
else:
    text = text.replace(old_fastboot, new_fastboot, 1)
    print("patched fastboot.vdi KDIR -> kernel-a16")

kernel_anchor = """kernel:
\t@echo "Target kernel has started, $$(date +%H:%M:%S)"
\tmkdir -p $(ANDROIDOUT)/kout
ifeq ($(ANDROID_VERSION),nougat)"""

kernel_new = """kernel:
\t@echo "Target kernel has started, $$(date +%H:%M:%S)"
\tmkdir -p $(ANDROIDOUT)/kout
ifeq ($(ANDROID_VERSION),baklava)
\t$(call export_env); \\
\tcd $(ANDROIDHOME)/kernel-a16 && export PATH=$(CLANG_PREBUILT_BIN):$$PATH && \\
\tmake ARCH=x86_64 CC=clang LLVM=1 -j$(numproc) bzImage modules
else ifeq ($(ANDROID_VERSION),nougat)"""

if "ANDROID_VERSION),baklava)" in text.split("kernel:")[1].split("android:")[0]:
    print("kernel baklava target already present")
elif kernel_anchor not in text:
    raise SystemExit("kernel target anchor not found")
else:
    text = text.replace(kernel_anchor, kernel_new, 1)
    print("patched kernel target for baklava -> kernel-a16")

fkc_anchor = """force-kernel-clean:
\t@echo "Target force-kernel-clean has started, $$(date +%H:%M:%S)"
\t@echo "Cleaning kernel component for $(ANDROIDHOME) branch"
\trm -rf $(ANDROIDOUT)/kernel"""

fkc_new = """force-kernel-clean:
\t@echo "Target force-kernel-clean has started, $$(date +%H:%M:%S)"
ifeq ($(ANDROID_VERSION),baklava)
\t@echo "Skipping force-kernel-clean for baklava (kernel-a16 is out-of-tree)"
else
\t@echo "Cleaning kernel component for $(ANDROIDHOME) branch"
\trm -rf $(ANDROIDOUT)/kernel"""

if "Skipping force-kernel-clean for baklava" in text:
    print("force-kernel-clean baklava skip already present")
elif fkc_anchor not in text:
    raise SystemExit("force-kernel-clean anchor not found")
else:
    # close the else branch before next target
    text = text.replace(
        fkc_anchor,
        fkc_new,
        1,
    )
    text = text.replace(
        '\t@echo "Target force-kernel-clean has completed, $$(date +%H:%M:%S)"\n\ntest:',
        '\t@echo "Target force-kernel-clean has completed, $$(date +%H:%M:%S)"\nendif\n\ntest:',
        1,
    )
    print("patched force-kernel-clean skip for baklava")

mk.write_text(text)

drivers = Path.home() / "app-player/hd/guest/Drivers/Makefile"
dt = drivers.read_text()
old_d = "all:\n\t$(MAKE) -C VirtualBox all"
new_d = """all:
ifneq ($(and $(VBOX_GUEST_ADDITIONS),$(wildcard $(VBOX_GUEST_ADDITIONS)/vboxguest)),)
\t$(MAKE) -C VirtualBox all
else
\t@echo "Skipping VirtualBox guest drivers (VBOX_GUEST_ADDITIONS missing)"
endif"""
if old_d not in dt:
    if "Skipping VirtualBox guest drivers" in dt:
        print("Drivers VirtualBox skip already present")
    else:
        raise SystemExit("Drivers Makefile anchor not found")
else:
    drivers.write_text(dt.replace(old_d, new_d, 1))
    print("patched Drivers/Makefile VirtualBox skip")
