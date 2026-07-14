#!/usr/bin/env python3
"""Temporarily restore gfxstream Android.bp files for soong regen (init-only rebuild)."""
import os
import shutil
import sys

AOSP = os.path.expanduser(os.environ.get("AOSP", "~/aosp16"))
GFX = os.path.join(AOSP, "hardware/google/gfxstream")
DISABLED = os.path.join(AOSP, "hardware/google/gfxstream.disabled")
STUBS = os.path.join(AOSP, "hardware/google/gfxstream_soong_stubs")
MODE = sys.argv[1] if len(sys.argv) > 1 else "restore"

if MODE == "restore":
    if not os.path.isdir(DISABLED):
        print("gfxstream.disabled missing", file=sys.stderr)
        sys.exit(1)
    if os.path.isdir(GFX):
        print("gfxstream already exists")
    else:
        os.rename(DISABLED, GFX)
        print(f"renamed {DISABLED} -> {GFX}")
    count = 0
    for root, _, files in os.walk(GFX):
        for name in files:
            if name.endswith(".bp.bsdisabled"):
                src = os.path.join(root, name)
                dst = os.path.join(root, name[: -len(".bsdisabled")])
                if not os.path.exists(dst):
                    shutil.copy2(src, dst)
                    count += 1
    print(f"restored {count} Android.bp files")
elif MODE == "disable":
    if os.path.isdir(GFX):
        os.rename(GFX, DISABLED)
        print(f"renamed {GFX} -> {DISABLED}")
    for root, _, files in os.walk(DISABLED):
        for name in files:
            if name == "Android.bp":
                src = os.path.join(root, name)
                dst = src + ".bsdisabled"
                if not os.path.exists(dst):
                    shutil.copy2(src, dst)
                os.remove(src)
    print("disabled gfxstream Android.bp files")
else:
    print(f"usage: {sys.argv[0]} [restore|disable]", file=sys.stderr)
    sys.exit(1)
