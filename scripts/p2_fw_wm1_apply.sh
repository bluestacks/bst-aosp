#!/bin/bash
# P2-FW-WM-1 surgical: ActivityStarter (hideBlueStacksPkg + optional GRM) + ATM getGlVersion
set +u
python3 - <<'PY'
from pathlib import Path

A16 = Path.home() / "aosp16/frameworks/base"

# ---- ActivityStarter ----
p = A16 / "services/core/java/com/android/server/wm/ActivityStarter.java"
t = p.read_text()
if "A16DBG:P2:FW-WM ActivityStarter" in t:
    print("ActivityStarter already patched")
else:
    # imports
    if "import android.util.BstUtils;" not in t:
        t = t.replace(
            "import android.util.ArraySet;\n",
            "import android.util.ArraySet;\nimport android.util.BstUtils;\n",
            1,
        )
    if "import com.bluestacks.os.BstHostCallManager;" not in t:
        # after last import before java.io
        needle = "import java.io.PrintWriter;"
        if needle not in t:
            raise SystemExit("PrintWriter import missing")
        t = t.replace(
            needle,
            "import com.bluestacks.os.BstHostCallManager;\n\n" + needle,
            1,
        )
    if "private BstHostCallManager mBstHostCallManagerService;" not in t:
        t = t.replace(
            "    private String mLastStartReason;\n",
            "    private String mLastStartReason;\n\n"
            "    private BstHostCallManager mBstHostCallManagerService;\n",
            1,
        )

    # Insert after: final int userId = ... launchMode ... block's opening success log start
    # Place BST checks right after userId/launchMode computed and before logMessage, matching a13 timing
    anchor = """        final int userId = aInfo != null && aInfo.applicationInfo != null
                ? UserHandle.getUserId(aInfo.applicationInfo.uid) : 0;
        final int launchMode = aInfo != null ? aInfo.launchMode : 0;
        if (err == ActivityManager.START_SUCCESS) {
            request.logMessage.append(\"START u\").append(userId).append(\" {\")
"""
    insert = """        final int userId = aInfo != null && aInfo.applicationInfo != null
                ? UserHandle.getUserId(aInfo.applicationInfo.uid) : 0;
        final int launchMode = aInfo != null ? aInfo.launchMode : 0;

        // A16DBG:P2:FW-WM ActivityStarter — a13 hideBlueStacksPkg + optional GRM (kill-switch)
        if (err == ActivityManager.START_SUCCESS && intent != null && intent.getComponent() != null) {
            final String launchPkg = intent.getComponent().getPackageName();
            try {
                mService.mContext.getPackageManager().getPackageInfo(launchPkg, 0);
                // GRM: default OFF (persist.bst.grm.launch_check=1 to match a13). Past Batch B Layer2 risk.
                if (android.os.SystemProperties.getBoolean(\"persist.bst.grm.launch_check\", false)) {
                    boolean bstCheckGrm = (aInfo != null) ? !aInfo.applicationInfo.isSystemApp() : true;
                    if (bstCheckGrm && callingPackage != null && launchPkg != null
                            && !callingPackage.equals(\"com.bluestacks.BstCommandProcessor\")
                            && !callingPackage.equals(launchPkg)) {
                        if (mBstHostCallManagerService == null) {
                            mBstHostCallManagerService = (BstHostCallManager) mService.mContext
                                    .getSystemService(android.content.Context.BST_HOST_CALL);
                        }
                        if (mBstHostCallManagerService != null
                                && !mBstHostCallManagerService.isAppLaunchAllowed(launchPkg, false)) {
                            Slog.i(TAG, \"A16DBG:P2:FW-WM Show grm for pkg=\" + launchPkg);
                            return err; // a13 behavior
                        }
                    }
                }
            } catch (android.content.pm.PackageManager.NameNotFoundException e) {
                Slog.w(TAG, \"A16DBG:P2:FW-WM launchPkg=\" + launchPkg + \" not installed; skip GRM\");
            }
            int bstUid = android.os.Binder.getCallingUid();
            if (bstUid >= 10000) {
                int bstPid = android.os.Binder.getCallingPid();
                String callingApp = BstUtils.getAppNameFromPid(bstPid);
                boolean isAppPrivileged = BstUtils.bstIsCallingAppPrivileged(bstUid, callingApp);
                if (BstUtils.hideBlueStacksPkg(launchPkg, isAppPrivileged)) {
                    Slog.i(TAG, \"A16DBG:P2:FW-WM hideBlueStacksPkg pkg=\" + launchPkg);
                    return ActivityManager.START_CLASS_NOT_FOUND;
                }
            }
        }

        if (err == ActivityManager.START_SUCCESS) {
            request.logMessage.append(\"START u\").append(userId).append(\" {\")
"""
    if anchor not in t:
        raise SystemExit("ActivityStarter anchor missing")
    t = t.replace(anchor, insert, 1)
    p.write_text(t)
    print("ActivityStarter patched")

