#!/bin/bash
# Classify a13 frameworks/base & native deltas vs a16 for surgical P2 ports.
set -euo pipefail
LOG=~/p2_fw_classify.log
OUT=~/bst-aosp/patches/android-16/patches/p2-fw-classify
mkdir -p "$OUT"
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:fw classify start $(date -Is)"

A13B=~/app-player/android-13/frameworks/base
A16B=~/aosp16/frameworks/base
A13N=~/app-player/android-13/frameworks/native
A16N=~/aosp16/frameworks/native

# --- base: list a13 changed files ---
(cd "$A13B" && git diff --name-only android-13.0.0_r49..HEAD) > "$OUT/a13_base_files.txt"
echo "a13 base files: $(wc -l < "$OUT/a13_base_files.txt")"

# Categorize by path prefix
python3 - <<'PY'
from pathlib import Path
from collections import Counter, defaultdict
out = Path.home()/"bst-aosp/patches/android-16/patches/p2-fw-classify"
files = (out/"a13_base_files.txt").read_text().splitlines()
a16 = Path.home()/"aosp16/frameworks/base"
cats = defaultdict(list)
for f in files:
    if f.startswith("services/core/java/com/android/server/wm/"):
        cats["wm"].append(f)
    elif f.startswith("services/core/java/com/android/server/am/"):
        cats["am"].append(f)
    elif f.startswith("services/core/java/com/android/server/pm/"):
        cats["pm"].append(f)
    elif f.startswith("services/core/java/com/android/server/"):
        cats["services_other"].append(f)
    elif f.startswith("core/java/com/bluestacks/") or f.startswith("services/java/com/bluestacks/"):
        cats["bst_api"].append(f)
    elif f.startswith("core/java/android/"):
        cats["android_api"].append(f)
    elif f.startswith("cmds/"):
        cats["cmds"].append(f)
    elif f.startswith("packages/"):
        cats["packages"].append(f)
    elif "Android.bp" in f or "Android.mk" in f or f.endswith(".xml"):
        cats["build_xml"].append(f)
    else:
        cats["other"].append(f)

# existence on a16
lines = []
for cat, fl in sorted(cats.items()):
    exist = sum(1 for f in fl if (a16/f).exists())
    miss = [f for f in fl if not (a16/f).exists()]
    lines.append(f"## {cat}: {len(fl)} files ({exist} exist on a16, {len(miss)} missing)")
    for f in fl[:30]:
        mark = "EXISTS" if (a16/f).exists() else "MISS"
        lines.append(f"  {mark} {f}")
    if len(fl) > 30:
        lines.append(f"  ... +{len(fl)-30} more")
    if miss:
        lines.append("  missing sample:")
        for f in miss[:15]:
            lines.append(f"    {f}")
(out/"base_categories.md").write_text("\n".join(lines)+"\n")
print("\n".join(lines[:80]))
print(f"... wrote {out/'base_categories.md'}")

# Diffstat size for EXISTS files in wm/am/bst_api/android_api/cmds
A13 = Path.home()/"app-player/android-13/frameworks/base"
import subprocess
for cat in ["wm", "am", "bst_api", "android_api", "cmds"]:
    sizes = []
    for f in cats[cat]:
        if not (a16/f).exists():
            continue
        r = subprocess.run(
            ["git", "-C", str(A13), "diff", "--numstat", "android-13.0.0_r49..HEAD", "--", f],
            capture_output=True, text=True,
        )
        for line in r.stdout.splitlines():
            parts = line.split("\t")
            if len(parts) >= 3 and parts[0].isdigit():
                sizes.append((int(parts[0])+int(parts[1]), f, int(parts[0]), int(parts[1])))
    sizes.sort(reverse=True)
    print(f"\n=== top diffs {cat} ===")
    for total, f, a, d in sizes[:12]:
        print(f"  +{a}/-{d} ({total}) {f}")
PY

# --- native ---
(cd "$A13N" && git diff --name-only android-13.0.0_r49..HEAD) > "$OUT/a13_native_files.txt"
echo "a13 native files: $(wc -l < "$OUT/a13_native_files.txt")"
python3 - <<'PY'
from pathlib import Path
out = Path.home()/"bst-aosp/patches/android-16/patches/p2-fw-classify"
a16 = Path.home()/"aosp16/frameworks/native"
files = (out/"a13_native_files.txt").read_text().splitlines()
for f in files:
    mark = "EXISTS" if (a16/f).exists() else "MISS"
    print(f"{mark} {f}")
PY

# What's already on a16 for BST services (G5 subset)?
echo "=== a16 BST hostcall already present? ==="
rg -n "bstNotifyActivityDisplayed|onActivityDisplayed|BST_HOST_CALL|mBstHostCall" \
  ~/aosp16/frameworks/base/services/core/java/com/android/server/wm/WindowManagerService.java 2>/dev/null | head -20 || true
rg -n "pagefusion|Features|Sdk23|class BstUtils" ~/aosp16/frameworks/base --glob "*.java" 2>/dev/null | head -20 || true

echo "A16DBG:P2:fw classify DONE $(date -Is)"
