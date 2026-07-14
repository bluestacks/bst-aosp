#!/usr/bin/env python3
from pathlib import Path

for rel in [
    "app-player/hd/guest/BootImage/bstsetup.env",
    "app-player/hd/guest/BootImage/initrd/boot/bstsetup.env",
]:
    p = Path.home() / rel
    if not p.exists():
        print("missing", p)
        continue
    t = p.read_text()
    # broken form written by previous patch
    bad = 'if [ \\"$totalfiles\\" -eq 0 ]; then'
    good = 'if [ "$totalfiles" -eq 0 ]; then'
    n = t.count(bad)
    t = t.replace(bad, good)
    # also literal backslash-quote variants
    bad2 = 'if [ \\"$totalfiles\\" -eq 0 ]; then'
    p.write_text(t)
    print(p, "replaced", n)
    for i, ln in enumerate(p.read_text().splitlines(), 1):
        if "totalfiles" in ln and "eq 0" in ln:
            print(i, repr(ln))
