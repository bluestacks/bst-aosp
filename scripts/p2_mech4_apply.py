#!/usr/bin/env python3
# P2-MECH-4: start.cpp BST state reset on service stop (system/core/toolbox, a13->a16).
# When stopping default services, also stop appstatsd + reset BST config properties (shutdown cleanup).
# Low-risk toolbox command. Robust exact-string replace.
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

patch("system/core/toolbox/start.cpp", [
    ("        for (auto it = services.crbegin(); it != services.crend(); ++it) {\n"
     "            ControlService(false, *it);\n"
     "        }\n"
     "    }\n",
     "        for (auto it = services.crbegin(); it != services.crend(); ++it) {\n"
     "            ControlService(false, *it);\n"
     "        }\n"
     "        // A16DBG:P2:MECH BST: reset state on stop (a13)\n"
     "        android::base::SetProperty(\"ctl.stop\", \"appstatsd\");\n"
     "        android::base::SetProperty(\"bst.config.boot_completed\", \"0\");\n"
     "        android::base::SetProperty(\"bst.config.pm_ready\", \"0\");\n"
     "        android::base::SetProperty(\"bst.config.screen_enabled\", \"0\");\n"
     "        android::base::SetProperty(\"bst.config.top_package_name\", \"\");\n"
     "        android::base::SetProperty(\"bst.config.top_activity_name\", \"\");\n"
     "    }\n"),
], "start.cpp BST state reset on stop")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
