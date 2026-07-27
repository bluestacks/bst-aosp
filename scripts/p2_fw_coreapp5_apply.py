#!/usr/bin/env python3
# P2-FW-CORE-APP-5: Settings anti-detection + Environment sdcard_emul (a13->a16).
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


ENV_GET_EXTERNAL_DIRS_HOOK = """
            // A16DBG:P2:FW-CORE-APP-5 sdcard_emul path redirect (a13 cases 14080/12660, BS4-2783)
            try {
                int pid = Process.myPid();
                String packageName = BstUtils.getAppNameFromPid(pid);
                IBstFilterAppsService mBstFilter = IBstFilterAppsService.Stub.asInterface(
                        ServiceManager.getService(Context.BST_FILTER_APPS));
                File[] cachedOrigExternalPath = new File[1];
                cachedOrigExternalPath[0] = volumes[0].getPathFile();

                if (modifySdPathForFnCall && packageName != null
                        && mBstFilter.isModifysdPathReqd(packageName)) {
                    String emulatedExternalStorageDir = new StringBuilder(DIR_DATA)
                            .append("/").append(packageName).append(SDCARD_EMUL_PATH).toString();
                    files[0] = new File(DIR_ANDROID_DATA, emulatedExternalStorageDir);

                    File emulatedObbPath = (buildPaths(files, DIR_ANDROID, DIR_OBB))[0];
                    File actualObbPath = (buildPaths(cachedOrigExternalPath, DIR_ANDROID, DIR_OBB,
                            packageName))[0];
                    String[] actualObbPathFiles = actualObbPath.list();
                    if (actualObbPathFiles != null && actualObbPathFiles.length > 0
                            && !emulatedObbPath.exists()) {
                        emulatedObbPath.mkdirs();
                        File emulatedObbFullPath = new File(emulatedObbPath, packageName);
                        Os.symlink(actualObbPath.toString(), emulatedObbFullPath.toString());
                    }
                    return files;
                }
            } catch (Exception e) {
                Log.w(TAG, "A16DBG:P2:FW-CORE-APP-5 isModifysdPathReqd: " + e.getMessage());
            } finally {
                modifySdPathForFnCall = false;
            }

"""

STORAGE_VOLUME_REDIRECT = """
        StorageVolume volume = null;
        // A16DBG:P2:FW-CORE-APP-5 SDCARD_EMUL_PATH storage query redirect (a13)
        if (path.toString().contains(SDCARD_EMUL_PATH)) {
            final File externalDir = sCurrentUser.getExternalDirs()[0];
            volume = StorageManager.getStorageVolume(externalDir, UserHandle.myUserId());
        } else {
            volume = StorageManager.getStorageVolume(path, UserHandle.myUserId());
        }
"""

patch(
    "core/java/android/os/Environment.java",
    [
        (
            "import android.os.storage.StorageVolume;\n",
            "import android.os.storage.StorageVolume;\nimport android.system.Os;\n"
            "import android.util.BstUtils;\n",
        ),
        (
            "import java.util.Objects;\n",
            "import java.util.Objects;\n\nimport com.bluestacks.os.IBstFilterAppsService;\n",
        ),
        (
            "    private static Boolean sNoIsolatedStorageAppOp;\n",
            "    private static Boolean sNoIsolatedStorageAppOp;\n\n"
            "    // A16DBG:P2:FW-CORE-APP-5 sdcard_emul (a13 cases 14080/12660)\n"
            "    private static final String SDCARD_EMUL_PATH = \"/sdcard_emul\";\n"
            "    private static boolean modifySdPathForFnCall = false;\n",
        ),
        (
            """            final File[] files = new File[volumes.length];
            for (int i = 0; i < volumes.length; i++) {
                files[i] = volumes[i].getPathFile();
            }
            return files;
        }

        @UnsupportedAppUsage
        public File getExternalStorageDirectory() {
""",
            """            final File[] files = new File[volumes.length];
"""
            + ENV_GET_EXTERNAL_DIRS_HOOK
            + """            for (int i = 0; i < volumes.length; i++) {
                files[i] = volumes[i].getPathFile();
            }
            return files;
        }

        @UnsupportedAppUsage
        public File getExternalStorageDirectory() {
""",
        ),
        (
            "        public File[] buildExternalStorageAndroidDataDirs() {\n"
            "            return buildPaths(getExternalDirs(), DIR_ANDROID, DIR_DATA);\n        }\n",
            "        public File[] buildExternalStorageAndroidDataDirs() {\n"
            "            modifySdPathForFnCall = true;\n"
            "            return buildPaths(getExternalDirs(), DIR_ANDROID, DIR_DATA);\n        }\n",
        ),
        (
            "        public File[] buildExternalStorageAppDataDirs(String packageName) {\n"
            "            return buildPaths(getExternalDirs(), DIR_ANDROID, DIR_DATA, packageName);\n        }\n",
            "        public File[] buildExternalStorageAppDataDirs(String packageName) {\n"
            "            modifySdPathForFnCall = true;\n"
            "            return buildPaths(getExternalDirs(), DIR_ANDROID, DIR_DATA, packageName);\n        }\n",
        ),
        (
            "        public File[] buildExternalStorageAppFilesDirs(String packageName) {\n"
            "            return buildPaths(getExternalDirs(), DIR_ANDROID, DIR_DATA, packageName, DIR_FILES);\n        }\n",
            "        public File[] buildExternalStorageAppFilesDirs(String packageName) {\n"
            "            modifySdPathForFnCall = true;\n"
            "            return buildPaths(getExternalDirs(), DIR_ANDROID, DIR_DATA, packageName, DIR_FILES);\n        }\n",
        ),
        (
            "        public File[] buildExternalStorageAppCacheDirs(String packageName) {\n"
            "            return buildPaths(getExternalDirs(), DIR_ANDROID, DIR_DATA, packageName, DIR_CACHE);\n        }\n",
            "        public File[] buildExternalStorageAppCacheDirs(String packageName) {\n"
            "            modifySdPathForFnCall = true;\n"
            "            return buildPaths(getExternalDirs(), DIR_ANDROID, DIR_DATA, packageName, DIR_CACHE);\n        }\n",
        ),
        (
            "    public static String getExternalStorageState(File path) {\n"
            "        final StorageVolume volume = StorageManager.getStorageVolume(path, UserHandle.myUserId());\n",
            "    public static String getExternalStorageState(File path) {\n" + STORAGE_VOLUME_REDIRECT,
        ),
        (
            "    public static boolean isExternalStorageRemovable(@NonNull File path) {\n"
            "        final StorageVolume volume = StorageManager.getStorageVolume(path, UserHandle.myUserId());\n",
            "    public static boolean isExternalStorageRemovable(@NonNull File path) {\n"
            + STORAGE_VOLUME_REDIRECT,
        ),
        (
            "    public static boolean isExternalStorageEmulated(@NonNull File path) {\n"
            "        final StorageVolume volume = StorageManager.getStorageVolume(path, UserHandle.myUserId());\n",
            "    public static boolean isExternalStorageEmulated(@NonNull File path) {\n"
            + STORAGE_VOLUME_REDIRECT,
        ),
    ],
    "Environment.sdcard_emul",
)

