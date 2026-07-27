#!/bin/bash
set -euo pipefail
ALLOW=~/aosp16/build/soong/scripts/check_boot_jars/package_allowed_list.txt
python3 - <<'PY'
from pathlib import Path
p = Path.home() / "aosp16/build/soong/scripts/check_boot_jars/package_allowed_list.txt"
t = p.read_text()
if r"com\.bluestacks\.internal" in t:
    print("allowlist ok")
else:
    needle = "com\\.bluestacks\\.os\\..*\n"
    insert = needle + "com\\.bluestacks\\.internal\ncom\\.bluestacks\\.internal\\..*\n"
    if needle not in t:
        raise SystemExit("needle missing")
    p.write_text(t.replace(needle, insert, 1))
    print("inserted internal allowlist")
print("---")
for i, line in enumerate(p.read_text().splitlines(), 1):
    if "bluestacks" in line:
        print(f"{i}:{line}")
PY

# kill stale awaits without build
pkill -f p2_await_g1 || true
pkill -f 'g1_build.sh' || true
pkill -f 'soong_ui --build-mode' || true
sleep 2

nohup bash ~/bst-aosp/scripts/g1_build.sh > ~/g1_build_droid.log 2>&1 &
echo build=$!
sleep 3
nohup bash ~/bst-aosp/scripts/p2_await_g1_then_pack.sh </dev/null >/dev/null 2>&1 &
echo await=$!
sleep 2
pgrep -af 'g1_build.sh|p2_await|soong_ui --build-mode' | grep -v 'bash -c' | head -6
echo START_OK
