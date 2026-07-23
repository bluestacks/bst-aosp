#!/usr/bin/env python3
# P2-FW-PERIPH-2: TelephonyPermissions — bypass READ_PRIVILEGED_PHONE_STATE for specific apps (a13->a16).
# hook1: com.gamamobi.wog bypass in checkReadPhoneState(7-arg).
# hook2: com.bluestacks.devicedetails bypass before LegacyPermissionManager device-id check.
# telephony/common, system_server-side permission gate, low boot risk (query-time). Robust exact-string replace.
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

patch("telephony/common/com/android/internal/telephony/TelephonyPermissions.java", [
    # hook1: 7-arg checkReadPhoneState -> wog bypass after try {
    ("""            @Nullable  String callingFeatureId, String message) {
        try {
            context.enforcePermission(
                    android.Manifest.permission.READ_PRIVILEGED_PHONE_STATE, pid, uid, message);
""",
     """            @Nullable  String callingFeatureId, String message) {
        try {
            // A16DBG:P2:FW-PERIPH BST bypass READ_PRIVILEGED_PHONE_STATE for com.gamamobi.wog (a13)
            if(callingPackage.equals("com.gamamobi.wog"))
                return true;
            context.enforcePermission(
                    android.Manifest.permission.READ_PRIVILEGED_PHONE_STATE, pid, uid, message);
"""),
    # hook2: devicedetails bypass before LegacyPermissionManager device-id check
    ("""        if (allowCarrierPrivilegeOnAnySub && checkCarrierPrivilegeForAnySubId(context, uid)) {
            return true;
        }

        LegacyPermissionManager permissionManager = (LegacyPermissionManager)
""",
     """        if (allowCarrierPrivilegeOnAnySub && checkCarrierPrivilegeForAnySubId(context, uid)) {
            return true;
        }

        // A16DBG:P2:FW-PERIPH BST bypass device-id check for com.bluestacks.devicedetails (a13)
        if(callingPackage != null && callingPackage.equals("com.bluestacks.devicedetails"))
            return true;

        LegacyPermissionManager permissionManager = (LegacyPermissionManager)
"""),
], "TelephonyPermissions BST phone-state bypass")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
