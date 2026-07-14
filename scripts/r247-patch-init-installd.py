#!/usr/bin/env python3
"""R247 / Henry 7X-2: start installd + gatekeeperd early (on boot, not only on nonencrypted)."""
import sys
from pathlib import Path

MARK = "# R247 / Henry 7X-2: start installd early for PMS"
BLOCK = f"""    {MARK}
    start installd
    start gatekeeperd
"""

def patch(text: str) -> str:
    if MARK in text:
        print("already patched")
        return text
    needle = "    class_start core\n\non nonencrypted"
    if needle not in text:
        raise SystemExit("anchor not found: class_start core -> on nonencrypted")
    return text.replace(needle, f"    class_start core\n\n{BLOCK}\non nonencrypted", 1)


def main() -> None:
    path = Path(sys.argv[1] if len(sys.argv) > 1 else Path.home() / "releases/Baklava64/system/etc/init/hw/init.rc")
    text = path.read_text()
    path.write_text(patch(text))
    print(f"patched {path}")
    for i, line in enumerate(path.read_text().splitlines(), 1):
        if "R247" in line or (i > 1235 and i < 1265):
            if "class_start" in line or "start installd" in line or "nonencrypted" in line or "R247" in line:
                print(f"{i}: {line}")


if __name__ == "__main__":
    main()
