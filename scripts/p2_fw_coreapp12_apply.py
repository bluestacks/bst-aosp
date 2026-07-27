#!/usr/bin/env python3
# P2-FW-CORE-APP-12: SharedPreferencesImpl game default settings (a13->a16, ROB-8737/11560/11613).
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


BST_FIELDS = """
    @GuardedBy("mLock")
    private String packageName = null;

    @GuardedBy("mLock")
    private boolean mBstDefaultSet = false;
"""

BST_BFAM_FIELD = """
    private BstFilterAppsManager bfam = null;
"""

BST_HELPERS = """
    // A16DBG:P2:FW-CORE-APP-12 game default SharedPreferences (a13 ROB-8737/11560/11613)
    private void setBstGameDefaultSetting(String pkg) {
        String spFilename = "";
        String spKeyValueSequences = "";
        int len = 0;
        String oneSetting = "";

        if (mBstDefaultSet || !"1".equals(SystemProperties.get("sys.boot_completed"))) {
            return;
        }

        if (bfam == null) {
            bfam = BstFilterAppsManager.getInstance();
        }

        String gameSettingString = bfam.getGameDefaultSetting(pkg);
        if (gameSettingString.length() > 1) {
            try {
                spFilename = gameSettingString.substring(
                        gameSettingString.indexOf('=') + 1, gameSettingString.indexOf(','));
                spKeyValueSequences = gameSettingString.substring(
                        gameSettingString.indexOf(('='), spFilename.length()) + 1);
            } catch (Exception e) {
                Log.e(TAG, "A16DBG:P2:FW-CORE-APP-12 game setting parse failed");
            }
        }

        int scoreAbove = bfam.getPScoreAbove(pkg);
        if (!mFile.getName().equals(spFilename)
                || SystemProperties.getInt("bst.pscore", 180) <= scoreAbove) {
            mBstDefaultSet = true;
            return;
        }

        while (len < spKeyValueSequences.length()) {
            oneSetting = spKeyValueSequences.substring(spKeyValueSequences.indexOf('<', len));
            oneSetting = oneSetting.substring(1, oneSetting.indexOf('>'));
            len += oneSetting.length() + 2;
            String type = oneSetting.substring(0, oneSetting.indexOf(':'));
            String entry_value = oneSetting.substring(oneSetting.indexOf(':') + 1);
            String entry = entry_value.substring(0, entry_value.indexOf(':'));
            String value = entry_value.substring(entry_value.indexOf(':') + 1);

            switch (type) {
                case "int":
                    Integer iv = (Integer) mMap.get(entry);
                    if (iv == null) {
                        Editor editor = edit();
                        int data = Integer.parseInt(value);
                        if (entry.equals("HighFPS") && pkg.equals("com.dts.freefireth")) {
                            MemInfoReader minfo = new MemInfoReader();
                            minfo.readMemInfo();
                            long totalMemMb = minfo.getTotalSize() / (1024 * 1024);
                            if (totalMemMb <= 1433) {
                                continue;
                            }
                        }
                        editor.putInt(entry, data);
                        editor.commit();
                    }
                    break;
                case "string":
                    String sv = (String) mMap.get(entry);
                    if (sv == null) {
                        Editor editor = edit();
                        editor.putString(entry, value);
                        editor.apply();
                    }
                    break;
                case "bool":
                    Boolean bv = (Boolean) mMap.get(entry);
                    if (bv == null) {
                        Editor editor = edit();
                        editor.putBoolean(entry, Boolean.parseBoolean(value));
                        editor.apply();
                    }
                    break;
                case "float":
                    Float fv = (Float) mMap.get(entry);
                    if (fv == null) {
                        Editor editor = edit();
                        editor.putFloat(entry, Float.parseFloat(value));
                        editor.apply();
                    }
                    break;
                case "long":
                    Long lv = (Long) mMap.get(entry);
                    if (lv == null) {
                        Editor editor = edit();
                        editor.putLong(entry, Long.parseLong(value));
                        editor.apply();
                    }
                    break;
                default:
                    break;
            }
        }
        mBstDefaultSet = true;
    }

    private int bstPatchForMartialEgameGetInt(String key, Integer v) {
        if ((v == null) && mFile.getName().equals("com.martial.egame.gp.v2.playerprefs.xml")) {
            if (key.endsWith("PERFORMANCE_MODE") || key.endsWith("OPEN_HIGH_FRAME")) {
                return 1;
            } else if (key.equals("fenbianlv")) {
                return 1;
            }
        }
        return 0;
    }

    private boolean bstPatchForMartialEgameContains(String key) {
        if (!mMap.containsKey(key)
                && mFile.getName().equals("com.martial.egame.gp.v2.playerprefs.xml")) {
            if (key.endsWith("PERFORMANCE_MODE") || key.endsWith("OPEN_HIGH_FRAME")) {
                Editor editor = edit();
                editor.putInt(key, 1);
                editor.apply();
                return true;
            }
        }
        return false;
    }

    private int bstPatchForDungeonHunterGetInt(String key, Integer v) {
        if ((v == null) && mFile.getName().equals("com.goatgames.dhs.gb.gp.v2.playerprefs.xml")) {
            if (key.startsWith("HighFPS60")) {
                return 1;
            }
        }
        return 0;
    }

    private void bstEnsurePackageNameLocked() {
        if (packageName == null || "zygote".equals(packageName)) {
            mBstDefaultSet = false;
            packageName = BstUtils.getAppNameFromPid(Binder.getCallingPid());
        }
    }

"""

