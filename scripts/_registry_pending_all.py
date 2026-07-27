#!/usr/bin/env python3
import json
from collections import Counter
from pathlib import Path
r = json.loads(Path(r"c:\workspace\bst-aosp\patches\registry.json").read_text(encoding="utf-8"))
items = r["patches"]
pend = [i for i in items if i.get("port_status") == "pending"]
print("pending total", len(pend))
print("pending by phase", dict(Counter(str(i.get("phase")) for i in pend)))
print("pending by area", dict(Counter(i.get("area") for i in pend)))
print("\nAll pending:")
for i in sorted(pend, key=lambda x: (str(x.get("phase")), x.get("area") or "", x.get("id") or "")):
    print(
        f"P{i.get('phase')} {(i.get('port_status') or ''):8} {(i.get('related_group') or '-'):20} {(i.get('id') or '')[:48]:48} {(i.get('project_path') or '')[:42]}"
    )
print("\n=== P2-FRAMEWORK-REST related ===")
for i in items:
    if i.get("related_group") == "P2-FRAMEWORK-REST" or i.get("id") in (
        "win-frameworks-base",
        "mac-frameworks-base",
        "win-frameworks-native",
        "mac-frameworks-native",
    ):
        print(
            f"{i.get('port_status'):14} temp={i.get('temp_debt')} {i.get('id'):40} {(i.get('verification') or '')[:70]}"
        )
