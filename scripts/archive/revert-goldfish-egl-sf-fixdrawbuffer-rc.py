#!/usr/bin/env python3
"""Revert BS-A16 guest egl fixDrawBuffer rcGLHostInfo (NVIDIA-only workaround)."""
from __future__ import annotations

import pathlib
import sys

GGL = pathlib.Path.home() / "ggl/goldfish-opengl-pie"
PATH = GGL / "system/egl/egl.cpp"
MARKER = "BS-A16: NVIDIA nvoglv64 draw-buffer crash"

BLOCK = """        // BS-A16: NVIDIA nvoglv64 draw-buffer crash — host fixDrawBuffer via rcGLHostInfo
        if (strstr(pkg, "surfaceflinger") || strstr(pkg, "bootanimation")) {
            if (glHostInfoStr.length() > 0)
                glHostInfoStr.append(",");
            glHostInfoStr.append("fixDrawBuffer=0");
        }
"""


def main() -> int:
    if not PATH.is_file():
        print(f"missing {PATH}", file=sys.stderr)
        return 1
    text = PATH.read_text(encoding="utf-8")
    if MARKER not in text:
        print("OK already reverted: egl fixDrawBuffer block absent")
        return 0
    if BLOCK not in text:
        raise SystemExit(f"block mismatch in {PATH}")
    PATH.write_text(text.replace(BLOCK, "", 1), encoding="utf-8")
    print(f"Reverted: {PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
