#!/usr/bin/env python3
"""Ensure Makefile has required initrd cp lines."""
from pathlib import Path

OUT = "/home/clouddev/bst/workspace/markxu/aosp16/out_nxt_Baklava64/target/product/generic_x86_64"
mk = Path.home() / "app-player/hd/guest/BootImage/Makefile"
t = mk.read_text()

required = [
    "\tcp bstconf initrd/boot/bin/bstconf",
    "\tcp bstchkdata initrd/boot/bin/bstchkdata",
    "\tcp busybox-ndk initrd/boot/bin/busybox",
    "\tcp recovery initrd/boot/bin/recovery",
]
for line in required:
    if line.strip() not in t:
        anchor = "\tcp bstsetconf.sh initrd/boot/bstsetconf.sh"
        if anchor in t:
            t = t.replace(anchor, anchor + line, 1)
            print("added:", line.strip())

bins = ["ueventd", "apexd", "servicemanager", "aconfigd-system", "vdc", "vold", "keystore2"]
insert = "\tcp init-patched initrd/boot/init-patched\n"
for b in bins:
    l = f"\tcp {OUT}/system/bin/{b} initrd/boot/bin/{b}\n"
    if l.strip() not in t:
        insert += l
hws = f"\tcp {OUT}/system/system_ext/bin/hwservicemanager initrd/boot/bin/hwservicemanager\n"
if hws.strip() not in t:
    insert += hws
if "cgroups.json" not in t:
    insert += f"\tmkdir -p initrd/boot/etc\n"
    insert += f"\tcp {OUT}/system/etc/cgroups.json initrd/boot/etc/cgroups.json\n"

if insert != "\tcp init-patched initrd/boot/init-patched\n":
    t = t.replace("\tcp init.sh initrd/boot/init\n", "\tcp init.sh initrd/boot/init\n" + insert, 1)
    print("added binary cp lines")

mk.write_text(t)
print("Makefile OK")
