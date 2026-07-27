#!/usr/bin/env python3
"""Mark mac-only P2 pending as deferred (win-first policy)."""
import json
from collections import Counter
from pathlib import Path

reg_path = Path(r"c:\workspace\bst-aosp\patches\registry.json")
d = json.loads(reg_path.read_text(encoding="utf-8"))
n = 0
for p in d["patches"]:
    if p.get("phase") != "P2" or p.get("port_status") != "pending":
        continue
    if p.get("platform") != "mac":
        continue
    p["port_status"] = "dropped"
    p["verification"] = (
        "P2 win-first: mac-only entry deferred — "
        "platform-win-first-mac-reuse.md; mac-behavior-deferred. "
        "Re-open when win counterpart ported + arm64 BoardConfig pass."
    )
    p["host_compat"] = "mac-behavior-deferred"
    n += 1

reg_path.write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
pend = [x for x in d["patches"] if x.get("port_status") == "pending" and x.get("phase") == "P2"]
print(f"mac deferred(dropped)={n}")
print("P2 pending", len(pend))
for x in pend:
    print(" ", x["id"], x.get("project_path"), x.get("platform"))
print(Counter(x.get("area") for x in pend))
