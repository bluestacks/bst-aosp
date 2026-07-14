#!/usr/bin/env python3
"""BS-A16: glUtilsParamSize for GLES 3.1 params SF queries via safe_glGetIntegerv."""
from __future__ import annotations

import pathlib
import sys

GGL = pathlib.Path.home() / "ggl/goldfish-opengl-pie"
PATH = GGL / "shared/OpenglCodecCommon/glUtils.cpp"

ANCHOR = """    case GL_MAX_VERTEX_ATTRIBS:
    case GL_MAX_VERTEX_UNIFORM_VECTORS:"""

INSERT = """    case GL_MAX_VERTEX_ATTRIBS:
    case GL_MAX_VERTEX_ATTRIB_BINDINGS:  // BS-A16: GLES 3.1 (0x82DA)
    case GL_MAX_VERTEX_ATTRIB_STRIDE:    // BS-A16: GLES 3.1 (0x82E5)
    case GL_MAX_VERTEX_UNIFORM_VECTORS:"""


def main() -> int:
    if not PATH.is_file():
        print(f"missing {PATH}", file=sys.stderr)
        return 1
    text = PATH.read_text(encoding="utf-8")
    if "GL_MAX_VERTEX_ATTRIB_BINDINGS" in text and "case GL_MAX_VERTEX_ATTRIB_BINDINGS:" in text:
        print("OK already: glUtilsParamSize A16 params")
        return 0
    if ANCHOR not in text:
        raise SystemExit(f"anchor missing in {PATH}")
    PATH.write_text(text.replace(ANCHOR, INSERT, 1), encoding="utf-8")
    print("Patched: glUtilsParamSize A16 params")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
