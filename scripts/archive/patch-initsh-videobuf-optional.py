#!/usr/bin/env python3
"""Skip videobuf-core.ko load when module not bundled (clouddev kernel out path)."""
from pathlib import Path

p = Path.home() / "app-player/hd/guest/BootImage/init.sh"
t = p.read_text()
old = "load_module /boot/bstmods/videobuf-core.ko"
new = (
    "if [ -f /boot/bstmods/videobuf-core.ko ]; then load_module /boot/bstmods/videobuf-core.ko; "
    "else echo \"<0>A16DBG: skip videobuf-core.ko (not in initrd)\" > /dev/kmsg; fi"
)
if old not in t:
    print("videobuf line not found")
    raise SystemExit(1)
t = t.replace(old, new, 1)
p.write_text(t)
print("init.sh: videobuf optional OK")
