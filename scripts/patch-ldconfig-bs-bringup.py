#!/usr/bin/env python3
"""Patch golden ld.config.txt for BS bringup staged lib dirs (Round 81)."""
import shutil
from pathlib import Path

MARKER = "# BS bringup: staged lib search paths (henry-7AA)"
GOLDEN = Path.home() / "aosp16/system/linkerconfig/testdata/golden_output/stage1"
BOOT_LC = Path.home() / "app-player/hd/guest/BootImage/linkerconfig"

# Insert only AFTER properties are defined (never += before initial =)
REPLACEMENTS = [
    (
        "namespace.com_android_art.search.paths = /apex/com.android.art/${LIB}\n",
        "namespace.com_android_art.search.paths = /apex/com.android.art/${LIB}\n"
        "namespace.com_android_art.search.paths += /data/art-libs\n"
        "namespace.com_android_art.search.paths += /data/statsd-libs\n"
        # R120: libjavacore/libopenjdk NEED libz/libcrypto/libssl/libjpeg (system libs, not in art APEX).
        # /system/${LIB} is already in permitted.paths; add to search so they resolve. APEX/art-libs win on order.
        "namespace.com_android_art.search.paths += /system/${LIB}\n",
    ),
    (
        "namespace.com_android_art.permitted.paths += /system_ext/${LIB}\n"
        "namespace.com_android_art.permitted.paths += /data\n",
        "namespace.com_android_art.permitted.paths += /system_ext/${LIB}\n"
        "namespace.com_android_art.permitted.paths += /data\n"
        "namespace.com_android_art.permitted.paths += /data/art-libs\n"
        "namespace.com_android_art.permitted.paths += /data/statsd-libs\n",
    ),
    (
        "namespace.com_android_i18n.search.paths = /apex/com.android.i18n/${LIB}\n",
        "namespace.com_android_i18n.search.paths = /apex/com.android.i18n/${LIB}\n"
        "namespace.com_android_i18n.search.paths += /data/i18n-libs\n"
        # R120: let i18n namespace also search /system for any system deps (already permitted).
        "namespace.com_android_i18n.search.paths += /system/${LIB}\n",
    ),
    (
        "namespace.com_android_i18n.permitted.paths += /system_ext/${LIB}\n",
        "namespace.com_android_i18n.permitted.paths += /system_ext/${LIB}\n"
        "namespace.com_android_i18n.permitted.paths += /data/i18n-libs\n",
    ),
    (
        "namespace.com_android_runtime.search.paths = /apex/com.android.runtime/${LIB}\n",
        "namespace.com_android_runtime.search.paths = /apex/com.android.runtime/${LIB}\n"
        # R162: crash_dump64 (runtime APEX) NEEDs libunwindstack -> libz.so; libz is in /system.
        # /system/${LIB} is already in permitted.paths; add to search so crash_dump64 links and
        # can unwind the zygote SIGSEGV backtrace. Same fix as R120 (art/i18n).
        "namespace.com_android_runtime.search.paths += /system/${LIB}\n",
    ),
]


def restore_golden() -> None:
    BOOT_LC.mkdir(parents=True, exist_ok=True)
    shutil.copy2(GOLDEN / "ld.config.txt", BOOT_LC / "ld.config.txt")
    art = GOLDEN / "com.android.art" / "ld.config.txt"
    if art.is_file():
        (BOOT_LC / "com.android.art").mkdir(parents=True, exist_ok=True)
        shutil.copy2(art, BOOT_LC / "com.android.art" / "ld.config.txt")
    rt = GOLDEN / "com.android.runtime" / "ld.config.txt"
    if rt.is_file():
        (BOOT_LC / "com.android.runtime").mkdir(parents=True, exist_ok=True)
        shutil.copy2(rt, BOOT_LC / "com.android.runtime" / "ld.config.txt")


def patch_file(path: Path) -> bool:
    if not path.is_file():
        return False
    text = path.read_text()
    if MARKER in text:
        print(f"{path}: already patched")
        return False
    changed = False
    for old, new in REPLACEMENTS:
        if old not in text:
            continue
        # R120: replace ALL occurrences (every ld.config block / process type), not just the first.
        text = text.replace(old, new)
        changed = True
    if changed:
        text = text.rstrip() + "\n" + MARKER + "\n"
        path.write_text(text)
        print(f"{path}: patched")
    else:
        print(f"{path}: no anchors matched")
    return changed


def main() -> None:
    restore_golden()
    for rel in ("ld.config.txt", "com.android.art/ld.config.txt", "com.android.runtime/ld.config.txt"):
        patch_file(BOOT_LC / rel)
    main_lc = BOOT_LC / "ld.config.txt"
    text = main_lc.read_text()
    if MARKER not in text:
        raise SystemExit("ld.config patch failed — marker missing")
    if "permitted.paths += /data/art-libs\nnamespace.com_android_art.permitted.paths =" in text:
        raise SystemExit("ld.config patch order wrong — permitted before =")
    art = text.count("/data/art-libs")
    i18n = text.count("/data/i18n-libs")
    statsd = text.count("/data/statsd-libs")
    print(f"verify: art-libs refs={art} i18n-libs refs={i18n} statsd-libs refs={statsd}")


if __name__ == "__main__":
    main()
