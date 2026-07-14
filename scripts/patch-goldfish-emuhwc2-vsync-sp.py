#!/usr/bin/env python3
"""BS-A16: EmuHWC2 VsyncThread must be held in sp<> before Thread::run().

A16 libutils Thread::run uses sp<Thread>::fromExisting(this), which calls
incStrongRequireStrong and aborts on embedded (non-sp-owned) Thread members.
"""
from __future__ import annotations

import pathlib
import sys

GGL = pathlib.Path.home() / "ggl/goldfish-opengl-pie"
H = GGL / "system/hwc2/EmuHWC2.h"
C = GGL / "system/hwc2/EmuHWC2.cpp"


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
    if not H.is_file() or not C.is_file():
        print(f"missing {H} or {C}", file=sys.stderr)
        return 1

    patch_file(
        H,
        "        VsyncThread mVsyncThread;",
        "        sp<VsyncThread> mVsyncThread;  // BS-A16: sp-owned before Thread::run",
        "EmuHWC2.h VsyncThread member",
    )

    patch_file(
        C,
        """    mVsyncPeriod(1000*1000*1000/60), // vsync is 60 hz
    mVsyncThread(*this),
    mClientTarget(),""",
        """    mVsyncPeriod(1000*1000*1000/60), // vsync is 60 hz
    mClientTarget(),""",
        "EmuHWC2.cpp ctor init list",
    )

    patch_file(
        C,
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
