#!/usr/bin/env python3
"""BS-A16 R237: switch RenderEngine to skiavkthreaded (Vulkan Skia) on Baklava init.x86.rc."""
from __future__ import annotations

import pathlib
import sys

PATH = pathlib.Path.home() / "aosp16/device/generic/common/init.x86.rc"
MARKER = "debug.renderengine.backend skiavkthreaded"


def main() -> int:
    if not PATH.is_file():
        print(f"missing {PATH}", file=sys.stderr)
        return 1
    text = PATH.read_text(encoding="utf-8")
    if MARKER in text:
        print("OK already: skiavkthreaded")
        return 0
    if "debug.renderengine.backend skiaglthreaded" in text:
        text = text.replace(
            "setprop debug.renderengine.backend skiaglthreaded",
            "setprop debug.renderengine.backend skiavkthreaded",
            1,
        )
    elif "BS-A16: goldfish ranchu RenderEngine" not in text:
        old = """    exec u:r:init:s0 -- /sbin/modprobe sdcardfs

on init"""
        new = """    exec u:r:init:s0 -- /sbin/modprobe sdcardfs

    # BS-A16: goldfish ranchu RenderEngine/HWUI backend for SurfaceFlinger Skia VK
    setprop debug.hwui.renderer skiagl
    setprop debug.renderengine.backend skiavkthreaded

on init"""
        if old not in text:
            raise SystemExit(f"anchor missing in {PATH}")
        text = text.replace(old, new, 1)
    else:
        raise SystemExit(f"unexpected init.x86.rc state in {PATH}")
    PATH.write_text(text, encoding="utf-8")
    print(f"Patched: {PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
