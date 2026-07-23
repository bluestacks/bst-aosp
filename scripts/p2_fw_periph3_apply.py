#!/usr/bin/env python3
# P2-FW-PERIPH-3: TelephonyManager operator spoof (anti-detection, bounded subset of a13).
# getNetworkOperatorName -> SystemProperties(gsm.operator.alpha,"T-Mobile");
# getNetworkOperator -> SystemProperties(gsm.operator.numeric,"310260").
# Bounded subset of a13's 18-hunk TM port (anti-emulator-detection). a16 anchors match a13 verbatim.
# App-framework (telephony), low boot risk (query-time). Robust exact-string replace.
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
    # fields after class declaration
    ("public class TelephonyManager {\n",
     "public class TelephonyManager {\n"
     "    // A16DBG:P2:FW-PERIPH-3 BST operator spoof (anti-emulator-detection, a13)\n"
     "    private static final boolean BST_TELEPHONY_CHANGES_ENABLED = true;\n"
     "    private static final String PROPERTY_OPERATOR_ALPHA = \"gsm.operator.alpha\";\n"
     "    private static final String PROPERTY_OPERATOR_NUMERIC = \"gsm.operator.numeric\";\n"),
    # getNetworkOperatorName -> T-Mobile
    ("""    public String getNetworkOperatorName() {
        return getNetworkOperatorName(getSubId());
    }
""",
     """    public String getNetworkOperatorName() {
        // A16DBG:P2:FW-PERIPH-3 BST spoof operator name (a13)
        if (!BST_TELEPHONY_CHANGES_ENABLED) {
            return getNetworkOperatorName(getSubId());
        } else {
            return SystemProperties.get(PROPERTY_OPERATOR_ALPHA, "T-Mobile");
        }
    }
"""),
    # getNetworkOperator -> 310260
    ("""    public String getNetworkOperator() {
        return getNetworkOperatorForPhone(getPhoneId());
    }
""",
     """    public String getNetworkOperator() {
        // A16DBG:P2:FW-PERIPH-3 BST spoof operator numeric (a13)
        if (!BST_TELEPHONY_CHANGES_ENABLED) {
            return getNetworkOperatorForPhone(getPhoneId());
        } else {
            return SystemProperties.get(PROPERTY_OPERATOR_NUMERIC, "310260");
        }
    }
"""),
], "TelephonyManager operator spoof")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
