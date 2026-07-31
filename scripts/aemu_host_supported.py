#!/usr/bin/env python3
"""Apply the recorded 25Q4 gfxstream host-variant conflict resolution."""

from __future__ import annotations

import argparse
from pathlib import Path

from lib.android16_guard import require_historical_target


parser = argparse.ArgumentParser()
parser.add_argument("--root", type=Path, default=Path("~/android-16"))
parser.add_argument("--apply-historical", action="store_true")
args = parser.parse_args()
root = require_historical_target(args.root, args.apply_historical)

path = root / "hardware/google/aemu/host-common/Android.bp"
source = path.read_text(encoding="utf-8")
anchor = '    name: "gfxstream_host_common",\n    // defaults: ["gfxstream_defaults"],\n'
replacement = (
    '    name: "gfxstream_host_common",\n'
    '    // defaults: ["gfxstream_defaults"],  // A16DBG: disabled (goldfish conflict, a13 BST port)\n'
    '    host_supported: true,  // A16DBG: 25Q4 gfxstream host modules need host variant\n'
)
if "host_supported: true,  // A16DBG: 25Q4 gfxstream" in source:
    print("already applied")
    raise SystemExit(0)
if anchor not in source:
    raise SystemExit("gfxstream_host_common anchor not found")
path.write_text(source.replace(anchor, replacement, 1), encoding="utf-8")
print(f"updated {path}")
