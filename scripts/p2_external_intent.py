#!/usr/bin/env python3
"""Classify external BST commits by message intent."""
import json
import subprocess
from collections import Counter, defaultdict
from pathlib import Path

a13 = Path.home() / "app-player/android-13"
d = json.loads((Path.home() / "bst-aosp/patches/registry.json").read_text())
projects = [
    (i["id"], i["project_path"])
    for i in d["patches"]
    if i.get("phase") == "P2"
    and i.get("port_status") == "pending"
    and i.get("platform") == "win"
    and (i.get("project_path") or "").startswith("external/")
]

out = Path.home() / "bst-aosp/patches/android-16/patches/p2-inventory/external_intent.tsv"
lines = ["id\tproject\tintent\tcommits\tsummary"]
intents = Counter()

for pid, rel in projects:
    directory = a13 / rel
    intent = "missing"
    summary = ""
    n = 0
    try:
        tags = subprocess.check_output(
            ["git", "tag", "--list", "android-13.0.0_r*", "--sort=version:refname"],
            cwd=str(directory), text=True, timeout=20, stderr=subprocess.DEVNULL,
        ).strip().splitlines()
        tag = tags[-1] if tags else ""
        if not tag:
            intent = "notag"
        else:
            log = subprocess.check_output(
                ["git", "log", "--oneline", f"{tag}..HEAD"],
                cwd=str(directory), text=True, timeout=30, stderr=subprocess.DEVNULL,
            ).strip()
            n = len(log.splitlines()) if log else 0
            summary = log.replace("\t", " ")[:180]
            low = log.lower()
            if n == 0:
                intent = "empty"
            elif all(
                ("removing .github" in ln.lower() or "deinit" in ln.lower() or "using lfs" in ln.lower() or "remove some large" in ln.lower() or "sync to aosp" in ln.lower())
                for ln in log.splitlines()
            ):
                intent = "packaging-noise"
            elif "disabling selinux" in low or "selinux" in low and "disabl" in low:
                intent = "selinux-temp"
            elif any(k in low for k in ("widevine", "drm", "boot time", "ssl test", "rob-")):
                intent = "functional"
            elif "cts" in low or "deqp" in low or "vulkancts" in low:
                intent = "cts-optional"
            else:
                intent = "review"
    except Exception as e:
        intent = "error"
        summary = str(e)[:80]
    intents[intent] += 1
    lines.append(f"{pid}\t{rel}\t{intent}\t{n}\t{summary}")
    print(f"{intent:16} {rel} n={n}", flush=True)

out.write_text("\n".join(lines) + "\n")
print(dict(intents), flush=True)
print("wrote", out, flush=True)
