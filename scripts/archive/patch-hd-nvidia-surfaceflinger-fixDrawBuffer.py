#!/usr/bin/env python3
"""BS-A16: NVIDIA nvoglv64 crash on SF draw-buffer setup — enable fixDrawBuffer workaround."""
from __future__ import annotations

import os
import pathlib
import sys

HD = pathlib.Path(os.environ.get("APP_PLAYER_TOP", r"C:\workspace\app-player"))
PATH = HD / "ggl/external/qemu/android/android-emugl/host/libs/Translator/GLcommon/GLEScontext.cpp"

OLD = """        if ((GLEScontext::s_currentVendor == GlVendor::NVIDIA) &&
                s_nvidiaFixDrawBufferList.contains(pkgName))
            m_glPkgWorkaround.fixDrawBuffer = true;"""

NEW = """        if ((GLEScontext::s_currentVendor == GlVendor::NVIDIA) &&
                (s_nvidiaFixDrawBufferList.contains(pkgName) ||
                 strstr(pkgName, "surfaceflinger") ||
                 strstr(pkgName, "bootanimation")))
            m_glPkgWorkaround.fixDrawBuffer = true;  // BS-A16: SF/bootanim on nvoglv64"""


def main() -> int:
    if not PATH.is_file():
        print(f"missing {PATH}", file=sys.stderr)
        return 1
    text = PATH.read_text(encoding="utf-8")
    if "BS-A16: SF/bootanim on nvoglv64" in text:
        print("OK already: NVIDIA SF fixDrawBuffer")
        return 0
    if OLD not in text:
        raise SystemExit(f"anchor missing in {PATH}")
    PATH.write_text(text.replace(OLD, NEW, 1), encoding="utf-8")
    print(f"Patched: {PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
