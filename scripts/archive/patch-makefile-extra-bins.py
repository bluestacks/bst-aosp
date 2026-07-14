#!/usr/bin/env python3
from pathlib import Path

p = Path.home() / "app-player/hd/guest/BootImage/Makefile"
t = p.read_text()
OUT = "/home/clouddev/bst/workspace/markxu/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/system/bin"
for b in ["aconfigd-system", "servicemanager", "hwservicemanager"]:
    line = f"\tcp {OUT}/{b} initrd/boot/bin/{b}\n"
    if b not in t:
        t = t.replace(
            f"\tcp {OUT}/apexd initrd/boot/bin/apexd\n",
            f"\tcp {OUT}/apexd initrd/boot/bin/apexd\n{line}",
        )
p.write_text(t)
print("Makefile extra bins OK")
