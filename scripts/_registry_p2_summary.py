#!/usr/bin/env python3
import json
from collections import Counter, defaultdict
from pathlib import Path
p = Path(r"c:\workspace\bst-aosp\patches\registry.json")
r = json.loads(p.read_text(encoding="utf-8"))
items = r.get("customizations") or r.get("items") or r.get("entries")
if items is None:
    for k, v in r.items():
        if isinstance(v, list) and v and isinstance(v[0], dict) and "id" in v[0]:
            items = v
            print("key", k)
            break
print("total", len(items))
print("by_status", dict(Counter(i.get("port_status") for i in items)))
print("by_phase", dict(Counter(str(i.get("phase")) for i in items)))
pend = [
    i
    for i in items
    if i.get("port_status") in ("pending", "in_progress", "in-progress", "blocked")
]
print("open(pending/in_progress/blocked)", len(pend))
p2 = [i for i in pend if str(i.get("phase")) in ("P2", "Phase2", "2", "p2")]
print("open P2", len(p2))
print("P2 area", dict(Counter(i.get("area") for i in p2)))
print("P2 related_group", Counter(i.get("related_group") for i in p2).most_common(25))
print("P2 platform", dict(Counter(i.get("platform") for i in p2)))
print("\n=== open P2 frameworks ===")
fw = [
    i
    for i in p2
    if (i.get("area") == "frameworks")
    or "framework" in (i.get("project_path") or "")
]
for i in sorted(fw, key=lambda x: (x.get("port_status") or "", x.get("id") or "")):
    print(
        f"{i.get('port_status'):12} {i.get('temp_debt')} {(i.get('id') or '')[:55]:55} {(i.get('project_path') or '')[:45]}"
    )
print("\n=== open P2 non-external top 40 by id ===")
non_ext = [i for i in p2 if i.get("area") != "external" and "external/" not in (i.get("project_path") or "")]
for i in sorted(non_ext, key=lambda x: x.get("id") or "")[:40]:
    print(
        f"{i.get('port_status'):12} {(i.get('related_group') or '-'):12} {(i.get('id') or '')[:50]:50} {(i.get('project_path') or '')[:40]}"
    )
print("\n=== blocked ===")
for i in items:
    if i.get("port_status") == "blocked":
        print(i.get("id"), "|", (i.get("notes") or "")[:80])
