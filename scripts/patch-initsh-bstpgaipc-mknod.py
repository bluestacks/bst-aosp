#!/usr/bin/env python3
"""Add /dev/bstpgaipc mknod to BootImage/init.sh (Henry bstvmsg/vboxuser pattern).

bstpgaipc.ko registers misc device 'bstpgaipc' but Henry init.sh only mknods
bstvmsg/vboxuser explicitly. Without early node, HST graphics IPC fails until
ueventd runs (too late for some early clients).
"""
from pathlib import Path

INIT = Path.home() / "app-player/hd/guest/BootImage/init.sh"

BLOCK = """
load_module /boot/bstmods/bstpgaipc.ko
bstpgaipc=`/boot/bin/busybox cat /sys/class/misc/bstpgaipc/uevent 2>/dev/null || /boot/bin/busybox cat /sys/devices/virtual/misc/bstpgaipc/uevent 2>/dev/null`
if [ ! -z "$bstpgaipc" ]; then
    MAJOR=`/boot/bin/busybox echo $bstpgaipc | /boot/bin/busybox cut -d '=' -f 2 | /boot/bin/busybox cut -d ' ' -f 1`
    MINOR=`/boot/bin/busybox echo $bstpgaipc | /boot/bin/busybox cut -d '=' -f 3 | /boot/bin/busybox cut -d ' ' -f 1`
    log_echo "making bstpgaipc node"
    /boot/bin/busybox mknod -m 0666 /dev/bstpgaipc c $MAJOR $MINOR
else
    log_echo "unable to make bstpgaipc dev node"
fi
"""

MARKER = "making bstpgaipc node"


def main() -> int:
    text = INIT.read_text()
    if MARKER in text:
        print(f"{INIT}: bstpgaipc mknod already present")
        return 0
    old = "load_module /boot/bstmods/bstpgaipc.ko\n"
    if old not in text:
        raise SystemExit("bstpgaipc load_module anchor missing")
    INIT.with_suffix(".sh.bak").write_text(text)
    text = text.replace(old, BLOCK.strip() + "\n", 1)
    INIT.write_text(text)
    print(f"{INIT}: added bstpgaipc mknod (Henry bstvmsg pattern)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