patch(
    "core/java/android/app/SharedPreferencesImpl.java",
    [
        (
            "import android.content.SharedPreferences;\n",
            "import android.content.SharedPreferences;\nimport android.os.Binder;\n",
        ),
        (
            "import android.os.Looper;\n",
            "import android.os.Looper;\nimport android.os.SystemProperties;\n",
        ),
        (
            "import android.util.Log;\n",
            "import android.util.BstUtils;\nimport android.util.Log;\n",
        ),
        (
            "import com.android.internal.util.ExponentiallyBucketedHistogram;\n",
            "import com.android.internal.util.ExponentiallyBucketedHistogram;\n"
            "import com.android.internal.util.MemInfoReader;\n",
        ),
        (
            "import java.util.concurrent.CountDownLatch;\n",
            "import java.util.concurrent.CountDownLatch;\n\n"
            "import com.bluestacks.os.BstFilterAppsManager;\n",
        ),
        (
            "    private final Object mWritingToDiskLock = new Object();\n\n    @GuardedBy(\"mLock\")\n    private Map<String, Object> mMap;",
            "    private final Object mWritingToDiskLock = new Object();\n" + BST_FIELDS + "\n    @GuardedBy(\"mLock\")\n    private Map<String, Object> mMap;",
        ),
        (
            "    private int mNumSync = 0;\n\n    private static final ThreadPoolExecutor sLoadExecutor",
            "    private int mNumSync = 0;" + BST_BFAM_FIELD + "\n\n    private static final ThreadPoolExecutor sLoadExecutor",
        ),
        (
            """    public String getString(String key, @Nullable String defValue) {
        synchronized (mLock) {
            awaitLoadedLocked();
            String v = (String)mMap.get(key);
            return v != null ? v : defValue;
        }
    }
""",
            """    public String getString(String key, @Nullable String defValue) {
        bstEnsurePackageNameLocked();
        synchronized (mLock) {
            awaitLoadedLocked();
            if (packageName != null) {
                setBstGameDefaultSetting(packageName);
            }
            String v = (String)mMap.get(key);
            return v != null ? v : defValue;
        }
    }
""",
        ),
        (
            """    public int getInt(String key, int defValue) {
        synchronized (mLock) {
            awaitLoadedLocked();
            Integer v = (Integer)mMap.get(key);
            return v != null ? v : defValue;
        }
    }
""",
            """    public int getInt(String key, int defValue) {
        bstEnsurePackageNameLocked();
        synchronized (mLock) {
            awaitLoadedLocked();
            if (packageName != null) {
                setBstGameDefaultSetting(packageName);
            }
            Integer v = (Integer)mMap.get(key);
            int egameRet = bstPatchForMartialEgameGetInt(key, v);
            if (egameRet > 0) {
                return egameRet;
            }
            int dhsRet = bstPatchForDungeonHunterGetInt(key, v);
            if (dhsRet > 0) {
                return dhsRet;
            }
            return v != null ? v : defValue;
        }
    }
"""
            + BST_HELPERS,
        ),
        (
            """    public long getLong(String key, long defValue) {
        synchronized (mLock) {
            awaitLoadedLocked();
            Long v = (Long)mMap.get(key);
            return v != null ? v : defValue;
        }
    }
""",
            """    public long getLong(String key, long defValue) {
        bstEnsurePackageNameLocked();
        synchronized (mLock) {
            awaitLoadedLocked();
            if (packageName != null) {
                setBstGameDefaultSetting(packageName);
            }
            Long v = (Long)mMap.get(key);
            return v != null ? v : defValue;
        }
    }
""",
        ),
        (
            """    public float getFloat(String key, float defValue) {
        synchronized (mLock) {
            awaitLoadedLocked();
            Float v = (Float)mMap.get(key);
            return v != null ? v : defValue;
        }
    }
""",
            """    public float getFloat(String key, float defValue) {
        bstEnsurePackageNameLocked();
        synchronized (mLock) {
            awaitLoadedLocked();
            if (packageName != null) {
                setBstGameDefaultSetting(packageName);
            }
            Float v = (Float)mMap.get(key);
            return v != null ? v : defValue;
        }
    }
""",
        ),
        (
            """    public boolean getBoolean(String key, boolean defValue) {
        synchronized (mLock) {
            awaitLoadedLocked();
            Boolean v = (Boolean)mMap.get(key);
            return v != null ? v : defValue;
        }
    }
""",
            """    public boolean getBoolean(String key, boolean defValue) {
        bstEnsurePackageNameLocked();
        synchronized (mLock) {
            awaitLoadedLocked();
            if (packageName != null) {
                setBstGameDefaultSetting(packageName);
            }
            Boolean v = (Boolean)mMap.get(key);
            return v != null ? v : defValue;
        }
    }
""",
        ),
        (
            """    public boolean contains(String key) {
        synchronized (mLock) {
            awaitLoadedLocked();
            return mMap.containsKey(key);
        }
    }
""",
            """    public boolean contains(String key) {
        synchronized (mLock) {
            awaitLoadedLocked();
            if (bstPatchForMartialEgameContains(key)) {
                return true;
            }
            return mMap.containsKey(key);
        }
    }
""",
        ),
    ],
    "SharedPreferencesImpl BST hooks",
)

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS:
        print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
