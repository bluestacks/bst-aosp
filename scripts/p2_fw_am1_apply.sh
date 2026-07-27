#!/bin/bash
# P2-FW-AM-1: AMS getMemoryInfo + onLocaleChanged; ActiveServices hide BS services
set +u
python3 - <<'PY'
from pathlib import Path

base = Path.home() / "aosp16/frameworks/base"

# ========== ActivityManagerService ==========
p = base / "services/core/java/com/android/server/am/ActivityManagerService.java"
t = p.read_text()
if "A16DBG:P2:FW-AM" in t:
    print("AMS already has FW-AM markers")
else:
    if "import android.util.BstUtils;" not in t:
        t = t.replace("import android.util.ArraySet;\n", "import android.util.ArraySet;\nimport android.util.BstUtils;\n", 1)
    if "import com.bluestacks.os.BstFilterAppsManager;" not in t:
        t = t.replace(
            "import java.util.concurrent.atomic.AtomicInteger;\n",
            "import java.util.concurrent.atomic.AtomicInteger;\n\n"
            "import com.bluestacks.os.BstFilterAppsManager;\n"
            "import com.bluestacks.os.BstHostCallManager;\n",
            1,
        )
    if "BstFilterAppsManager mBstFilterApps;" not in t:
        t = t.replace(
            "    private Installer mInstaller;\n",
            "    private Installer mInstaller;\n\n"
            "    BstFilterAppsManager mBstFilterApps;\n\n"
            "    BstHostCallManager mBstHostCallManagerService;\n",
            1,
        )

    old_mem = """    public void getMemoryInfo(ActivityManager.MemoryInfo outInfo) {
        mProcessList.getMemoryInfo(outInfo);
    }
"""
    new_mem = """    public void getMemoryInfo(ActivityManager.MemoryInfo outInfo) {
        mProcessList.getMemoryInfo(outInfo);
        // A16DBG:P2:FW-AM getMemoryInfo — per-uid fake totalMem from FilterApps (a13)
        try {
            if (mBstFilterApps == null) {
                mBstFilterApps = (BstFilterAppsManager) mContext
                        .getSystemService(Context.BST_FILTER_APPS);
            }
            if (mBstFilterApps != null) {
                final int uid = Binder.getCallingUid();
                final String memorySize = mBstFilterApps.getMemorySize(uid);
                if (memorySize != null && !memorySize.isEmpty()) {
                    long fakeTotalMem = 0L;
                    try {
                        fakeTotalMem = Long.parseLong(memorySize);
                    } catch (Exception e) {
                        Slog.w(TAG, "A16DBG:P2:FW-AM getMemoryInfo parse: " + e);
                    }
                    if (fakeTotalMem > 0 && outInfo.totalMem < fakeTotalMem) {
                        outInfo.totalMem = fakeTotalMem;
                        Slog.i(TAG, "A16DBG:P2:FW-AM getMemoryInfo uid=" + uid
                                + " fakeTotalMem=" + fakeTotalMem);
                    }
                }
            }
        } catch (RuntimeException e) {
            Slog.w(TAG, "A16DBG:P2:FW-AM getMemoryInfo: " + e);
        }
    }
"""
    if old_mem not in t:
        raise SystemExit("getMemoryInfo anchor missing")
    t = t.replace(old_mem, new_mem, 1)

    old_loc = """                    broadcastIntentLocked(null, null, null, intent, null, null, 0, null, null, null,
                            null, null, OP_NONE, bOptions.toBundle(), false, false, MY_PID,
                            SYSTEM_UID, Binder.getCallingUid(), Binder.getCallingPid(),
                            UserHandle.USER_ALL);
                }

                // Send a broadcast to PackageInstallers if the configuration change is interesting
"""
    new_loc = """                    broadcastIntentLocked(null, null, null, intent, null, null, 0, null, null, null,
                            null, null, OP_NONE, bOptions.toBundle(), false, false, MY_PID,
                            SYSTEM_UID, Binder.getCallingUid(), Binder.getCallingPid(),
                            UserHandle.USER_ALL);
                    // A16DBG:P2:FW-AM onLocaleChanged → host
                    try {
                        if (mBstHostCallManagerService == null) {
                            mBstHostCallManagerService = (BstHostCallManager) mContext
                                    .getSystemService(Context.BST_HOST_CALL);
                        }
                        if (mBstHostCallManagerService != null) {
                            mBstHostCallManagerService.onLocaleChanged(
                                    SystemProperties.get("persist.sys.locale"));
                        }
                    } catch (RuntimeException e) {
                        Slog.w(TAG, "A16DBG:P2:FW-AM onLocaleChanged: " + e);
                    }
                }

                // Send a broadcast to PackageInstallers if the configuration change is interesting
"""
    if old_loc not in t:
        raise SystemExit("locale anchor missing")
    t = t.replace(old_loc, new_loc, 1)
    p.write_text(t)
    print("AMS patched")

