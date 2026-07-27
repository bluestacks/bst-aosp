#!/usr/bin/env python3
"""Classify win P2 external projects — name-only diffs, with timeout."""
import json
import subprocess
from collections import Counter
from pathlib import Path

a13 = Path.home() / "app-player/android-13"
reg = Path.home() / "bst-aosp/patches/registry.json"
d = json.loads(reg.read_text())
projects = [
    i["project_path"]
    for i in d.get("patches", [])
    if i.get("phase") == "P2"
    and i.get("port_status") == "pending"
    and i.get("platform") == "win"
    and (i.get("project_path") or "").startswith("external/")
]

out = Path.home() / "bst-aosp/patches/android-16/patches/p2-inventory/delta_classification_ext.tsv"
out.parent.mkdir(parents=True, exist_ok=True)
lines = ["project\tfiles\tclass\tnote"]
print(f"projects={len(projects)}", flush=True)


def run(cmd, timeout=60):
    return subprocess.check_output(cmd, text=True, timeout=timeout, stderr=subprocess.DEVNULL)


for rel in projects:
    directory = a13 / rel
    if not directory.exists():
        lines.append(f"{rel}\t-1\tmissing\t")
        print(f"MISSING {rel}", flush=True)
        continue
    try:
        tag = run(
            ["bash", "-lc", f"cd '{directory}' && git tag --list 'android-13.0.0_r*' --sort=version:refname | tail -1"],
            timeout=30,
        ).strip()
        if not tag:
            lines.append(f"{rel}\t-1\tnotag\t")
            print(f"NOTAG {rel}", flush=True)
            continue
        files = int(
            run(
                ["bash", "-lc", f"cd '{directory}' && git diff --name-only {tag}..HEAD | wc -l"],
                timeout=120,
            ).strip()
        )
        note = ""
        if files > 0 and files <= 15:
            names = run(
                ["bash", "-lc", f"cd '{directory}' && git diff --name-only {tag}..HEAD | head -15"],
                timeout=60,
            ).strip().replace("\n", ",")
            note = names[:200]
        cls = "real"
        if files == 0:
            cls = "empty"
        elif files <= 3:
            cls = "trivial"
        elif files > 100:
            cls = "large"
        lines.append(f"{rel}\t{files}\t{cls}\t{note}")
        print(f"CLASS {rel} files={files} => {cls}", flush=True)
    except subprocess.TimeoutExpired:
        lines.append(f"{rel}\t-1\ttimeout\t")
        print(f"TIMEOUT {rel}", flush=True)
    except Exception as e:
        lines.append(f"{rel}\t-1\terror\t{e}")
        print(f"ERR {rel} {e}", flush=True)

out.write_text("\n".join(lines) + "\n")
print(Counter(l.split("\t")[2] for l in lines[1:]), flush=True)
print("wrote", out, flush=True)
