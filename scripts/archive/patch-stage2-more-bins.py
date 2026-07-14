#!/usr/bin/env python3
"""Extend stage2 per-file bind list for corrupted /system/bin binaries."""
from pathlib import Path
import re

p = Path.home() / "app-player/hd/guest/BootImage/stage2.sh"
t = p.read_text()

t = re.sub(
    r"for b in ueventd apexd; do",
    "for b in ueventd apexd aconfigd-system servicemanager hwservicemanager; do",
    t,
    count=1,
)
p.write_text(t)
print("stage2 bind list extended")
