#!/usr/bin/env python3
# P2-FW-SERVICES-2b: NotificationManagerService host notify only (isolated bisect).
import os
import sys

A16 = os.path.expanduser("~/aosp16/frameworks/base")
MARKER = "A16DBG:P2:FW-SERVICES-2b"
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


NMS = "services/core/java/com/android/server/notification/NotificationManagerService.java"
SEND_TO_HOST = """
    // A16DBG:P2:FW-SERVICES-2b send non-system app notification metadata to host (a13)
    private void sendNotificationToHost(String pkgName, Notification notification,
            NotificationRecord nr) {
        if (notification.isGroupSummary()) {
            if (DBG) {
                Slog.d(TAG, "A16DBG:P2:FW-SERVICES-2b skip group summary");
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
                Slog.d(TAG, "A16DBG:P2:FW-SERVICES-2b skip low importance update");
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
                    Slog.d(TAG, "A16DBG:P2:FW-SERVICES-2b skip system app: " + pkgName);
                }
                return;
            }
        } catch (Exception e) {
            Slog.e(TAG, "A16DBG:P2:FW-SERVICES-2b sendNotificationToHost: " + e.getMessage());
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
            Slog.e(TAG, "A16DBG:P2:FW-SERVICES-2b notification JSON: " + e.getMessage());
            return;
        }

        if (DBG) {
            Slog.d(TAG, "A16DBG:P2:FW-SERVICES-2b host notification: " + notificationData);
        }
        if (mBstHostCallManagerService == null) {
            mBstHostCallManagerService = (BstHostCallManager) getContext().getSystemService(
                    Context.BST_HOST_CALL);
        }
        if (mBstHostCallManagerService == null) {
            Slog.w(TAG, "A16DBG:P2:FW-SERVICES-2b BST_HOST_CALL unavailable");
            return;
        }
        int rval = mBstHostCallManagerService.onAppNotificationReceived(notificationData);
        if (rval != 0) {
            Slog.w(TAG, "A16DBG:P2:FW-SERVICES-2b onAppNotificationReceived rval=" + rval);
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

print(f"VERIFY {MARKER}:", MARKER in open(os.path.join(A16, NMS)).read())
