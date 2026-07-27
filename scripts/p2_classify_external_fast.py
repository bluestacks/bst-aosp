#!/usr/bin/env python3
import json, subprocess
from collections import Counter
from pathlib import Path

a13 = Path.home() / "app-player/android-13"
d = json.loads((Path.home() / "bst-aosp/patches/registry.json").read_text())
projects = [
    i["project_path"]
    for i in d["patches"]
    if i.get("phase") == "P2"
    and i.get("port_status") == "pending"
    and i.get("platform") == "win"
    and (i.get("project_path") or "").startswith("external/")
]
out = Path.home() / "bst-aosp/patches/android-16/patches/p2-inventory/delta_classification_ext.tsv"
out.parent.mkdir(parents=True, exist_ok=True)
lines = ["project\tcommits\tclass"]
print("projects=%d" % len(projects), flush=True)

for rel in projects:
    directory = a13 / rel
    if not directory.is_dir():
        lines.append("%s\t-1\tmissing" % rel)
        print("MISSING", rel, flush=True)
        continue
    try:
        tag = subprocess.check_output(
            ["git", "tag", "--list", "android-13.0.0_r*", "--sort=version:refname"],
            cwd=str(directory),
            text=True,
            timeout=20,
            stderr=subprocess.DEVNULL,
        ).strip().splitlines()
        tag = tag[-1] if tag else ""
        if not tag:
            lines.append("%s\t-1\tnotag" % rel)
            print("NOTAG", rel, flush=True)
            continue
        commits = int(
            subprocess.check_output(
                ["git", "rev-list", "--count", "%s..HEAD" % tag],
                cwd=str(directory),
                text=True,
                timeout=30,
                stderr=subprocess.DEVNULL,
            ).strip()
        )
        cls = "empty" if commits == 0 else ("trivial" if commits <= 2 else ("large" if commits > 50 else "real"))
        lines.append("%s\t%d\t%s" % (rel, commits, cls))
        print("CLASS", rel, "commits=%d" % commits, "=>", cls, flush=True)
    except subprocess.TimeoutExpired:
        lines.append("%s\t-1\ttimeout" % rel)
        print("TIMEOUT", rel, flush=True)
    except Exception as e:
        lines.append("%s\t-1\terror" % rel)
        print("ERR", rel, str(e)[:80], flush=True)

out.write_text("\n".join(lines) + "\n")
print(dict(Counter(l.split("\t")[2] for l in lines[1:])), flush=True)
print("wrote", out, flush=True)
