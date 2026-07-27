#!/usr/bin/env python3
# P2-FW-SERVICES-2: NMS host notification + IntentResolver/ComponentResolver hide BST pkgs.
import os
import sys

A16 = os.path.expanduser("~/aosp16/frameworks/base")
MARKER = "A16DBG:P2:FW-SERVICES-2"
ERRS = []


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
            ERRS.append(f"{label}: ANCHOR NOT FOUND: {old.strip()[:80]!r}")
            return
        if src.count(old) > 1:
            ERRS.append(
                f"{label}: ANCHOR NOT UNIQUE ({src.count(old)}): {old.strip()[:80]!r}"
            )
            return
        src = src.replace(old, new, 1)
    if src == orig:
        ERRS.append(f"{label}: no change")
        return
    with open(full, "w") as f:
        f.write(src)
    print(f"OK   {label}")


INTENT = "services/core/java/com/android/server/IntentResolver.java"
patch(
    INTENT,
    [
        (
            "    protected abstract boolean isPackageForFilter(String packageName, F filter);\n\n"
            "    protected abstract F[] newArray(int size);\n",
            "    protected abstract boolean isPackageForFilter(String packageName, F filter);\n\n"
            "    // A16DBG:P2:FW-SERVICES-2 — hook for hideBlueStacksPkg (override in ComponentResolver)\n"
            "    protected boolean isBluestacksFilter(F filter, List<R> dest) {\n"
            "        return false;\n"
            "    }\n\n"
            "    protected abstract F[] newArray(int size);\n",
        ),
        (
            "            if (debug) Slog.v(TAG, \"Matching against filter \" + filter);\n\n"
            "            if (excludingStopped && isFilterStopped(computer, filter, userId)) {\n",
            "            if (debug) Slog.v(TAG, \"Matching against filter \" + filter);\n\n"
            "            if (isBluestacksFilter(filter, dest)) {\n"
            "                if (debug) Slog.v(TAG, \"A16DBG:P2:FW-SERVICES-2 bluestacks filter skip \" + filter);\n"
            "                continue;\n"
            "            }\n\n"
            "            if (excludingStopped && isFilterStopped(computer, filter, userId)) {\n",
        ),
    ],
    "IntentResolver",
)

