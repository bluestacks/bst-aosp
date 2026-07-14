#!/usr/bin/env python3
"""R141: system namespace search.paths += runtime bionic (dex2oat64 libc via default→system link)."""
from pathlib import Path

MARKER = "# BS bringup R141: system search bionic for dex2oat (henry-7BU)"
BOOT_LC = Path.home() / "app-player/hd/guest/BootImage/linkerconfig"

REPLACEMENTS = [
    (
        "namespace.system.search.paths = /system/${LIB}\n"
        "namespace.system.search.paths += /system_ext/${LIB}\n",
        "namespace.system.search.paths = /system/${LIB}\n"
        "namespace.system.search.paths += /system_ext/${LIB}\n"
        "namespace.system.search.paths += /apex/com.android.runtime/${LIB}/bionic\n",
    ),
]


def patch_file(path: Path) -> bool:
    if not path.is_file():
        print(f"{path}: missing")
        return False
    text = path.read_text()
    if MARKER in text:
        print(f"{path}: already patched")
        return False
    changed = False
    for old, new in REPLACEMENTS:
        if old not in text:
            continue
        text = text.replace(old, new)
        changed = True
    if not changed:
        print(f"{path}: no anchors matched")
        return False
    text = text.rstrip() + "\n" + MARKER + "\n"
    path.write_text(text)
    print(f"{path}: patched")
    return True


def main() -> None:
    ok = False
    for rel in ("ld.config.txt", "com.android.art/ld.config.txt"):
        if patch_file(BOOT_LC / rel):
            ok = True
    main_lc = BOOT_LC / "ld.config.txt"
    n = main_lc.read_text().count("namespace.system.search.paths += /apex/com.android.runtime/${LIB}/bionic")
    print(f"verify: system-search-bionic refs={n}")
    if n < 1:
        raise SystemExit("R141 system bionic search patch verify failed")
    if not ok and MARKER not in main_lc.read_text():
        raise SystemExit("R141 patch did not apply")


if __name__ == "__main__":
    main()
