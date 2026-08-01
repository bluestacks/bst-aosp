#!/usr/bin/env python3
"""Remove the retired bst_x86_64 product from the external HWC2 build filter."""

from __future__ import annotations

import argparse
import os
from pathlib import Path

from lib.android16_guard import require_historical_target


parser = argparse.ArgumentParser()
parser.add_argument(
    "--root",
    type=Path,
    default=Path(
        os.environ.get(
            "BST_GOLDFISH_OPENGL_ROOT",
            str(Path.home() / "ggl/goldfish-opengl-pie"),
        )
    ),
)
parser.add_argument("--apply-historical", action="store_true")
args = parser.parse_args()
root = require_historical_target(args.root, args.apply_historical)

path = root / "system/hwc2/Android.mk"
old = "ifneq ($(filter android_x86_64 bst_x86_64,$(TARGET_PRODUCT)),)"
new = "ifeq ($(TARGET_PRODUCT),android_x86_64)"
source = path.read_text(encoding="utf-8")
if new in source:
    print("already uses android_x86_64 only")
    raise SystemExit(0)
if old not in source:
    raise SystemExit(f"product-filter anchor not found in {path}")
path.write_text(source.replace(old, new, 1), encoding="utf-8")
print(f"removed bst_x86_64 from {path}")
