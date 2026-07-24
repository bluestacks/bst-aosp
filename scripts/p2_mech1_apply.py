#!/usr/bin/env python3
# P2-MECH-1: small mechanical ports outside frameworks/base (a13->a16).
# 1. hardware/interfaces audio service.cpp: comment out ABinderProcess_setThreadPoolMaxThreadCount(1)
#    (BST audio service: no threadpool limit). Low-risk HAL tweak.
# 2. system/core healthd/BatteryMonitor.cpp: gate dmesg KLOG_WARNING (if false) + klog_set_level(3).
#    Low-risk healthd logging tweak. Robust exact-string replace.
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

patch("hardware/interfaces/audio/common/all-versions/default/service/service.cpp", [
    ("    ABinderProcess_setThreadPoolMaxThreadCount(1);\n",
     "    //ABinderProcess_setThreadPoolMaxThreadCount(1);  // A16DBG:P2:MECH BST audio: no threadpool limit (a13)\n"),
], "audio service.cpp threadpool")

patch("system/core/healthd/BatteryMonitor.cpp", [
    ('''    KLOG_WARNING(LOG_TAG, "%s\\n", dmesgline);
''',
     '''    // A16DBG:P2:MECH BST: gate dmesg spam + set klog level (a13)
    if (false)
        KLOG_WARNING(LOG_TAG, "%s\\n", dmesgline);
    klog_set_level(3);
'''),
], "BatteryMonitor klog gate")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
