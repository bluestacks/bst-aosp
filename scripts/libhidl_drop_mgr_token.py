#!/usr/bin/env python3
"""Apply the recorded libhidl manifest conflict resolution."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

from lib.android16_guard import require_historical_target


parser = argparse.ArgumentParser()
parser.add_argument("--root", type=Path, default=Path("~/android-16"))
parser.add_argument("--apply-historical", action="store_true")
args = parser.parse_args()
root = require_historical_target(args.root, args.apply_historical)

path = root / "system/libhidl/vintfdata/manifest.xml"
source = path.read_text(encoding="utf-8")
drop = {"android.hidl.manager", "android.hidl.token"}
parts = re.split(r"(<hal\b.*?</hal>)", source, flags=re.S)
output: list[str] = []
removed: list[str] = []
for part in parts:
    if part.startswith("<hal") and "</hal>" in part:
        match = re.search(r"<name>([^<]+)</name>", part)
        name = match.group(1).strip() if match else ""
        if name in drop:
            removed.append(name)
            continue
    output.append(part)
updated = re.sub(r"\n{3,}", "\n\n", "".join(output))
if set(removed) != drop:
    raise SystemExit(f"expected to remove {sorted(drop)}, found {sorted(removed)}")
path.write_text(updated, encoding="utf-8")
print(f"updated {path}; removed={sorted(removed)}")
