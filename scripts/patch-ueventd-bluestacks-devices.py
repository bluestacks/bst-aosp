#!/usr/bin/env python3
"""Add BlueStacks device node permissions to ueventd.rc (Henry A13/A16 boot patch).

Reference: references/android-16-boot-patches/10-aosp-repo-diff.patch
Without /dev/bstpgaipc (HST graphics IPC), gralloc/hwc cannot reach HD host.
"""
import os
import sys

AOSP = os.path.expanduser(os.environ.get("AOSP", "~/aosp16"))
RELEASE = os.path.expanduser(os.environ.get("RELEASE", "~/releases/Baklava64"))

BLOCK = """
# BlueStacks device permissions (ported from A13 ueventd.rc)
/dev/bst_ime            0666    root    root
/dev/bstpgaipc          0666    root    root
/dev/bstvmsg            0666    root    root
/dev/vboxuser           0666    root    root
/dev/hvmem              0660    system  system
"""


def patch_file(path: str) -> bool:
    if not os.path.isfile(path):
        print(f"skip missing {path}")
        return False
    text = open(path).read()
    if "/dev/bstpgaipc" in text:
        print(f"{path}: bstpgaipc rules already present")
        return False
    open(path + ".bak", "w").write(text)
    open(path, "w").write(text.rstrip() + "\n" + BLOCK)
    print(f"{path}: added BlueStacks ueventd device rules")
    return True


def main() -> int:
    changed = 0
    for rel in (
        "system/core/rootdir/ueventd.rc",
        "system/etc/ueventd.rc",
    ):
        p = os.path.join(AOSP, rel)
        if patch_file(p):
            changed += 1
    rel_ueventd = os.path.join(RELEASE, "system/etc/ueventd.rc")
    if patch_file(rel_ueventd):
        changed += 1
    print(f"UEVENTD_BST_DONE changed={changed}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
