#!/bin/bash
# Pre-mount com.android.runtime.apex in init.sh (apexd-bootstrap loop EBUSY on BS bringup)
set -euo pipefail
INIT=~/app-player/hd/guest/BootImage/init.sh
python3 - <<'PY'
from pathlib import Path
p = Path.home() / "app-player/hd/guest/BootImage/init.sh"
t = p.read_text()
t = t.replace(
    "for apexname in com.android.i18n; do",
    "for apexname in com.android.runtime com.android.i18n; do",
)
t = t.replace(
    "while [ $n -lt 16 ]; do",
    "while [ $n -lt 48 ]; do",
)
if "com.android.runtime com.android.i18n" not in t:
    raise SystemExit("apex loop pattern not found")
p.write_text(t)
print("init.sh: pre-mount runtime+i18n, loop scan 48")
PY