COMP = "services/core/java/com/android/server/pm/resolution/ComponentResolver.java"
patch(
    COMP,
    [
        (
            "import static com.android.server.pm.PackageManagerService.DEBUG_REMOVE;\n",
            "import static android.os.Trace.TRACE_TAG_PACKAGE_MANAGER;\n\n"
            "import static com.android.server.pm.PackageManagerService.DEBUG_REMOVE;\n",
        ),
        (
            "import android.content.IntentFilter;\n",
            "import android.content.Context;\n"
            "import android.content.IntentFilter;\n",
        ),
        (
            "import android.os.UserHandle;\n",
            "import android.os.Binder;\n"
            "import android.os.Process;\n"
            "import android.os.ServiceManager;\n"
            "import android.os.Trace;\n"
            "import android.os.UserHandle;\n",
        ),
        (
            "import android.util.Slog;\n",
            "import android.util.Slog;\n"
            "import android.util.BstUtils;\n",
        ),
        (
            "import com.android.server.IntentResolver;\n",
            "import com.android.server.IntentResolver;\n\n"
            "import com.bluestacks.os.IBstFilterAppsService;\n",
        ),
        (
            "    private static final boolean DEBUG_SHOW_INFO = false;\n",
            "    private static final boolean DEBUG_SHOW_INFO = false;\n\n"
            "    // A16DBG:P2:FW-SERVICES-2 hideBlueStacksPkg filter apps service\n"
            "    static IBstFilterAppsService mBstfilter;\n",
        ),
        (
            "            return true;\n"
            "        }\n\n"
            "        @Override\n"
            "        protected Pair<ParsedActivity, ParsedIntentInfo>[] newArray(int size) {\n",
            "            return true;\n"
            "        }\n\n"
            "        @Override\n"
            "        protected boolean isBluestacksFilter(\n"
            "                Pair<ParsedActivity, ParsedIntentInfo> filter, List<ResolveInfo> dest) {\n"
            "            Trace.traceBegin(TRACE_TAG_PACKAGE_MANAGER, \"isBluestacksFilter\");\n"
            "            try {\n"
            "                ParsedActivity parsedActivity = filter.first;\n"
            "                String packageName = parsedActivity.getPackageName();\n"
            "                int uid = Binder.getCallingUid();\n"
            "                if (uid >= Process.FIRST_APPLICATION_UID && packageName != null\n"
            "                        && packageName.startsWith(\"com.bluestacks\")) {\n"
            "                    if (uid != Process.SYSTEM_UID) {\n"
            "                        int pid = Binder.getCallingPid();\n"
            "                        String callingPackage = BstUtils.getAppNameFromPid(pid);\n"
            "                        boolean isHideFromPkg = false;\n"
            "                        try {\n"
            "                            if (mBstfilter == null) {\n"
            "                                mBstfilter = IBstFilterAppsService.Stub.asInterface(\n"
            "                                        ServiceManager.getService(Context.BST_FILTER_APPS));\n"
            "                            }\n"
            "                            isHideFromPkg = mBstfilter.isHideBstActivityInfo(callingPackage);\n"
            "                        } catch (Exception e) {\n"
            "                            Slog.w(TAG, \"A16DBG:P2:FW-SERVICES-2 isBluestacksFilter: \" + e);\n"
            "                        }\n"
            "                        if (isHideFromPkg) {\n"
            "                            boolean isAppPrivileged = BstUtils.bstIsCallingAppPrivileged(\n"
            "                                    uid, callingPackage);\n"
            "                            if (DEBUG_SHOW_INFO) {\n"
            "                                Log.v(TAG, \"A16DBG:P2:FW-SERVICES-2 pkg=\" + callingPackage\n"
            "                                        + \" query=\" + parsedActivity.getName());\n"
            "                            }\n"
            "                            if (BstUtils.hideBlueStacksPkg(packageName, isAppPrivileged)) {\n"
            "                                return true;\n"
            "                            }\n"
            "                        }\n"
            "                    }\n"
            "                }\n"
            "                return false;\n"
            "            } finally {\n"
            "                Trace.traceEnd(TRACE_TAG_PACKAGE_MANAGER);\n"
            "            }\n"
            "        }\n\n"
            "        @Override\n"
            "        protected Pair<ParsedActivity, ParsedIntentInfo>[] newArray(int size) {\n",
        ),
    ],
    "ComponentResolver",
)

