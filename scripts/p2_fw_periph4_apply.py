#!/usr/bin/env python3
# P2-FW-PERIPH-4: ServiceState getDataNetworkType -> LTE (anti-detection, a13->a16).
# Gated by bst.config.modify_nwtype (default 1=on). Reports LTE network type.
# telephony/java, query-time, low boot risk. Robust exact-string replace.
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

patch("telephony/java/android/telephony/ServiceState.java", [
    ("    private boolean mIsIwlanPreferred;\n",
     "    private boolean mIsIwlanPreferred;\n"
     "    // A16DBG:P2:FW-PERIPH-4 BST report LTE network type (anti-detection, a13; gated)\n"
     "    private static boolean BST_CHANGES_ENABLED =\n"
     "            (android.os.SystemProperties.getInt(\"bst.config.modify_nwtype\", 1) > 0);\n"),
    ("    public @NetworkType int getDataNetworkType() {\n"
     "        final NetworkRegistrationInfo iwlanRegInfo = getNetworkRegistrationInfo(\n"
     "                NetworkRegistrationInfo.DOMAIN_PS, AccessNetworkConstants.TRANSPORT_TYPE_WLAN);\n",
     "    public @NetworkType int getDataNetworkType() {\n"
     "        // A16DBG:P2:FW-PERIPH-4 BST report LTE (anti-detection, a13)\n"
     "        if (BST_CHANGES_ENABLED) {\n"
     "            return TelephonyManager.NETWORK_TYPE_LTE;\n"
     "        }\n"
     "        final NetworkRegistrationInfo iwlanRegInfo = getNetworkRegistrationInfo(\n"
     "                NetworkRegistrationInfo.DOMAIN_PS, AccessNetworkConstants.TRANSPORT_TYPE_WLAN);\n"),
], "ServiceState getDataNetworkType -> LTE")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