# ---- ATM getDeviceConfigurationInfo ----
p = A16 / "services/core/java/com/android/server/wm/ActivityTaskManagerService.java"
t = p.read_text()
if "A16DBG:P2:FW-WM ATM getGlVersion" in t:
    print("ATM already patched")
else:
    if "import android.util.BstUtils;" not in t:
        t = t.replace(
            "import android.util.ArraySet;\n",
            "import android.util.ArraySet;\nimport android.util.BstUtils;\n",
            1,
        )
    if "import com.bluestacks.os.BstFilterAppsManager;" not in t:
        # before class javadoc / after imports
        needle = "/**\n * System service for managing activities"
        if needle not in t:
            # try alternate
            idx = t.find("public class ActivityTaskManagerService")
            # find last import before class
            last_imp = t.rfind("\nimport ", 0, idx)
            end = t.find("\n", last_imp + 1)
            t = t[: end + 1] + "import com.bluestacks.os.BstFilterAppsManager;\n" + t[end + 1 :]
        else:
            t = t.replace(
                needle,
                "import com.bluestacks.os.BstFilterAppsManager;\n\n" + needle,
                1,
            )

    old = """            config.reqGlEsVersion = GL_ES_VERSION;
        }
        return config;
    }
"""
    new = """            config.reqGlEsVersion = GL_ES_VERSION;
            // A16DBG:P2:FW-WM ATM getGlVersion — per-app GLES override from FilterApps
            try {
                final int pid = android.os.Binder.getCallingPid();
                final int uid = android.os.Binder.getCallingUid();
                if (uid >= 10000) {
                    BstFilterAppsManager bstFilter = (BstFilterAppsManager) mContext
                            .getSystemService(android.content.Context.BST_FILTER_APPS);
                    if (bstFilter != null) {
                        String pkgName = BstUtils.getAppNameFromPid(pid);
                        int glVersion = bstFilter.getGlVersion(pkgName);
                        if (glVersion != -1) {
                            config.reqGlEsVersion = glVersion;
                            Slog.i(TAG, \"A16DBG:P2:FW-WM getGlVersion pkg=\" + pkgName
                                    + \" gl=\" + glVersion);
                        }
                    }
                }
            } catch (RuntimeException e) {
                Slog.w(TAG, \"A16DBG:P2:FW-WM getGlVersion: \" + e);
            }
        }
        return config;
    }
"""
    if old not in t:
        raise SystemExit("ATM reqGlEsVersion anchor missing")
    t = t.replace(old, new, 1)
    p.write_text(t)
    print("ATM patched")

print("VERIFY ActivityStarter markers:")
for i,l in enumerate(Path(A16/"services/core/java/com/android/server/wm/ActivityStarter.java").read_text().splitlines(),1):
    if "A16DBG:P2:FW-WM" in l or "mBstHostCallManagerService" in l:
        print(f"  {i}:{l[:100]}")
print("VERIFY ATM markers:")
for i,l in enumerate(Path(A16/"services/core/java/com/android/server/wm/ActivityTaskManagerService.java").read_text().splitlines(),1):
    if "A16DBG:P2:FW-WM" in l or "getGlVersion" in l:
        print(f"  {i}:{l[:100]}")
PY
