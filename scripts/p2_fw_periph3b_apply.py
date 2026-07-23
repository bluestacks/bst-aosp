#!/usr/bin/env python3
# P2-FW-PERIPH-3b: TelephonyManager device-id/software-version spoof (anti-detection).
# getDeviceId() + getDeviceSoftwareVersion(int) early-return "01" when BST_TELEPHONY_CHANGES_ENABLED
# (field added in PERIPH-3). Adapted from a13 (a16 restructured these to telephony.*ForSlot/getDeviceIdWithFeature;
# early-return achieves the same anti-detection effect). App-framework, query-time. Robust exact-string replace.
import os, sys
A16 = os.path.expanduser("~/aosp16/frameworks/base")
ERRS = []

def patch(rel, replacements, label):
    full = os.path.join(A16, rel)
    with open(full) as f: src = f.read()
    orig = src
    for old, new in replacements:
        if old not in src:
            ERRS.append(f"{label}: ANCHOR NOT FOUND: {old.strip()[:70]!r}"); return
        if src.count(old) > 1:
            ERRS.append(f"{label}: ANCHOR NOT UNIQUE ({src.count(old)}): {old.strip()[:70]!r}"); return
        src = src.replace(old, new, 1)
    if src == orig:
        ERRS.append(f"{label}: no change"); return
    with open(full, "w") as f: f.write(src)
    print(f"OK   {label}")

patch("telephony/java/android/telephony/TelephonyManager.java", [
    # getDeviceId() -> "01"
    ("    public String getDeviceId() {\n        try {\n",
     "    public String getDeviceId() {\n"
     "        // A16DBG:P2:FW-PERIPH-3b BST spoof device id (anti-detection, a13)\n"
     "        if (BST_TELEPHONY_CHANGES_ENABLED) return \"01\";\n"
     "        try {\n"),
    # getDeviceSoftwareVersion(int) -> "01"
    ("    public String getDeviceSoftwareVersion(int slotIndex) {\n        ITelephony telephony = getITelephony();\n",
     "    public String getDeviceSoftwareVersion(int slotIndex) {\n"
     "        // A16DBG:P2:FW-PERIPH-3b BST spoof software version (anti-detection, a13)\n"
     "        if (BST_TELEPHONY_CHANGES_ENABLED) return \"01\";\n"
     "        ITelephony telephony = getITelephony();\n"),
], "TelephonyManager device-id/software-version spoof")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
