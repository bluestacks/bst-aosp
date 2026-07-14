#!/usr/bin/env python3
"""Restore BootImage Makefile initrd.img target + fix init.cpp zygote patch."""
from pathlib import Path

OUT = "/home/clouddev/bst/workspace/markxu/aosp16/out_nxt_Baklava64/target/product/generic_x86_64"

# Revert init.cpp ro.zygote patch (use stage2 /vendor/build.prop instead)
init_cpp = Path.home() / "aosp16/system/core/init/init.cpp"
t = init_cpp.read_text()
old = (
    "    PropertyInit();\n"
    "    if (GetProperty(\"ro.zygote\", \"\").empty()) {\n"
    "        LOG(WARNING) << \"ro.zygote missing, defaulting to zygote64 (BS bringup)\";\n"
    "        InitPropertySet(\"ro.zygote\", \"zygote64\");\n"
    "    }\n"
)
if old in t:
    t = t.replace(old, "    PropertyInit();\n", 1)
    init_cpp.write_text(t)
    print("init.cpp zygote patch reverted")

# Restore Makefile from git then patch initrd.img target
mk = Path.home() / "app-player/hd/guest/BootImage/Makefile"
import subprocess
subprocess.run(["git", "-C", str(mk.parent), "checkout", "--", "Makefile"], check=True)

t = mk.read_text()
bins = [
    "ueventd", "apexd", "servicemanager", "aconfigd-system", "vdc", "vold", "keystore2",
]
hws = f"{OUT}/system/system_ext/bin/hwservicemanager"

insert_after = "\tcp init.sh initrd/boot/init\n"
block = insert_after + "\tcp init-patched initrd/boot/init-patched\n"
for b in bins:
    block += f"\tcp {OUT}/system/bin/{b} initrd/boot/bin/{b}\n"
block += f"\tcp {hws} initrd/boot/bin/hwservicemanager\n"
block += f"\tmkdir -p initrd/boot/etc\n"
block += f"\tcp {OUT}/system/etc/cgroups.json initrd/boot/etc/cgroups.json\n"

# Only patch initrd.img target (second occurrence in file for 64-bit build)
idx = t.find("initrd.img: clean-initrd.img")
if idx < 0:
    raise SystemExit("initrd.img target not found")
sub = t[idx:]
pos = sub.find(insert_after)
if pos < 0:
    raise SystemExit("cp init.sh not found in initrd.img")
pos += idx + len(insert_after)
t = t[:pos] + block[len(insert_after):] + t[pos:]
mk.write_text(t)
print("Makefile restored and patched")

# stage2: add vendor/build.prop for ro.zygote
s2 = Path.home() / "app-player/hd/guest/BootImage/stage2.sh"
st = s2.read_text()
if "/vendor/build.prop" not in st:
    st = st.replace(
        "# BRINGUP: skip umount",
        "# ro.zygote when vendor partition missing\n"
        "/boot/bin/busybox mkdir -p /vendor\n"
        "echo 'ro.zygote=zygote64' > /vendor/build.prop\n"
        "# BRINGUP: skip umount",
    )
    s2.write_text(st)
    print("stage2 vendor/build.prop added")
