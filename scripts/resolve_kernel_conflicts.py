#!/usr/bin/env python3
"""Apply the recorded kernel-a16 conflict decisions from cont.103."""

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
kernel = root / "kernel-a16"
conflict = re.compile(r"<<<<<<< ours\n.*?=======\n.*?>>>>>>> theirs\n", re.S)


def resolve(path: Path, preferred: str, label: str) -> None:
    source = path.read_text(encoding="utf-8")
    before = len(conflict.findall(source))

    def replacement(match: re.Match[str]) -> str:
        for line in match.group(0).splitlines():
            if preferred in line:
                return line + "\n"
        return match.group(0)

    updated = conflict.sub(replacement, source)
    if before == 0:
        raise SystemExit(f"no conflict marker found in {path}")
    if "<<<<<<<" in updated or ">>>>>>>" in updated:
        raise SystemExit(f"unresolved conflict marker remains in {path}")
    path.write_text(updated, encoding="utf-8")
    print(f"{label}: resolved {before} conflict(s)")


resolve(
    kernel / "arch/x86/kernel/setup.c",
    "bstandroid=tiramisu64",
    "setup.c -> tiramisu64",
)
resolve(
    kernel / "fs/bst_hooks.h",
    "bst_current_uid_is_user_app(void)",
    "bst_hooks.h -> modern (void) signature",
)
