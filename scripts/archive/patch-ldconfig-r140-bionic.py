#!/usr/bin/env python3
"""R140: add runtime bionic to com_android_art search+permitted paths (dex2oat64 libc.so)."""
from pathlib import Path

MARKER = "# BS bringup R140: runtime bionic in com_android_art (henry-7BU)"
BOOT_LC = Path.home() / "app-player/hd/guest/BootImage/linkerconfig"

REPLACEMENTS = [
    (
        "namespace.com_android_art.search.paths += /system/${LIB}\n",
        "namespace.com_android_art.search.paths += /system/${LIB}\n"
        "namespace.com_android_art.search.paths += /apex/com.android.runtime/${LIB}/bionic\n",
    ),
    (
        "namespace.com_android_art.permitted.paths += /data/statsd-libs\n",
        "namespace.com_android_art.permitted.paths += /data/statsd-libs\n"
        "namespace.com_android_art.permitted.paths += /apex/com.android.runtime/${LIB}/bionic\n",
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
    if not main_lc.is_file():
        raise SystemExit("ld.config.txt missing")
    text = main_lc.read_text()
    n = text.count("/apex/com.android.runtime/${LIB}/bionic")
    print(f"verify: runtime-bionic refs={n}")
    if n < 2:
        raise SystemExit("R140 bionic patch verify failed")
    if not ok and MARKER not in text:
        raise SystemExit("R140 patch did not apply")


if __name__ == "__main__":
    main()