# ========== ActiveServices ==========
p = base / "services/core/java/com/android/server/am/ActiveServices.java"
t = p.read_text()
if "A16DBG:P2:FW-AM hideBsService" in t:
    print("ActiveServices already patched")
else:
    if "import android.util.BstUtils;" not in t:
        t = t.replace("import android.util.ArraySet;\n", "import android.util.ArraySet;\nimport android.util.BstUtils;\n", 1)

    # helper method before getRunningServiceInfoLocked
    helper = '''
    /** A16DBG:P2:FW-AM hideBsService — a13: hide com.bluestacks.* from 3p getRunningServices */
    private boolean bstShouldHideServiceLocked(ServiceRecord sr, int uid, String callingPackage) {
        return sr != null && sr.processName != null && sr.processName.startsWith("com.bluestacks")
                && uid >= 10000
                && callingPackage != null
                && !callingPackage.startsWith("com.bluestacks")
                && (callingPackage.equalsIgnoreCase("com.android.vending")
                    || !callingPackage.startsWith("com.android"));
    }

'''
    anchor = "    List<ActivityManager.RunningServiceInfo> getRunningServiceInfoLocked(int maxNum, int flags,\n"
    if anchor not in t:
        raise SystemExit("getRunningServiceInfoLocked anchor missing")
    t = t.replace(anchor, helper + anchor, 1)

    old = """    List<ActivityManager.RunningServiceInfo> getRunningServiceInfoLocked(int maxNum, int flags,
        int callingUid, boolean allowed, boolean canInteractAcrossUsers) {
        ArrayList<ActivityManager.RunningServiceInfo> res
                = new ArrayList<ActivityManager.RunningServiceInfo>();

        final long ident = mAm.mInjector.clearCallingIdentity();
        try {
            if (canInteractAcrossUsers) {
                int[] users = mAm.mUserController.getUsers();
                for (int ui=0; ui<users.length && res.size() < maxNum; ui++) {
                    ArrayMap<ComponentName, ServiceRecord> alls = getServicesLocked(users[ui]);
                    for (int i=0; i<alls.size() && res.size() < maxNum; i++) {
                        ServiceRecord sr = alls.valueAt(i);
                        res.add(makeRunningServiceInfoLocked(sr));
                    }
                }

                for (int i=0; i<mRestartingServices.size() && res.size() < maxNum; i++) {
                    ServiceRecord r = mRestartingServices.get(i);
                    ActivityManager.RunningServiceInfo info =
                            makeRunningServiceInfoLocked(r);
                    info.restarting = r.nextRestartTime;
                    res.add(info);
                }
            } else {
                int userId = UserHandle.getUserId(callingUid);
                ArrayMap<ComponentName, ServiceRecord> alls = getServicesLocked(userId);
                for (int i=0; i<alls.size() && res.size() < maxNum; i++) {
                    ServiceRecord sr = alls.valueAt(i);

                    if (allowed || (sr.app != null && sr.app.uid == callingUid)) {
                        res.add(makeRunningServiceInfoLocked(sr));
                    }
                }

                for (int i=0; i<mRestartingServices.size() && res.size() < maxNum; i++) {
                    ServiceRecord r = mRestartingServices.get(i);
                    if (r.userId == userId
                        && (allowed || (r.app != null && r.app.uid == callingUid))) {
                        ActivityManager.RunningServiceInfo info =
                                makeRunningServiceInfoLocked(r);
                        info.restarting = r.nextRestartTime;
                        res.add(info);
                    }
                }
            }
"""
    new = """    List<ActivityManager.RunningServiceInfo> getRunningServiceInfoLocked(int maxNum, int flags,
        int callingUid, boolean allowed, boolean canInteractAcrossUsers) {
        ArrayList<ActivityManager.RunningServiceInfo> res
                = new ArrayList<ActivityManager.RunningServiceInfo>();

        // A16DBG:P2:FW-AM hideBsService
        final String bstCallingPackage = BstUtils.getAppNameFromPid(Binder.getCallingPid());
        final long ident = mAm.mInjector.clearCallingIdentity();
        try {
            if (canInteractAcrossUsers) {
                int[] users = mAm.mUserController.getUsers();
                for (int ui=0; ui<users.length && res.size() < maxNum; ui++) {
                    ArrayMap<ComponentName, ServiceRecord> alls = getServicesLocked(users[ui]);
                    for (int i=0; i<alls.size() && res.size() < maxNum; i++) {
                        ServiceRecord sr = alls.valueAt(i);
                        if (bstShouldHideServiceLocked(sr, callingUid, bstCallingPackage)) {
                            continue;
                        }
                        res.add(makeRunningServiceInfoLocked(sr));
                    }
                }

                for (int i=0; i<mRestartingServices.size() && res.size() < maxNum; i++) {
                    ServiceRecord r = mRestartingServices.get(i);
                    if (bstShouldHideServiceLocked(r, callingUid, bstCallingPackage)) {
                        continue;
                    }
                    ActivityManager.RunningServiceInfo info =
                            makeRunningServiceInfoLocked(r);
                    info.restarting = r.nextRestartTime;
                    res.add(info);
                }
            } else {
                int userId = UserHandle.getUserId(callingUid);
                ArrayMap<ComponentName, ServiceRecord> alls = getServicesLocked(userId);
                for (int i=0; i<alls.size() && res.size() < maxNum; i++) {
                    ServiceRecord sr = alls.valueAt(i);
                    if (bstShouldHideServiceLocked(sr, callingUid, bstCallingPackage)) {
                        continue;
                    }

                    if (allowed || (sr.app != null && sr.app.uid == callingUid)) {
                        res.add(makeRunningServiceInfoLocked(sr));
                    }
                }

                for (int i=0; i<mRestartingServices.size() && res.size() < maxNum; i++) {
                    ServiceRecord r = mRestartingServices.get(i);
                    if (bstShouldHideServiceLocked(r, callingUid, bstCallingPackage)) {
                        continue;
                    }
                    if (r.userId == userId
                        && (allowed || (r.app != null && r.app.uid == callingUid))) {
                        ActivityManager.RunningServiceInfo info =
                                makeRunningServiceInfoLocked(r);
                        info.restarting = r.nextRestartTime;
                        res.add(info);
                    }
                }
            }
"""
    if old not in t:
        raise SystemExit("ActiveServices body anchor missing")
    t = t.replace(old, new, 1)
    # need Binder import?
    if "import android.os.Binder;" not in t and "android.os.Binder" not in t[:5000]:
        # Binder often already used via full name elsewhere; we used Binder.getCallingPid
        if "import android.os.UserHandle;" in t:
            t = t.replace("import android.os.UserHandle;\n", "import android.os.Binder;\nimport android.os.UserHandle;\n", 1)
    p.write_text(t)
    print("ActiveServices patched")

print("VERIFY:")
for f in [
    "services/core/java/com/android/server/am/ActivityManagerService.java",
    "services/core/java/com/android/server/am/ActiveServices.java",
]:
    path = base / f
    for i, l in enumerate(path.read_text().splitlines(), 1):
        if "A16DBG:P2:FW-AM" in l:
            print(f"  {f}:{i}:{l[:100]}")
PY
