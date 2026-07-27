import json
from collections import Counter

d = json.load(open(r"c:\workspace\bst-aosp\patches\registry.json", encoding="utf-8"))
pend = [i for i in d["patches"] if i.get("port_status") == "pending" and i.get("phase") == "P2"]
print("P2 pending", len(pend))
print("platform", Counter(i.get("platform") for i in pend))
win = [i for i in pend if i.get("platform") in ("win", "both")]
mac = [i for i in pend if i.get("platform") == "mac"]
print("win/both", len(win), "mac-only", len(mac))
print("win areas", Counter(i.get("area") for i in win))
print("mac areas", Counter(i.get("area") for i in mac))
print("--- win/both projects ---")
for i in sorted(win, key=lambda x: x.get("project_path") or ""):
    print(f"{i['id']:45} {i.get('project_path')}  rg={i.get('related_group')}")
print("--- mac-only non-external sample ---")
for i in mac:
    if i.get("area") != "external":
        print(f"{i['id']:45} {i.get('project_path')}")
