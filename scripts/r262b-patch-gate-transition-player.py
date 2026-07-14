#!/usr/bin/env python3
"""TEMP(R262b): Gate registerTransitionPlayer on ENABLE_SHELL_TRANSITIONS.

TEMPORARY bringup workaround — pair with TEMP(R262); remove both when BLAST/SF
commit path is fixed. Baklava onInit() always registered TransitionPlayer even
when ENABLE_SHELL_TRANSITIONS=false; without this gate R262 alone is ineffective.
"""
from pathlib import Path

PATH = (
    Path.home()
    / "aosp16/frameworks/base/libs/WindowManager/Shell/src"
    / "com/android/wm/shell/transition/Transitions.java"
)
MARK = "TEMP(R262b) / BST bringup: gate TransitionPlayer on ENABLE_SHELL_TRANSITIONS"
LEGACY_MARKS = (
    "R262b / BST: only register TransitionPlayer when ENABLE_SHELL_TRANSITIONS",
    MARK,
)

OLD = """        // Register this transition handler with Core
        if (unifyShellBinders()) {
            mOrganizer.initializeDependencies(this);
        } else {
            try {
                mOrganizer.registerTransitionPlayer(mPlayerImpl);
            } catch (RuntimeException e) {
                throw e;
            }
        }
"""

NEW = f"""        // Register this transition handler with Core
        // {MARK}
        if (ENABLE_SHELL_TRANSITIONS) {{
            if (unifyShellBinders()) {{
                mOrganizer.initializeDependencies(this);
            }} else {{
                try {{
                    mOrganizer.registerTransitionPlayer(mPlayerImpl);
                }} catch (RuntimeException e) {{
                    throw e;
                }}
            }}
        }}
"""


def main() -> int:
    text = PATH.read_text()
    bak = PATH.with_suffix(PATH.suffix + ".bak-r262b")
    if not bak.exists():
        bak.write_text(text)
        print(f"backup {bak}")

    if any(m in text for m in LEGACY_MARKS):
        print("already patched (TEMP R262b)")
        return 0
    if OLD not in text:
        print("anchor not found")
        for i, line in enumerate(text.splitlines(), 1):
            if "registerTransitionPlayer" in line or "unifyShellBinders" in line:
                print(f"{i}: {line}")
        return 1

    PATH.write_text(text.replace(OLD, NEW, 1))
    print(f"patched {PATH}")
    for i, line in enumerate(PATH.read_text().splitlines(), 1):
        if "R262b" in line or "ENABLE_SHELL_TRANSITIONS" in line or "registerTransitionPlayer" in line:
            if i > 140 and i < 450:
                print(f"{i}: {line}")
    print("R262B_TEMP_PATCH_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
