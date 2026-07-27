#!/usr/bin/env python3
# P2-FW-PERIPH-8: SubscriptionManager fake-SIM (anti-detection, uid-gated 3rd-party).
# BST return at METHOD END (replaces final return) so the iSub permission check + @RequiresPermission
# annotation are preserved (earlier attempt put it at method start -> metalava dropped @RequiresPermission
# -> check_current_api fail). a13 createSubInfoInstance relocated to SubscriptionManager.
import os, sys
A16 = os.path.expanduser("~/aosp16/frameworks/base")
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
HELPER = '''
    // A16DBG:P2:FW-PERIPH-8 BST fake-SIM for anti-detection (a13 createSubInfoInstance relocated;
    // uid-gated 3rd-party only -> boot-safe). operator props consistent with PERIPH-3.
    private SubscriptionInfo createBstSubscriptionInfo() {
        String iccId = null;
        try { iccId = BstUtils.getBstSimSerialNumber(); } catch (Exception ex) { iccId = null; }
        String operatorAlpha = android.os.SystemProperties.get("gsm.operator.alpha", "T-Mobile");
        String operatorNumeric = android.os.SystemProperties.get("gsm.operator.numeric", "310260");
        String mcc = operatorNumeric.length() >= 3 ? operatorNumeric.substring(0, 3) : "310";
        String mnc = operatorNumeric.length() > 3 ? operatorNumeric.substring(3) : "260";
        android.graphics.Bitmap icon = android.graphics.BitmapFactory.decodeResource(
                mContext.getResources(), com.android.internal.R.drawable.ic_sim_card_multi_24px_clr);
        return new SubscriptionInfo(
                1, iccId, 0, "SIM 1", operatorAlpha,
                0, -16777216, null, 0, icon, mcc, mnc, "us",
                false, null, null, 0, false, null, false,
                0, 0, 0, null, null, true);
    }
'''
patch("telephony/java/android/telephony/SubscriptionManager.java", [
    ("import android.os.Binder;\n",
     "import android.os.Binder;\nimport android.os.SystemProperties;\n"
     "import android.graphics.Bitmap;\nimport android.graphics.BitmapFactory;\n"
     "import android.util.BstUtils;\n"),
    # helper before getActiveSubscriptionInfoList
    ("    public @Nullable List<SubscriptionInfo> getActiveSubscriptionInfoList() {\n",
     HELPER + "    public @Nullable List<SubscriptionInfo> getActiveSubscriptionInfoList() {\n"),
    # BST fake-SIM return at END (replaces final return) so @RequiresPermission is preserved
    ("        if (activeList != null) {\n            activeList = activeList.stream().filter(subInfo -> isSubscriptionVisible(subInfo))\n                    .collect(Collectors.toList());\n        } else {\n            activeList = Collections.emptyList();\n        }\n        return activeList;\n",
     "        if (activeList != null) {\n            activeList = activeList.stream().filter(subInfo -> isSubscriptionVisible(subInfo))\n                    .collect(Collectors.toList());\n        } else {\n            activeList = Collections.emptyList();\n        }\n"
     "        // A16DBG:P2:FW-PERIPH-8 BST fake-SIM for 3rd-party callers (anti-detection, a13)\n"
     "        if (Binder.getCallingUid() >= android.os.Process.FIRST_APPLICATION_UID) {\n"
     "            return Collections.singletonList(createBstSubscriptionInfo());\n"
     "        }\n"
     "        return activeList;\n"),
], "SubscriptionManager fake-SIM (uid-gated, end-return)")
if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
