#!/usr/bin/env python3
# P2-FW-CORE-APP-7: Display.java custom DPI + rotation override + metrics (a13->a16).
import os, sys

A16 = os.path.expanduser("~/aosp16/frameworks/base")
ERRS = []


def patch(rel, replacements, label):
    full = os.path.join(A16, rel)
    with open(full) as f:
        src = f.read()
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


BST_HELPERS = """
    // A16DBG:P2:FW-CORE-APP-7 Display BST helpers (a13 custom DPI / rotation / xydpi)
    private String mLastPkg = "";
    private boolean mModifyDisplayRotation = false;
    private int mFixedSurfaceRotation = -1;
    private int mCachedCustomDpi = -1;

    private int getCustomDpi() {
        try {
            if (mCachedCustomDpi == -1) {
                int ppid = Process.myPpid();
                if (ppid != 1 && ppid != 2) {
                    int uid = Binder.getCallingUid();
                    if (uid >= 10000) {
                        String callingApp = BstUtils.getAppNameFromPid(Process.myPid());
                        mCachedCustomDpi = (callingApp != null
                                && BstUtils.bstIsCallingAppPrivileged(uid, callingApp))
                                ? 0 : BstUtils.getCustomDpi();
                    } else {
                        mCachedCustomDpi = 0;
                    }
                } else {
                    mCachedCustomDpi = 0;
                }
            }
        } catch (Exception ex) {
            Log.d(TAG, "A16DBG:P2:FW-CORE-APP-7 getCustomDpi: " + ex);
            mCachedCustomDpi = 0;
        }
        return mCachedCustomDpi;
    }

    private void bstApplyCustomDpiToMetrics(DisplayMetrics outMetrics) {
        int customDpiValue = getCustomDpi();
        if (customDpiValue != 0) {
            float dpiRatio = customDpiValue / 160f;
            outMetrics.density = dpiRatio;
            outMetrics.densityDpi = customDpiValue;
            outMetrics.scaledDensity = dpiRatio;
        }
    }

    private void bstApplyXYDpiOverride(DisplayMetrics outMetrics) {
        try {
            if (Binder.getCallingUid() >= 10000) {
                String callingApp = BstUtils.getAppNameFromPid(Process.myPid());
                IBstFilterAppsService bstfilter = IBstFilterAppsService.Stub.asInterface(
                        ServiceManager.getService(Context.BST_FILTER_APPS));
                if (callingApp != null && bstfilter != null && bstfilter.isDefaultXYDpi(callingApp)) {
                    if (DEBUG) Log.d(TAG, "App[" + callingApp + "] use Default Xdpi and Ydpi");
                } else {
                    outMetrics.xdpi = outMetrics.ydpi = outMetrics.densityDpi;
                }
            }
        } catch (Exception exception) {
            Log.w(TAG, "A16DBG:P2:FW-CORE-APP-7 xydpi: " + exception);
        }
    }

"""

