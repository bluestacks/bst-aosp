#!/usr/bin/env python3
"""BS-A16: EmuHWC2 VsyncThread must be held in sp<> before Thread::run().

A16 libutils Thread::run uses sp<Thread>::fromExisting(this), which calls
incStrongRequireStrong and aborts on embedded (non-sp-owned) Thread members.
"""
from __future__ import annotations

import pathlib
import argparse
import os

from lib.android16_guard import require_historical_target



def patch_file(path: pathlib.Path, old: str, new: str, label: str) -> None:
    text = path.read_text(encoding="utf-8")
    if new in text:
        print(f"OK already: {label}")
        return
    if old not in text:
        raise SystemExit(f"anchor missing for {label} in {path}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print(f"Patched: {label}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--root",
        type=pathlib.Path,
        default=pathlib.Path(
            os.environ.get(
                "BST_GOLDFISH_OPENGL_ROOT",
                str(pathlib.Path.home() / "ggl/goldfish-opengl-pie"),
            )
        ),
    )
    parser.add_argument("--apply-historical", action="store_true")
    args = parser.parse_args()
    ggl = require_historical_target(args.root, args.apply_historical)
    header = ggl / "system/hwc2/EmuHWC2.h"
    source = ggl / "system/hwc2/EmuHWC2.cpp"
    if not header.is_file() or not source.is_file():
        raise SystemExit(f"missing {header} or {source}")

    patch_file(
        header,
        "        VsyncThread mVsyncThread;",
        "        sp<VsyncThread> mVsyncThread;  // BS-A16: sp-owned before Thread::run",
        "EmuHWC2.h VsyncThread member",
    )

    patch_file(
        source,
        """    mVsyncPeriod(1000*1000*1000/60), // vsync is 60 hz
    mVsyncThread(*this),
    mClientTarget(),""",
        """    mVsyncPeriod(1000*1000*1000/60), // vsync is 60 hz
    mClientTarget(),""",
        "EmuHWC2.cpp ctor init list",
    )

    patch_file(
        source,
        """    {
        mVsyncThread.run("", HAL_PRIORITY_URGENT_DISPLAY);
    }""",
        """    {
        // BS-A16: Thread::run requires existing strong ref (sp::fromExisting)
        mVsyncThread = sp<VsyncThread>::make(*this);
        mVsyncThread->run("EmuHWC2-Vsync", HAL_PRIORITY_URGENT_DISPLAY);
    }""",
        "EmuHWC2.cpp VsyncThread run",
    )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
