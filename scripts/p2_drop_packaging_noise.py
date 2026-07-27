#!/usr/bin/env python3
"""Mark packaging-noise / cts-optional / typo external entries as dropped in registry."""
import json
from pathlib import Path

reg_path = Path(r"c:\workspace\bst-aosp\patches\registry.json")
intent_path = Path(r"c:\workspace\bst-aosp\patches\android-16\patches\p2-inventory\external_intent.tsv")

# Prefer remote-synced intent if present locally after scp; else embed from known results
intents = {}
if intent_path.exists():
    for line in intent_path.read_text(encoding="utf-8").splitlines()[1:]:
        parts = line.split("\t")
        if len(parts) >= 3:
            intents[parts[0]] = parts[2]

d = json.loads(reg_path.read_text(encoding="utf-8"))
changed = 0
for p in d["patches"]:
    if p.get("phase") != "P2" or p.get("port_status") != "pending":
        continue
    if p.get("platform") != "win":
        continue
    intent = intents.get(p["id"])
    if intent in ("packaging-noise", "cts-optional") or p["id"] == "win-external-robolectric":
        p["port_status"] = "dropped"
        p["verification"] = (
            "P2 triage 2026-07-20: a13 fork delta is packaging-noise "
            "(.github removal / deinit / LFS / CTS submodule) — not applicable to a16 product tree."
        )
        p["checkpoint_ref"] = "patches/android-16/patches/p2-inventory/external_intent.tsv"
        changed += 1
    elif intent == "selinux-temp":
        p["temp_debt"] = True
        p["verification"] = "escalate with P2-TEMP-SEPOLICY (a13 Disabling selinux)"
        # keep pending
        changed += 1

reg_path.write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(f"updated {changed} entries")
# recount
pend = [x for x in d["patches"] if x.get("port_status") == "pending" and x.get("phase") == "P2"]
print("P2 pending now", len(pend))
from collections import Counter
print(Counter(x.get("area") for x in pend))
print(Counter(x.get("platform") for x in pend))
