#!/usr/bin/env python3
from pathlib import Path

p = Path.home() / "aosp16/system/core/init/init.cpp"
t = p.read_text()
t = t.replace('property_set("ro.zygote"', 'InitPropertySet("ro.zygote"')
p.write_text(t)
print("init.cpp fixed")

mk = Path.home() / "app-player/hd/guest/BootImage/Makefile"
lines = mk.read_text().splitlines()
seen = set()
out = []
for line in lines:
    if "initrd/boot/bin/" in line and line.strip().startswith("cp "):
        if line in seen:
            continue
        seen.add(line)
    out.append(line)
mk.write_text("\n".join(out) + "\n")
print(f"Makefile deduped {len(lines)} -> {len(out)}")
