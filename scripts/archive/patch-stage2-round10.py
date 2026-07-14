#!/usr/bin/env python3
"""Round 10: verify stage2.sh has bringup block (full file deployed separately)."""
from pathlib import Path

p = Path.home() / "app-player/hd/guest/BootImage/stage2.sh"
t = p.read_text()
if "exec /tmp/init" not in t or "bootstrap-apex" not in t:
    print("stage2.sh incomplete — deploy stage2-round10.sh first")
    raise SystemExit(1)
print("stage2 round10 OK")