NMS = "services/core/java/com/android/server/notification/NotificationManagerService.java"
SEND_TO_HOST = """
    // A16DBG:P2:FW-SERVICES-2 send non-system app notification metadata to host (a13)
    private void sendNotificationToHost(String pkgName, Notification notification,
            NotificationRecord nr) {
        if (notification.isGroupSummary()) {
            if (DBG) {
                Slog.d(TAG, "A16DBG:P2:FW-SERVICES-2 skip group summary");
            }
            return;
        }

        int progress = notification.extras.getInt(Notification.EXTRA_PROGRESS);
        int progressMax = notification.extras.getInt(Notification.EXTRA_PROGRESS_MAX);
        if (progress != 0 || progressMax != 0) {
            return;
        }

        if (nr.isUpdate && (nr.getImportance() <= IMPORTANCE_LOW)) {
            if (DBG) {
                Slog.d(TAG, "A16DBG:P2:FW-SERVICES-2 skip low importance update");
            }
            return;
        }

        PackageManager pm = getContext().getPackageManager();
        ApplicationInfo ai;
        try {
            ai = pm.getApplicationInfo(pkgName, PackageManager.GET_META_DATA);
            int mask = ApplicationInfo.FLAG_SYSTEM | ApplicationInfo.FLAG_UPDATED_SYSTEM_APP;
            if ((ai.flags & mask) != 0) {
                if (DBG) {
                    Slog.d(TAG, "A16DBG:P2:FW-SERVICES-2 skip system app: " + pkgName);
                }
                return;
            }
        } catch (Exception e) {
            Slog.e(TAG, "A16DBG:P2:FW-SERVICES-2 sendNotificationToHost: " + e.getMessage());
            return;
        }

        String appName = pm.getApplicationLabel(ai).toString();
        String contentTitle = notification.extras.getCharSequence(
                Notification.EXTRA_TITLE, "").toString();
        String contentText = notification.extras.getCharSequence(
                Notification.EXTRA_TEXT, "").toString();
        long mSecs = notification.when;
        String notificationData;
        try {
            JSONObject json = new JSONObject();
            json.put("packageName", pkgName);
            json.put("appName", appName);
            json.put("contentTitle", contentTitle);
            json.put("contentText", contentText);
            json.put("mSecsFromEpochUTC", mSecs);
            notificationData = json.toString();
        } catch (Exception e) {
            Slog.e(TAG, "A16DBG:P2:FW-SERVICES-2 notification JSON: " + e.getMessage());
            return;
        }

        if (DBG) {
            Slog.d(TAG, "A16DBG:P2:FW-SERVICES-2 host notification: " + notificationData);
        }
        if (mBstHostCallManagerService == null) {
            mBstHostCallManagerService = (BstHostCallManager) getContext().getSystemService(
                    Context.BST_HOST_CALL);
        }
        if (mBstHostCallManagerService == null) {
            Slog.w(TAG, "A16DBG:P2:FW-SERVICES-2 BST_HOST_CALL unavailable");
            return;
        }
        int rval = mBstHostCallManagerService.onAppNotificationReceived(notificationData);
        if (rval != 0) {
            Slog.w(TAG, "A16DBG:P2:FW-SERVICES-2 onAppNotificationReceived rval=" + rval);
        }
    }

"""

patch(
    NMS,
    [
        (
            "import com.android.internal.R;\n",
            "import com.android.internal.R;\n\n"
            "import com.bluestacks.os.BstHostCallManager;\n",
        ),
        (
            "    private Set<String> mMsgPkgsAllowedAsConvos = new HashSet();\n",
            "    private Set<String> mMsgPkgsAllowedAsConvos = new HashSet();\n"
            "    private BstHostCallManager mBstHostCallManagerService;\n",
        ),
        (
            "                    if (notification.getSmallIcon() != null) {\n"
            "                        NotificationRecordLogger.NotificationReported maybeReport =\n",
            "                    if (notification.getSmallIcon() != null) {\n"
            "                        sendNotificationToHost(pkg, notification, r);\n"
            "                        NotificationRecordLogger.NotificationReported maybeReport =\n",
        ),
        (
            "    }\n\n"
            "    /**\n"
            "     * Asynchronously notify all listeners about a posted (new or updated) notification. This\n"
            "     * should be called from {@link PostNotificationRunnable} to \"complete\" the post (since SysUI is\n",
            "    }\n\n"
            + SEND_TO_HOST
            + "    /**\n"
            "     * Asynchronously notify all listeners about a posted (new or updated) notification. This\n"
            "     * should be called from {@link PostNotificationRunnable} to \"complete\" the post (since SysUI is\n",
        ),
    ],
    "NotificationManagerService",
)

if ERRS:
    for e in ERRS:
        print(f"ERROR {e}", file=sys.stderr)
    sys.exit(1)

for rel in (INTENT, COMP, NMS):
    n = sum(1 for line in open(os.path.join(A16, rel)) if MARKER in line)
    print(f"VERIFY {rel}: {n} marker lines")
