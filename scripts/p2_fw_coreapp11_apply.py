#!/usr/bin/env python3
# P2-FW-CORE-APP-11: ResourcesImpl custom DPI + xydpi + fake config + status_bar (a13->a16).
import os
import sys

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
    // A16DBG:P2:FW-CORE-APP-11 ResourcesImpl BST custom DPI / status_bar (a13)
    private static final boolean DEBUG_BST = SystemProperties.getBoolean("bst.debug.status_bar", false);
    private static final boolean mBstHideStatusBar =
            SystemProperties.getInt("bst.enable_statusbar", 1) == 0;

    private int mCachedCustomDpi = -1;

    private int getCustomDpi() {
        try {
            if (mCachedCustomDpi == -1) {
                int ppid = android.os.Process.myPpid();
                if (ppid != 1 && ppid != 2) {
                    int uid = Binder.getCallingUid();
                    if (uid >= Process.FIRST_APPLICATION_UID) {
                        int pid = android.os.Process.myPid();
                        String callingApp = BstUtils.getAppNameFromPid(pid);
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
            Slog.d(TAG, "A16DBG:P2:FW-CORE-APP-11 getCustomDpi: " + ex);
            mCachedCustomDpi = 0;
        }
        return mCachedCustomDpi;
    }

"""

patch(
    "core/java/android/content/res/ResourcesImpl.java",
    [
        (
            "import android.content.res.Resources.NotFoundException;\n",
            "import android.content.Context;\nimport android.content.res.Resources.NotFoundException;\n",
        ),
        (
            "import android.os.Build;\n",
            "import android.os.Binder;\nimport android.os.Build;\nimport android.os.Process;\n"
            "import android.os.ServiceManager;\nimport android.os.SystemProperties;\n",
        ),
        (
            "import android.util.AttributeSet;\n",
            "import android.util.AttributeSet;\nimport android.util.BstUtils;\n",
        ),
        (
            "import com.android.internal.util.GrowingArrayUtils;\n",
            "import com.android.internal.util.GrowingArrayUtils;\n\n"
            "import com.bluestacks.os.IBstFilterAppsService;\n",
        ),
        (
            """    static {
        sPreloadedDrawables = new LongSparseArray[2];
        sPreloadedDrawables[0] = new LongSparseArray<>();
        sPreloadedDrawables[1] = new LongSparseArray<>();
    }

    private static final LocaleConfig sEmptyLocaleConfig =
""",
            """    static {
        sPreloadedDrawables = new LongSparseArray[2];
        sPreloadedDrawables[0] = new LongSparseArray<>();
        sPreloadedDrawables[1] = new LongSparseArray<>();
    }
"""
            + BST_HELPERS
            + """
    private static final LocaleConfig sEmptyLocaleConfig =
""",
        ),
        (
            """    DisplayMetrics getDisplayMetrics() {
        if (DEBUG_CONFIG) Slog.v(TAG, "Returning DisplayMetrics: " + mMetrics.widthPixels
                + "x" + mMetrics.heightPixels + " " + mMetrics.density);
        return mMetrics;
    }
""",
            """    DisplayMetrics getDisplayMetrics() {
        if (DEBUG_CONFIG) Slog.v(TAG, "Returning DisplayMetrics: " + mMetrics.widthPixels
                + "x" + mMetrics.heightPixels + " " + mMetrics.density);

        int customDpiValue = getCustomDpi();
        if (customDpiValue != 0) {
            float dpiRatio = customDpiValue / 160f;
            mMetrics.density = dpiRatio;
            mMetrics.densityDpi = customDpiValue;
            mMetrics.scaledDensity = dpiRatio;
            if (DEBUG_CONFIG) {
                Slog.v(TAG, "A16DBG:P2:FW-CORE-APP-11 fake density:" + mMetrics.density
                        + " dpi=" + mMetrics.densityDpi);
            }
        }

        try {
            String topPackageName = SystemProperties.get("bst.config.top_package_name", null);
            if (topPackageName != null
                    && topPackageName.equals("com.jagex.runescape.android")) {
                mMetrics.xdpi = mMetrics.ydpi = mMetrics.densityDpi;
            }
            if (topPackageName != null && !topPackageName.equals("")) {
                IBstFilterAppsService bstfilter = IBstFilterAppsService.Stub.asInterface(
                        ServiceManager.getService(Context.BST_FILTER_APPS));
                if (bstfilter != null && bstfilter.isDefaultXYDpi(topPackageName)) {
                    if (DEBUG_CONFIG) {
                        Log.d(TAG, "A16DBG:P2:FW-CORE-APP-11 default xydpi " + topPackageName);
                    }
                } else {
                    mMetrics.xdpi = mMetrics.ydpi = mMetrics.densityDpi;
                }
            }
        } catch (Exception exception) {
            Log.w(TAG, "A16DBG:P2:FW-CORE-APP-11 xydpi: " + exception);
        }
        return mMetrics;
    }
""",
        ),
        (
            """    @UnsupportedAppUsage
    public Configuration getConfiguration() {
        return mConfiguration;
    }
""",
            """    @UnsupportedAppUsage
    public Configuration getConfiguration() {
        int customDpiValue = getCustomDpi();
        if (customDpiValue != 0) {
            Configuration fakeConfig = new Configuration();
            fakeConfig.setTo(mConfiguration);
            float dpiRatio = customDpiValue / 160f;
            int left = mConfiguration.windowConfiguration.getAppBounds().left;
            int right = mConfiguration.windowConfiguration.getAppBounds().right;
            int top = mConfiguration.windowConfiguration.getAppBounds().top;
            int bottom = mConfiguration.windowConfiguration.getAppBounds().bottom;
            fakeConfig.screenWidthDp = (int) Math.floor((right - left) / dpiRatio);
            fakeConfig.smallestScreenWidthDp = (int) Math.floor((bottom - top) / dpiRatio);
            fakeConfig.screenHeightDp = fakeConfig.smallestScreenWidthDp
                    - (mConfiguration.smallestScreenWidthDp - mConfiguration.screenHeightDp);
            fakeConfig.densityDpi = customDpiValue;
            if (DEBUG_CONFIG) {
                Slog.v(TAG, "A16DBG:P2:FW-CORE-APP-11 fakeConfig dpi=" + fakeConfig.densityDpi);
            }
            return fakeConfig;
        }
        return mConfiguration;
    }
""",
        ),
        (
            """    int getIdentifier(String name, String defType, String defPackage) {
        if (name == null) {
            throw new NullPointerException("name is null");
        }
        if (isIntLike(name)) {
""",
            """    int getIdentifier(String name, String defType, String defPackage) {
        if (name == null) {
            throw new NullPointerException("name is null");
        }
        if (mBstHideStatusBar) {
            String resourceName = name;
            String resourceType = defType;
            String pkg = defPackage;
            if (resourceName.contains(":")) {
                pkg = resourceName.split(":")[0];
                resourceName = resourceName.split(":")[1];
            }
            if (resourceName.contains("/")) {
                String[] parts = resourceName.split("/");
                resourceType = parts[0];
                resourceName = parts[1];
            }
            if (resourceType != null && resourceType.equals("dimen") && pkg != null
                    && pkg.equals("android")) {
                if (resourceName.equals("status_bar_height")) {
                    if (DEBUG_BST) {
                        Log.d(TAG, "A16DBG:P2:FW-CORE-APP-11 status_bar_height -> 0");
                    }
                    name = "bst_system_bar_height";
                    defType = "dimen";
                    defPackage = "android";
                }
            }
        }
        if (isIntLike(name)) {
""",
        ),
    ],
    "ResourcesImpl BST hooks",
)

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS:
        print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
