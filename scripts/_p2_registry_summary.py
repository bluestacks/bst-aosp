import json
r = json.load(open(r"c:\workspace\bst-aosp\patches\registry.json", encoding="utf-8"))
for i in r["patches"]:
    if i.get("phase") != "P2":
        continue
    st = i.get("port_status")
    if st in ("ported", "blocked", "boot-archived", "pending", "in-progress", "partial"):
        print(f"{st:14} {i['id']:42} {i.get('project_path','')}")
print("--- P1 pending (may still need work) ---")
for i in r["patches"]:
    if i.get("phase") == "P1" and i.get("port_status") == "pending":
        print(f"P1/pending    {i['id']:42} {i.get('project_path','')}")
