#!/usr/bin/env python3
"""R248 / Henry 7W-2 + 7X-1: disable HintManagerService and BiometricService on BS (no power/gatekeeper HAL)."""
from pathlib import Path

PATH = Path.home() / "aosp16/frameworks/base/services/java/com/android/server/SystemServer.java"
MARK_H = "// R248 / Henry 7W-2: no power HAL on BS"
MARK_B = "// R248 / Henry 7X-1: no gatekeeper HAL on BS"

PATCHES = [
    (
        MARK_H,
        """            t.traceBegin("StartHintManager");
            mSystemServiceManager.startService(HintManagerService.class);
            t.traceEnd();""",
        f"""            t.traceBegin("StartHintManager");
            {MARK_H}
            // mSystemServiceManager.startService(HintManagerService.class);
            t.traceEnd();""",
    ),
    (
        MARK_B,
        """            t.traceBegin("StartBiometricService");
            mSystemServiceManager.startService(BiometricService.class);
            t.traceEnd();""",
        f"""            t.traceBegin("StartBiometricService");
            {MARK_B}
            // mSystemServiceManager.startService(BiometricService.class);
            t.traceEnd();""",
    ),
]


def main() -> None:
    text = PATH.read_text()
    for mark, old, new in PATCHES:
        if mark in text:
            print(f"already patched: {mark}")
            continue
        if old not in text:
            raise SystemExit(f"anchor missing for {mark}")
        text = text.replace(old, new, 1)
        print(f"patched: {mark}")
    PATH.write_text(text)


if __name__ == "__main__":
    main()
