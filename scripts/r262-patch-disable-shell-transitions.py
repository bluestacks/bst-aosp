#!/usr/bin/env python3
"""TEMP(R262): Disable Shell Transitions (Settings / app layers stuck EXITING).

TEMPORARY bringup workaround — remove when goldfish BLAST/SF transaction commit
callbacks return reliably. Not a permanent product default.

A16 Baklava hardcodes ENABLE_SHELL_TRANSITIONS=true. BLAST/SF transaction
commit callbacks never return on BST goldfish path → Transition Roots stick,
app layers stay hidden by parent → Settings invisible while Activity is RESUMED.

Force false so SystemUI skips registerTransitionPlayer (see TEMP R262b) → WMS
isShellTransitionsEnabled()==false → legacy path, no stuck Transition Roots.
"""
from pathlib import Path

PATH = (
    Path.home()
    / "aosp16/frameworks/base/libs/WindowManager/Shell/src"
    / "com/android/wm/shell/transition/Transitions.java"
)
MARK = (
    "TEMP(R262) / BST bringup: disable shell transitions until BLAST commit "
    "fixed (stuck EXITING)"
)
# Older marker from first apply; treat as already patched
LEGACY_MARKS = (
    "R262 / BST: disable shell transitions (stuck BLAST commit / EXITING)",
    MARK,
)

OLD = (
    "    /** Set to {@code true} to enable shell transitions. */\n"
    "    public static final boolean ENABLE_SHELL_TRANSITIONS = true;\n"
)

NEW = (
    "    /** Set to {@code true} to enable shell transitions. */\n"
    f"    // {MARK}\n"
    "    public static final boolean ENABLE_SHELL_TRANSITIONS = false;\n"
)


def main() -> int:
    text = PATH.read_text()
    bak = PATH.with_suffix(PATH.suffix + ".bak-r262")
    if not bak.exists():
        bak.write_text(text)
        print(f"backup {bak}")

    if any(m in text for m in LEGACY_MARKS) and "ENABLE_SHELL_TRANSITIONS = false" in text:
        print("already patched (TEMP R262)")
        return 0
    if OLD not in text:
        print("anchor not found; current ENABLE lines:")
        for i, line in enumerate(text.splitlines(), 1):
            if "ENABLE_SHELL_TRANSITIONS" in line:
                print(f"  {i}: {line}")
        return 1

    PATH.write_text(text.replace(OLD, NEW, 1))
    print(f"patched {PATH}")
    for i, line in enumerate(PATH.read_text().splitlines(), 1):
        if "ENABLE_SHELL_TRANSITIONS" in line or "TEMP(R262)" in line or "R262" in line:
            print(f"{i}: {line}")
    print("R262_TEMP_PATCH_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
