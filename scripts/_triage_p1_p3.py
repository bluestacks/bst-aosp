#!/usr/bin/env python3
"""Triage P1 leftover + P3 prebuilts per Phase2 human decisions."""
import json
from pathlib import Path
p = Path(r"c:\workspace\bst-aosp\patches\registry.json")
r = json.loads(p.read_text(encoding="utf-8"))
items = r["patches"]
changed = []
for i in items:
    pid = i.get("id") or ""
    # P3 prebuilts: Phase3 deferred by human — explicit drop
    if i.get("phase") == "P3" and i.get("port_status") == "pending" and "prebuilts" in (i.get("project_path") or ""):
        i["port_status"] = "dropped"
        i["notes"] = ((i.get("notes") or "") + " | 2026-07-21: Phase3/host deferred by human decision; explicit drop from Phase2 gate.").strip(" |")
        i["verification"] = "dropped: Phase3 not in scope (human 2026-07-21)"
        changed.append(pid)
    # Move functional P1 leftovers into Phase2 tracking (keep pending, retarget phase)
    if i.get("phase") == "P1" and i.get("port_status") == "pending" and i.get("platform") == "win":
        if i.get("related_group") in ("G6", "G7", "G8", "G9") or pid.startswith("win-hardware-bst") or pid in (
            "win-packages-apps-Launcher3", "win-system-core", "win-build-make", "win-build-soong",
            "win-hardware-interfaces", "win-hardware-libhardware",
        ):
            i["phase"] = "P2"
            i["notes"] = ((i.get("notes") or "") + " | 2026-07-21: rolled into Phase2 functional alignment queue (was P1 leftover pending).").strip(" |")
            changed.append(pid + "->P2")
p.write_text(json.dumps(r, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print("changed", len(changed))
for c in changed:
    print(" ", c)