SETTINGS_GET_HOOK = """
            // A16DBG:P2:FW-CORE-APP-5 Settings anti-detection hooks (a13)
            if (name != null && name.equals(Settings.Secure.ALLOW_MOCK_LOCATION)) {
                try {
                    int pid = Binder.getCallingPid();
                    String callingApp = BstUtils.getAppNameFromPid(pid);
                    if (callingApp != null && callingApp.startsWith("com.nianticlabs")) {
                        if (DEBUG) Log.w(TAG, "A16DBG:P2:FW-CORE-APP-5 fake ALLOW_MOCK_LOCATION for "
                                + callingApp);
                        return "0";
                    }
                } catch (Exception e) {
                    Log.w(TAG, "A16DBG:P2:FW-CORE-APP-5 ALLOW_MOCK_LOCATION: " + e.getMessage());
                }
            } else if (name != null && name.equals(Settings.Global.WEBVIEW_MULTIPROCESS)) {
                try {
                    int pid = Binder.getCallingPid();
                    String callingApp = BstUtils.getAppNameFromPid(pid);
                    if (callingApp != null && (callingApp.startsWith("com.netease.mrzh")
                            || callingApp.equals("com.tencent.tmgp.yongyong.mrzh"))) {
                        return "1";
                    }
                } catch (Exception e) {
                    Log.w(TAG, "A16DBG:P2:FW-CORE-APP-5 WEBVIEW_MULTIPROCESS: " + e.getMessage());
                }
            } else if (name != null && (name.equals(Settings.Global.ADB_ENABLED)
                    || name.equals(Settings.Global.DEVELOPMENT_SETTINGS_ENABLED))) {
                try {
                    int uid = Binder.getCallingUid();
                    if (uid >= 10000) {
                        return "0";
                    }
                } catch (Exception e) {
                    Log.w(TAG, "A16DBG:P2:FW-CORE-APP-5 ADB/DEV_SETTINGS: " + e.getMessage());
                }
            }

"""

patch(
    "core/java/android/provider/Settings.java",
    [
        (
            "import android.util.ArraySet;\n",
            "import android.util.ArraySet;\nimport android.util.BstUtils;\n",
        ),
        (
            """        public boolean putStringForUser(ContentResolver cr, String name, String value,
                String tag, boolean makeDefault, final @CanBeCURRENT @UserIdInt int userId,
                boolean overrideableByRestore) {
            try {
                Bundle arg = new Bundle();
""",
            """        public boolean putStringForUser(ContentResolver cr, String name, String value,
                String tag, boolean makeDefault, final @CanBeCURRENT @UserIdInt int userId,
                boolean overrideableByRestore) {
            // A16DBG:P2:FW-CORE-APP-5 block apps changing brightness/screen timeout (a13)
            if (name.equals("screen_brightness") || name.equals("screen_off_timeout")) {
                Log.d(TAG, "Package name:-" + cr.getPackageName() + " trying to change " + name
                        + " with value=" + value);
                return true;
            }
            try {
                Bundle arg = new Bundle();
""",
        ),
        (
            """                }
            }

            IContentProvider cp = mProviderHolder.getProvider(cr);
            if (cp == null) {
                Log.w(TAG, "Can't get key " + name + " because cp is null");
                return null;  // Return null, but don't cache it.
            }

            // Try the fast path first, not using query().  If this
""",
            """                }
            }
"""
            + SETTINGS_GET_HOOK
            + """
            IContentProvider cp = mProviderHolder.getProvider(cr);
            if (cp == null) {
                Log.w(TAG, "Can't get key " + name + " because cp is null");
                return null;  // Return null, but don't cache it.
            }

            // Try the fast path first, not using query().  If this
""",
        ),
    ],
    "Settings anti-detection",
)

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS:
        print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
