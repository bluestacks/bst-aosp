#!/usr/bin/env python3
"""Inject bs_bootlog service into system init.rc (Henry stage2-good-vhd pattern).

bs_bootlog runs from initrd /boot/bin/bs_bootlog.sh; needs init.rc service + post-fs-data start.
"""
import os
import sys

AOSP = os.path.expanduser(os.environ.get("AOSP", "~/aosp16"))
RELEASE = os.path.expanduser(os.environ.get("RELEASE", "~/releases/Baklava64"))

SERVICE_BLOCK = """# BlueStacks boot diagnostic: logcat -> kmsg for Player.log (Henry 7AJ/7R)
service bs_bootlog /boot/bin/sh /boot/bin/bs_bootlog.sh
    user root
    group system
    disabled
    seclabel u:r:su:s0

on post-fs-data
    start bs_bootlog

"""

MARKER = "service bs_bootlog"


def patch_init_rc(path: str) -> bool:
    if not os.path.isfile(path):
        print(f"skip missing {path}")
        return False
    text = open(path).read()
    if MARKER in text:
        print(f"{path}: bs_bootlog already present")
        return False
    anchor = "on post-fs-data"
    if anchor in text:
        new_text = text.replace(anchor, SERVICE_BLOCK + anchor, 1)
    else:
        new_text = text.rstrip() + "\n\n" + SERVICE_BLOCK
    open(path + ".bak", "w").write(text)
    open(path, "w").write(new_text)
    print(f"{path}: added bs_bootlog service")
    return True


def main() -> int:
    changed = 0
    for rel in (
        "system/core/rootdir/init.rc",
        "system/etc/init/hw/init.rc",
    ):
        p = os.path.join(AOSP, rel)
        if patch_init_rc(p):
            changed += 1
    for rel_rc in (
        "system/etc/init/hw/init.rc",
        "system/etc/init/init.rc",
    ):
        p = os.path.join(RELEASE, rel_rc)
        if os.path.isfile(p) and patch_init_rc(p):
            changed += 1
            break
    print(f"BS_BOOTLOG_INIT_RC_DONE changed={changed}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
