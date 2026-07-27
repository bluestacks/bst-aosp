#!/usr/bin/env python3
"""Drop win P2 external packaging-noise; keep functional/selinux."""
import json
from collections import Counter
from pathlib import Path

KEEP = {
    "win-external-boringssl",  # DRM/boot SSL functional
    "win-external-icu",  # ROB-14898 Iran TZ
    "win-external-selinux",  # escalate with sepolicy
}

reg_path = Path(r"c:\workspace\bst-aosp\patches\registry.json")
d = json.loads(reg_path.read_text(encoding="utf-8"))
changed = 0
for p in d["patches"]:
    if p.get("phase") != "P2" or p.get("port_status") != "pending":
        continue
    if p.get("platform") != "win":
        continue
    if not (p.get("project_path") or "").startswith("external/"):
        continue
    pid = p["id"]
    if pid in KEEP:
        if pid == "win-external-selinux":
            p["temp_debt"] = True
            p["verification"] = (
                "P2 triage: a13 has Disabling selinux — escalate with P2-TEMP-SEPOLICY"
            )
            changed += 1
        continue
    p["port_status"] = "dropped"
    p["verification"] = (
        "P2 triage 2026-07-20: a13 fork delta is packaging-noise "
        "(.github removal / deinit / LFS / CTS) — N/A for a16 product. "
        "See patches/android-16/patches/p2-inventory/external_intent.tsv"
    )
    p["checkpoint_ref"] = "patches/android-16/patches/p2-inventory/external_intent.tsv"
    changed += 1

reg_path.write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
pend = [x for x in d["patches"] if x.get("port_status") == "pending" and x.get("phase") == "P2"]
print(f"dropped/updated touching {changed}")
print("P2 pending", len(pend), Counter(x.get("platform") for x in pend), Counter(x.get("area") for x in pend))
print("remaining win:")
for x in pend:
    if x.get("platform") == "win":
        print(" ", x["id"], x.get("project_path"))
