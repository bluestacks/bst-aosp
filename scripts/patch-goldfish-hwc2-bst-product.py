#!/usr/bin/env python3
"""BS-A16: build hwcomposer.android_x86_64 for bst_x86_64 (M1 used android_x86_64 lunch)."""
from __future__ import annotations

import pathlib
import sys

MK = pathlib.Path.home() / "ggl/goldfish-opengl-pie/system/hwc2/Android.mk"

OLD = "ifeq ($(TARGET_PRODUCT),android_x86_64)"
NEW = "ifneq ($(filter android_x86_64 bst_x86_64,$(TARGET_PRODUCT)),)"


def main() -> int:
    if not MK.is_file():
        print(f"missing {MK}", file=sys.stderr)
        return 1
    text = MK.read_text(encoding="utf-8")
    if NEW in text:
        print("OK already: hwc2 Android.mk bst_x86_64 product filter")
        return 0
    if OLD not in text:
        print(f"anchor missing in {MK}", file=sys.stderr)
        return 1
    MK.write_text(text.replace(OLD, NEW, 1), encoding="utf-8")
    print(f"Patched: {MK}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
