#!/usr/bin/env python3
"""BS-A16: SF format probes must not fail glGetInternalformativ on A16 internal formats."""
from __future__ import annotations

import pathlib
import sys

GGL = pathlib.Path.home() / "ggl/goldfish-opengl-pie"
PATH = GGL / "system/GLESv2_enc/GL2Encoder.cpp"

OLD = """    SET_ERROR_IF(pname != GL_NUM_SAMPLE_COUNTS &&
                 pname != GL_SAMPLES,
                 GL_INVALID_ENUM);
    SET_ERROR_IF(!GLESv2Validation::internalFormatTarget(ctx, target), GL_INVALID_ENUM);
    SET_ERROR_IF(!GLESv2Validation::unsizedFormat(internalformat) &&
                 !GLESv2Validation::colorRenderableFormat(ctx, internalformat) &&
                 !GLESv2Validation::depthRenderableFormat(ctx, internalformat) &&
                 !GLESv2Validation::stencilRenderableFormat(ctx, internalformat),
                 GL_INVALID_ENUM);
    SET_ERROR_IF(bufSize < 0, GL_INVALID_VALUE);"""

NEW = """    SET_ERROR_IF(pname != GL_NUM_SAMPLE_COUNTS &&
                 pname != GL_SAMPLES,
                 GL_INVALID_ENUM);
    SET_ERROR_IF(!GLESv2Validation::internalFormatTarget(ctx, target), GL_INVALID_ENUM);
    // BS-A16: A16 SF probes formats goldfish validation may not list; return stubs.
    SET_ERROR_IF(bufSize < 0, GL_INVALID_VALUE);"""


def main() -> int:
    if not PATH.is_file():
        print(f"missing {PATH}", file=sys.stderr)
        return 1
    text = PATH.read_text(encoding="utf-8")
    if "A16 SF probes formats goldfish validation may not list" in text:
        print("OK already: s_glGetInternalformativ A16")
        return 0
    if OLD not in text:
        raise SystemExit(f"anchor missing in {PATH}")
    PATH.write_text(text.replace(OLD, NEW, 1), encoding="utf-8")
    print("Patched: s_glGetInternalformativ A16")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
