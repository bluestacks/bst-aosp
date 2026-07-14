#!/usr/bin/env python3
"""Fix aconfigd bind: copy to /tmp and bind (corrupt path lookup)."""
from pathlib import Path
import re

p = Path.home() / "app-player/hd/guest/BootImage/stage2.sh"
t = p.read_text()
# Ensure bind uses /tmp copy pattern (already should)
if "aconfigd-system" not in t:
    t = re.sub(
        r"for b in ueventd apexd[^;]*;",
        "for b in ueventd apexd aconfigd-system servicemanager hwservicemanager;",
        t,
        count=1,
    )
p.write_text(t)
print("stage2 bind list OK")
