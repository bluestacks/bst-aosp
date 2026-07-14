#!/usr/bin/env python3
"""init.sh: losetup -f for inner system.img (auto-alloc loop dev node)."""
from pathlib import Path

p = Path.home() / "app-player/hd/guest/BootImage/init.sh"
t = p.read_text()

old = """\tsfsloop=`find_free_loop_sfs`
\t/boot/bin/busybox losetup $sfsloop /sfs/system.img
\tif [ $? -ne 0 ]; then die_if_error "Cannot losetup system.img from sfs"; fi"""

new = """\tsfsloop=`/boot/bin/busybox losetup -f /sfs/system.img`
\tif [ $? -ne 0 ] || [ -z "$sfsloop" ]; then die_if_error "Cannot losetup system.img from sfs"; fi"""

if "losetup -f /sfs/system.img" in t:
    print("init.sh losetup -f already patched")
elif old not in t:
    raise SystemExit("losetup block not found")
else:
    t = t.replace(old, new, 1)
    # Drop unused find_free_loop_sfs if present
    import re
    t = re.sub(
        r"\n\tfind_free_loop_sfs\(\)\n\t\{[^}]+\}\n",
        "\n",
        t,
        count=1,
    )
    p.write_text(t)
    print("init.sh: losetup -f for inner system.img")
