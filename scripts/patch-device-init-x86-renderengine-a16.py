#!/usr/bin/env python3
"""BS-A16: Baklava device init.x86.rc — goldfish ranchu RenderEngine/HWUI props (Henry device overlay)."""
from __future__ import annotations

import pathlib
import sys

PATH = pathlib.Path.home() / "aosp16/device/generic/common/init.x86.rc"
MARKER = "BS-A16: goldfish ranchu RenderEngine"

INSERT = """
    # BS-A16: goldfish ranchu RenderEngine/HWUI backend for SurfaceFlinger Skia GL
    setprop debug.hwui.renderer skiagl
    setprop debug.renderengine.backend skiaglthreaded
"""

OLD = """    exec u:r:init:s0 -- /sbin/modprobe sdcardfs

on init"""

NEW = """    exec u:r:init:s0 -- /sbin/modprobe sdcardfs
""" + INSERT + """
on init"""


def main() -> int:
    if not PATH.is_file():
        print(f"missing {PATH}", file=sys.stderr)
        return 1
    text = PATH.read_text(encoding="utf-8")
    if MARKER in text:
        print("OK already: init.x86.rc renderengine props")
        return 0
    if OLD not in text:
        raise SystemExit(f"anchor missing in {PATH}")
    PATH.write_text(text.replace(OLD, NEW, 1), encoding="utf-8")
    print(f"Patched: {PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
