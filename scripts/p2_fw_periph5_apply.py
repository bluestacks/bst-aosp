#!/usr/bin/env python3
# P2-FW-PERIPH-5: TelephonyManager device-id/software-version spoof — CONDITIONAL (uid-gated).
# Redo of PERIPH-3b which broke boot (unconditional). Gate: only spoof for 3rd-party callers
# (Binder.getCallingUid() >= 10000); system_server (uid<10000) gets real id -> boot-safe.
# Anti-detection: 3rd-party apps see device id "01". telephony/java, query-time.
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
    # getDeviceId() -> "01" for 3rd-party only (uid >= 10000)
    ("    public String getDeviceId() {\n        try {\n",
     "    public String getDeviceId() {\n"
     "        // A16DBG:P2:FW-PERIPH-5 BST spoof device id for 3rd-party only (anti-detection, a13;\n"
     "        //  uid-gated so system_server boot path gets real id — PERIPH-3b lesson)\n"
     "        if (BST_TELEPHONY_CHANGES_ENABLED && Binder.getCallingUid() >= 10000) return \"01\";\n"
     "        try {\n"),
    # getDeviceSoftwareVersion(int) -> "01" for 3rd-party only
    ("    public String getDeviceSoftwareVersion(int slotIndex) {\n        ITelephony telephony = getITelephony();\n",
     "    public String getDeviceSoftwareVersion(int slotIndex) {\n"
     "        // A16DBG:P2:FW-PERIPH-5 BST spoof software version for 3rd-party only (a13; uid-gated)\n"
     "        if (BST_TELEPHONY_CHANGES_ENABLED && Binder.getCallingUid() >= 10000) return \"01\";\n"
     "        ITelephony telephony = getITelephony();\n"),
], "TelephonyManager device-id spoof (uid-gated)")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
