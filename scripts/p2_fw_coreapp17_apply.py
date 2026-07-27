#!/usr/bin/env python3
# P2-FW-CORE-APP-17: Display rotation override with kill-switch (default off; APP-7 3/7 without).
import os
import sys

A16 = os.path.expanduser("~/aosp16/frameworks/base")
ERRS = []
MARKER = "A16DBG:P2:FW-CORE-APP-17"


def patch(rel, replacements, label):
    full = os.path.join(A16, rel)
    with open(full) as f:
        src = f.read()
    if MARKER in src:
        print(f"SKIP {label} (already patched)")
        return
    orig = src
    for old, new in replacements:
        if old not in src:
            ERRS.append(f"{label}: ANCHOR NOT FOUND: {old.strip()[:70]!r}")
            return
        if src.count(old) > 1:
            ERRS.append(
                f"{label}: ANCHOR NOT UNIQUE ({src.count(old)}): {old.strip()[:70]!r}"
            )
            return
        src = src.replace(old, new, 1)
    if src == orig:
        ERRS.append(f"{label}: no change")
        return
    with open(full, "w") as f:
        f.write(src)
    print(f"OK   {label}")


ROTATION_FIELDS = """
    // A16DBG:P2:FW-CORE-APP-17 rotation override fields (kill-switch default off)
    private String mLastPkg = "";
    private boolean mModifyDisplayRotation = false;
    private int mFixedSurfaceRotation = -1;
"""

GET_ROTATION = """
    public int getRotation() {
        synchronized (mLock) {
            // A16DBG:P2:FW-CORE-APP-17 rotation override (bst.enable_display_rotation=1 to enable)
            if (android.os.SystemProperties.getInt("bst.enable_display_rotation", 0) == 0) {
                updateDisplayInfoLocked();
                return getLocalRotation();
            }
            try {
                if (Binder.getCallingUid() >= Process.FIRST_APPLICATION_UID) {
                    String callingApp = BstUtils.getAppNameFromPid(Process.myPid());
                    if (callingApp != null && !callingApp.equals(mLastPkg)) {
                        IBstFilterAppsService bstfilter = IBstFilterAppsService.Stub.asInterface(
                                ServiceManager.getService(Context.BST_FILTER_APPS));
                        if (bstfilter != null) {
                            mModifyDisplayRotation = bstfilter.isModifyDisplayRotationApp(callingApp);
                            mFixedSurfaceRotation = bstfilter.getFixedSurfaceRotationRequired(
                                    callingApp);
                        }
                        mLastPkg = callingApp;
                    }
                }
            } catch (Exception exe) {
                Log.w(TAG, "A16DBG:P2:FW-CORE-APP-17 rotation query: " + exe);
            }
            updateDisplayInfoLocked();
            if (mModifyDisplayRotation) {
                return ((mDisplayInfo.rotation == 0) ? 1 : 0);
            }
            if (mFixedSurfaceRotation >= 0) {
                return mFixedSurfaceRotation;
            }
            return getLocalRotation();
        }
    }
"""

patch(
    "core/java/android/view/Display.java",
    [
        (
            "import android.os.Process;\n",
            "import android.os.Process;\nimport android.os.SystemProperties;\n",
        ),
        (
            "    // A16DBG:P2:FW-CORE-APP-10 Display BST metrics helpers (a13; rotation deferred after APP-7 3/7)\n    private int mCachedCustomDpi = -1;\n",
            "    // A16DBG:P2:FW-CORE-APP-10 Display BST metrics helpers (a13)\n    private int mCachedCustomDpi = -1;\n"
            + ROTATION_FIELDS,
        ),
        (
            """    public int getRotation() {
        synchronized (mLock) {
            updateDisplayInfoLocked();
            return getLocalRotation();
        }
    }
""",
            GET_ROTATION,
        ),
    ],
    "Display rotation kill-switch",
)

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS:
        print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