patch(
    "core/java/android/view/Display.java",
    [
        (
            "import android.compat.annotation.UnsupportedAppUsage;\n",
            "import android.compat.annotation.UnsupportedAppUsage;\nimport android.content.Context;\n",
        ),
        (
            "import android.os.Build;\n",
            "import android.os.Binder;\nimport android.os.Build;\nimport android.os.ServiceManager;\n",
        ),
        (
            "import android.util.ArraySet;\n",
            "import android.util.ArraySet;\nimport android.util.BstUtils;\n\n"
            "import com.bluestacks.os.IBstFilterAppsService;\n",
        ),
        (
            "    private boolean mIsValid;\n\n    // Temporary display metrics structure",
            "    private boolean mIsValid;\n\n" + BST_HELPERS + "\n    // Temporary display metrics structure",
        ),
        (
            """    public boolean getDisplayInfo(DisplayInfo outDisplayInfo) {
        synchronized (mLock) {
            updateDisplayInfoLocked();
            outDisplayInfo.copyFrom(mDisplayInfo);
            return mIsValid;
        }
    }
""",
            """    public boolean getDisplayInfo(DisplayInfo outDisplayInfo) {
        synchronized (mLock) {
            updateDisplayInfoLocked();
            outDisplayInfo.copyFrom(mDisplayInfo);
            int customDpiValue = getCustomDpi();
            if (customDpiValue != 0) {
                outDisplayInfo.logicalDensityDpi = customDpiValue;
            }
            return mIsValid;
        }
    }
""",
        ),
        (
            """    public int getRotation() {
        synchronized (mLock) {
            updateDisplayInfoLocked();
            return getLocalRotation();
        }
    }
""",
            """    public int getRotation() {
        synchronized (mLock) {
            // A16DBG:P2:FW-CORE-APP-7 rotation override for FilterApps packages (a13)
            try {
                if (Binder.getCallingUid() >= 10000) {
                    String callingApp = BstUtils.getAppNameFromPid(Process.myPid());
                    if (callingApp != null && !callingApp.equals(mLastPkg)) {
                        IBstFilterAppsService bstfilter = IBstFilterAppsService.Stub.asInterface(
                                ServiceManager.getService(Context.BST_FILTER_APPS));
                        if (bstfilter != null) {
                            mModifyDisplayRotation = bstfilter.isModifyDisplayRotationApp(callingApp);
                            mFixedSurfaceRotation = bstfilter.getFixedSurfaceRotationRequired(callingApp);
                        }
                        mLastPkg = callingApp;
                    }
                }
            } catch (Exception exe) {
                Log.w(TAG, "A16DBG:P2:FW-CORE-APP-7 rotation query: " + exe);
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
""",
        ),
        (
            """    public void getMetrics(DisplayMetrics outMetrics) {
        synchronized (mLock) {
            updateDisplayInfoLocked();
            mDisplayInfo.getAppMetrics(outMetrics, getDisplayAdjustments());
        }
    }
""",
            """    public void getMetrics(DisplayMetrics outMetrics) {
        synchronized (mLock) {
            updateDisplayInfoLocked();
            mDisplayInfo.getAppMetrics(outMetrics, getDisplayAdjustments());
            bstApplyCustomDpiToMetrics(outMetrics);
            bstApplyXYDpiOverride(outMetrics);
        }
    }
""",
        ),
        (
            """                if (DEBUG) {
                    Log.d(TAG, "getRealMetrics determined from max bounds: " + outMetrics);
                }
                // Skip adjusting by fixed rotation, since if it is necessary, the configuration
                // should already reflect the expected rotation.
                return;
            }
            mDisplayInfo.getLogicalMetrics(outMetrics,
                    CompatibilityInfo.DEFAULT_COMPATIBILITY_INFO, null);
            final @Surface.Rotation int rotation = getLocalRotation();
            if (rotation != mDisplayInfo.rotation) {
                adjustMetrics(outMetrics, mDisplayInfo.rotation, rotation);
            }
        }
    }
""",
            """                if (DEBUG) {
                    Log.d(TAG, "getRealMetrics determined from max bounds: " + outMetrics);
                }
                bstApplyCustomDpiToMetrics(outMetrics);
                bstApplyXYDpiOverride(outMetrics);
                // Skip adjusting by fixed rotation, since if it is necessary, the configuration
                // should already reflect the expected rotation.
                return;
            }
            mDisplayInfo.getLogicalMetrics(outMetrics,
                    CompatibilityInfo.DEFAULT_COMPATIBILITY_INFO, null);
            final @Surface.Rotation int rotation = getLocalRotation();
            if (rotation != mDisplayInfo.rotation) {
                adjustMetrics(outMetrics, mDisplayInfo.rotation, rotation);
            }
            bstApplyCustomDpiToMetrics(outMetrics);
            bstApplyXYDpiOverride(outMetrics);
        }
    }
""",
        ),
    ],
    "Display custom DPI and rotation",
)

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS:
        print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
