#!/usr/bin/env python3
"""BS-A16: NVIDIA nvoglv64 crash — unbind GL_ELEMENT_ARRAY_BUFFER before SF glDrawArrays."""
from __future__ import annotations

import os
import pathlib
import sys

HD = pathlib.Path(os.environ.get("APP_PLAYER_TOP", r"C:\workspace\app-player"))
GLES_H = HD / "ggl/external/qemu/android/android-emugl/host/libs/Translator/include/GLcommon/GLEScontext.h"
GLES_CPP = HD / "ggl/external/qemu/android/android-emugl/host/libs/Translator/GLcommon/GLEScontext.cpp"
CTX_CPP = HD / "ggl/external/qemu/android/android-emugl/host/libs/Translator/GLES_V2/GLESv2Context.cpp"
IMP_CPP = HD / "ggl/external/qemu/android/android-emugl/host/libs/Translator/GLES_V2/GLESv2Imp.cpp"

MARKER = "nvidiaUnbindEBOOnDrawArrays"


def main() -> int:
    if MARKER in GLES_H.read_text(encoding="utf-8"):
        print("OK already: nvidiaUnbindEBOOnDrawArrays")
        return 0
    raise SystemExit(
        "manual patch required — apply host translator changes in app-player "
        "(GLEScontext.h/cpp, GLESv2Context.cpp, GLESv2Imp.cpp)"
    )


if __name__ == "__main__":
    raise SystemExit(main())
