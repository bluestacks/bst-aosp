#!/usr/bin/env python3
"""List APKs that declare android.intent.category.HOME."""
import os
import re
import subprocess
import sys

AAPT = os.path.expanduser(
    "~/aosp16/out_nxt_Baklava64/host/linux-x86/bin/aapt2"
)
ROOT = os.path.expanduser("~/releases/Baklava64/system")


def main() -> int:
    found = []
    for dirpath, _, files in os.walk(ROOT):
        for f in files:
            if not f.endswith(".apk"):
                continue
            apk = os.path.join(dirpath, f)
            try:
                p = subprocess.run(
                    [AAPT, "dump", "xmltree", apk, "AndroidManifest.xml"],
                    capture_output=True,
                    text=True,
                    timeout=15,
                    check=False,
                )
            except Exception as e:
                print(f"skip {apk}: {e}", file=sys.stderr)
                continue
            if "android.intent.category.HOME" not in p.stdout:
                continue
            b = subprocess.run(
                [AAPT, "dump", "badging", apk],
                capture_output=True,
                text=True,
                timeout=15,
                check=False,
            )
            m = re.search(r"package: name='([^']+)'", b.stdout)
            pkg = m.group(1) if m else apk
            acts = re.findall(r"launchable-activity: name='([^']+)'", b.stdout)
            found.append((pkg, acts, apk))
            print(f"HOME: {pkg} acts={acts}\n  {apk}")
    print(f"TOTAL={len(found)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
