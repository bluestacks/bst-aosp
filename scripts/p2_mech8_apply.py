#!/usr/bin/env python3
# P2-MECH-8: Settings BST_CHANGES_ENABLED gate (a13->a16).
# When BST_CHANGES_ENABLED (default on via bst.config.modify_settings), skip actionBar customization
# (BST has its own Settings UI behavior). packages/apps/Settings, low boot risk. Robust replace.
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

patch("packages/apps/Settings/src/com/android/settings/SettingsActivity.java", [
    # add BST_CHANGES_ENABLED field before setActionBarStatus
    ("    private void setActionBarStatus() {\n",
     "    // A16DBG:P2:MECH BST settings gate (a13)\n"
     "    private static final boolean BST_CHANGES_ENABLED =\n"
     "            (android.os.SystemProperties.getInt(\"bst.config.modify_settings\", 1) > 0);\n\n"
     "    private void setActionBarStatus() {\n"),
    # wrap actionBar block in if (!BST_CHANGES_ENABLED)
    ("        final ActionBar actionBar = getActionBar();\n"
     "        if (actionBar != null) {\n"
     "            actionBar.setDisplayHomeAsUpEnabled(isActionBarButtonEnabled);\n"
     "            actionBar.setHomeButtonEnabled(isActionBarButtonEnabled);\n",
     "        // A16DBG:P2:MECH BST: skip actionBar customization when BST enabled (a13)\n"
     "        if (!BST_CHANGES_ENABLED) {\n"
     "        final ActionBar actionBar = getActionBar();\n"
     "        if (actionBar != null) {\n"
     "            actionBar.setDisplayHomeAsUpEnabled(isActionBarButtonEnabled);\n"
     "            actionBar.setHomeButtonEnabled(isActionBarButtonEnabled);\n"),
    # add closing brace for the if (!BST_CHANGES_ENABLED)
    ("            actionBar.setDisplayShowTitleEnabled(true);\n        }\n    }\n",
     "            actionBar.setDisplayShowTitleEnabled(true);\n        }\n        } // end BST_CHANGES_ENABLED gate\n    }\n"),
], "Settings BST_CHANGES_ENABLED gate")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
