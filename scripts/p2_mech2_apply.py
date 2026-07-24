#!/usr/bin/env python3
# P2-MECH-2: Launcher3 AndroidManifest — remove HOME category (a13->a16).
# Use a13's single multi-line comment block (manifest_merger rejects inline/double comments w/ '--').
import os, sys
A16 = os.path.expanduser("~/aosp16")
ERRS = []
def patch(rel, replacements, label):
    full = os.path.join(A16, rel)
    with open(full) as f: src = f.read()
    orig = src
    for old, new in replacements:
        if old not in src: ERRS.append(f"{label}: ANCHOR NOT FOUND: {old.strip()[:70]!r}"); return
        if src.count(old) > 1: ERRS.append(f"{label}: ANCHOR NOT UNIQUE ({src.count(old)}): {old.strip()[:70]!r}"); return
        src = src.replace(old, new, 1)
    if src == orig: ERRS.append(f"{label}: no change"); return
    with open(full, "w") as f: f.write(src)
    print(f"OK   {label}")
HOME_OLD = '                <category android:name="android.intent.category.HOME" />\n'
HOME_NEW = ''  # remove HOME category line (no comment -> no manifest_merger parse issue)
            '                <category android:name="android.intent.category.HOME" />\n'
            '                -->\n')
patch("packages/apps/Launcher3/AndroidManifest.xml", [(HOME_OLD, HOME_NEW)], "Launcher3 AndroidManifest HOME removal")
patch("packages/apps/Launcher3/quickstep/AndroidManifest-launcher.xml", [(HOME_OLD, HOME_NEW)], "Launcher3 quickstep HOME removal")
if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK")
