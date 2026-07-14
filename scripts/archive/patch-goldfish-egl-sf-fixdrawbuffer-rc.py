#!/usr/bin/env python3
"""BS-A16: SF/bootanim NVIDIA host crash — send fixDrawBuffer via rcGLHostInfo (Henry egl mmm)."""
from __future__ import annotations

import pathlib
import sys

GGL = pathlib.Path.home() / "ggl/goldfish-opengl-pie"
PATH = GGL / "system/egl/egl.cpp"

MARKER = "BS-A16: NVIDIA nvoglv64 draw-buffer crash"

INSERT_BLOCK = """        // BS-A16: NVIDIA nvoglv64 draw-buffer crash — host fixDrawBuffer via rcGLHostInfo
        if (strstr(pkg, "surfaceflinger") || strstr(pkg, "bootanimation")) {
            if (glHostInfoStr.length() > 0)
                glHostInfoStr.append(",");
            glHostInfoStr.append("fixDrawBuffer=0");
        }
"""

ANCHORS = [
    (
        """        android::String8 glHostInfoStr = (android::String8)bfam.getGLHostInfo(pkgName);
        GLsizei glHostInfoLen = strlen((GLchar*)glHostInfoStr.c_str());
        if (glHostInfoLen > 0)
        {
            rcEnc->rcGLHostInfo(rcEnc, rcContext, pkg, pkgLen, (GLchar*)glHostInfoStr.c_str(), glHostInfoLen);
        }""",
        """        android::String8 glHostInfoStr = (android::String8)bfam.getGLHostInfo(pkgName);
""" + INSERT_BLOCK + """        GLsizei glHostInfoLen = strlen((GLchar*)glHostInfoStr.c_str());
        if (glHostInfoLen > 0)
        {
            rcEnc->rcGLHostInfo(rcEnc, rcContext, pkg, pkgLen, (GLchar*)glHostInfoStr.c_str(), glHostInfoLen);
        }""",
    ),
    (
        """        android::String8 glHostInfoStr = (android::String8)bfam.getGLHostInfo(pkgName);
        GLsizei glHostInfoLen = strlen((GLchar*)glHostInfoStr.string());
        if (glHostInfoLen > 0)
        {
            rcEnc->rcGLHostInfo(rcEnc, rcContext, pkg, pkgLen, (GLchar*)glHostInfoStr.string(), glHostInfoLen);
        }""",
        """        android::String8 glHostInfoStr = (android::String8)bfam.getGLHostInfo(pkgName);
""" + INSERT_BLOCK + """        GLsizei glHostInfoLen = strlen((GLchar*)glHostInfoStr.string());
        if (glHostInfoLen > 0)
        {
            rcEnc->rcGLHostInfo(rcEnc, rcContext, pkg, pkgLen, (GLchar*)glHostInfoStr.string(), glHostInfoLen);
        }""",
    ),
]


def main() -> int:
    if not PATH.is_file():
        print(f"missing {PATH}", file=sys.stderr)
        return 1
    text = PATH.read_text(encoding="utf-8")
    if MARKER in text:
        print("OK already: egl rcGLHostInfo fixDrawBuffer for SF")
        return 0
    for old, new in ANCHORS:
        if old in text:
            PATH.write_text(text.replace(old, new, 1), encoding="utf-8")
            print("Patched: egl rcGLHostInfo fixDrawBuffer for SF/bootanim")
            return 0
    raise SystemExit(f"anchor missing in {PATH}")


if __name__ == "__main__":
    raise SystemExit(main())
