#!/usr/bin/env python3
"""Let apexd-bootstrap own runtime APEX — remove init.sh pre-mount conflict."""
from pathlib import Path

p = Path.home() / "app-player/hd/guest/BootImage/init.sh"
t = p.read_text()

# Only pre-mount i18n; runtime is bootstrap apex for apexd-bootstrap
t = t.replace(
    "for apexname in com.android.runtime com.android.i18n; do",
    "for apexname in com.android.i18n; do",
)

# Skip init.sh linkerconfig for baklava64 — init.rc bootstrap stub + apexd handles it
old_bkl = (
    '\tif [ "$bstandroid" == "baklava64" ]; then\n'
    '\t\tmkdir /linkerconfig\n'
    '\t\t/apex/com.android.runtime/bin/linkerconfig --target /linkerconfig\n'
    '\t\techo "<0>A16DBG: linkerconfig rc=$?; ld.config=$(ls -l /linkerconfig/ld.config.txt 2>&1)" > /dev/kmsg\n'
    '\tfi'
)
new_bkl = (
    '\tif [ "$bstandroid" == "baklava64" ]; then\n'
    '\t\tmkdir -p /linkerconfig/bootstrap /linkerconfig/default\n'
    '\t\techo "#" > /linkerconfig/bootstrap/ld.config.txt\n'
    '\t\techo "#" > /linkerconfig/default/ld.config.txt\n'
    '\t\techo "<0>A16DBG: linkerconfig stub for baklava64" > /dev/kmsg\n'
    '\tfi'
)
if old_bkl in t:
    t = t.replace(old_bkl, new_bkl)
    p.write_text(t)
    print("init.sh runtime/linkerconfig OK")
else:
    print("init.sh pattern not found")
