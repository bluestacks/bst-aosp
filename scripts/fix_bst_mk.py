#!/usr/bin/env python3
from pathlib import Path

BLOCK = """LOCAL_C_INCLUDES += \\
    hardware/libhardware/include \\
    system/core/libsystem/include"""

for name in ("memtrack", "power"):
    p = Path.home() / "aosp16/hardware/bst" / name / "Android.mk"
    lines = p.read_text().splitlines()
    out = []
    i = 0
    while i < len(lines):
        if lines[i].startswith("LOCAL_C_INCLUDES"):
            out.extend(BLOCK.splitlines())
            i += 1
            while i < len(lines) and (
                lines[i].startswith("    ") or lines[i].startswith("\t")
            ):
                i += 1
            continue
        out.append(lines[i])
        i += 1
    p.write_text("\n".join(out) + "\n")
    print(f"fixed {name}")
