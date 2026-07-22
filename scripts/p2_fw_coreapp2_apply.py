#!/usr/bin/env python3
# P2-FW-CORE-APP-2: surgical BST hooks (a13 -> a16) — 2 independent app-framework files.
# View (ROB-11421 Roblox immersive via SYSTEM_UI_FLAG_FULLSCREEN) +
# ApkLiteParseUtils (ROB-15882 Pokemon extractNativeLibs anti-detection).
# Both depend only on already-present BST infra (BstUtils/BstHostCallManager/IBstFilterAppsService
# + Context.BST_* constants). App-process, non-startActivity-hot-path. Robust exact-string replace.
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

# 1) View.java — ROB-11421 Roblox immersive mode via SYSTEM_UI_FLAG_FULLSCREEN (a13).
patch("core/java/android/view/View.java", [
    ("import android.os.Build;\n",
     "import android.os.Binder;\nimport android.os.Build;\n"),
    ("import android.util.AttributeSet;\n",
     "import android.util.AttributeSet;\nimport android.util.BstUtils;\n"),
    ("import java.util.function.Predicate;\n",
     "import java.util.function.Predicate;\n\nimport com.bluestacks.os.BstHostCallManager;\n"),
    ("""    public void setSystemUiVisibility(int visibility) {
        if (visibility != mSystemUiVisibility) {
            mSystemUiVisibility = visibility;
""",
     """    public void setSystemUiVisibility(int visibility) {
        if (visibility != mSystemUiVisibility) {
            // A16DBG:P2:FW-CORE-APP ROB-11421 Roblox immersive via SYSTEM_UI_FLAG_FULLSCREEN (a13)
            if ((visibility & View.SYSTEM_UI_FLAG_FULLSCREEN)
                    != (mSystemUiVisibility & View.SYSTEM_UI_FLAG_FULLSCREEN)) {
                int uid = Binder.getCallingUid();
                if (uid >= 10000) {
                    String packageName = BstUtils.getAppNameFromPid(Binder.getCallingPid());
                    if (packageName != null && packageName.equals("com.roblox.client")) {
                        String activityName = " "; // HD ignores param but empty-checks
                        String mouseAction = (visibility & View.SYSTEM_UI_FLAG_FULLSCREEN)
                                == View.SYSTEM_UI_FLAG_FULLSCREEN ? "enableNative" : "";
                        String lastSent = android.os.SystemProperties.get(
                                "bst.config.last_mouse_action", "");
                        if (!mouseAction.isEmpty() || !lastSent.isEmpty()) {
                            BstHostCallManager hcm = (BstHostCallManager)
                                    mContext.getSystemService(Context.BST_HOST_CALL);
                            if (hcm != null) {
                                int rval = hcm.onSetMouseAction(packageName, activityName, mouseAction);
                                android.os.SystemProperties.set(
                                        "bst.config.last_mouse_action", mouseAction);
                                if (rval != 0) {
                                    Log.w(VIEW_LOG_TAG, "A16DBG:P2:FW-CORE-APP onSetMouseAction rval=" + rval);
                                }
                            }
                        }
                    }
                }
            }
            mSystemUiVisibility = visibility;
"""),
], "View.ROB-11421 Roblox immersive")

# 2) ApkLiteParseUtils.java — ROB-15882 Pokemon extractNativeLibs anti-detection (a13).
patch("core/java/android/content/pm/parsing/ApkLiteParseUtils.java", [
    ("import java.util.Set;\n",
     "import java.util.Set;\n\nimport android.content.Context;\n"
     "import android.os.Process;\nimport android.os.ServiceManager;\n"
     "import com.bluestacks.os.IBstFilterAppsService;\n"),
    ("""        // Check to see if overlay should be excluded based on system property condition
""",
     """        // A16DBG:P2:FW-CORE-APP ROB-15882 force extractNativeLibs for anti-detection (a13)
        try {
            int ppid = android.os.Process.myPpid();
            if (ppid != 1 && ppid != 2 && !packageSplit.first.equals("system_server")) {
                IBstFilterAppsService BstFilter = IBstFilterAppsService.Stub.asInterface(
                        ServiceManager.getService(Context.BST_FILTER_APPS));
                if (BstFilter != null && BstFilter.isExtractNativeLibs(packageSplit.first)) {
                    extractNativeLibs = true;
                }
            }
        } catch (Exception ex) {
            Slog.d(TAG, ex.getMessage());
            ex.printStackTrace();
        }
        // Check to see if overlay should be excluded based on system property condition
"""),
], "ApkLiteParseUtils.ROB-15882 Pokemon native libs")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
