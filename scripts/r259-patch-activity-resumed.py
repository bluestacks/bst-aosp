#!/usr/bin/env python3
"""R259: notify host on ActivityRecord RESUMED + align WMS with Henry (require ActivityRecord)."""
from pathlib import Path

AOSP = Path.home() / "aosp16"
WMS = AOSP / "frameworks/base/services/core/java/com/android/server/wm/WindowManagerService.java"
AR = AOSP / "frameworks/base/services/core/java/com/android/server/wm/ActivityRecord.java"

WMS_METHOD = r'''    // R259 / Henry: require ActivityRecord (no owningPackage fallback for systemui chrome).
    // Also used by ActivityRecord RESUMED hook.
    void bstSendTopDisplayedOnFocusChange(WindowState newFocus) {
        if (newFocus == null) {
            return;
        }
        final ActivityRecord activityRecord = newFocus.mActivityRecord;
        if (activityRecord == null) {
            return;
        }
        bstNotifyActivityDisplayed(activityRecord);
    }

    void bstNotifyActivityDisplayed(ActivityRecord activityRecord) {
        if (activityRecord == null) {
            return;
        }
        BstHostCallManager hostCall = mBstHostCallManagerService;
        if (hostCall == null) {
            try {
                hostCall = (BstHostCallManager) mContext.getSystemService(Context.BST_HOST_CALL);
            } catch (Exception e) {
                Slog.w(TAG, "R259: BST_HOST_CALL unavailable: " + e);
                return;
            }
            if (hostCall == null) {
                return;
            }
        }

        String packageName = activityRecord.packageName;
        String activityName = null;
        if (activityRecord.mActivityComponent != null) {
            activityName = activityRecord.mActivityComponent.getClassName();
        } else if (activityRecord.intent != null
                && activityRecord.intent.getComponent() != null) {
            activityName = activityRecord.intent.getComponent().getClassName();
        }
        if (packageName == null || packageName.isEmpty()) {
            return;
        }
        if (activityName == null || activityName.isEmpty()) {
            activityName = packageName;
        }
        if (activityName.equalsIgnoreCase("com.android.settings.FallbackHome")) {
            return;
        }
        // Host already ignores these; skip to avoid polluting top_displayed_pkg.
        if (packageName.equals("android")
                || packageName.equals("com.android.systemui")
                || packageName.equals("com.android.settings")) {
            return;
        }

        final String lastTopDisplayedPackage =
                SystemProperties.get("bst.config.top_displayed_pkg", "");
        if (packageName.equalsIgnoreCase(lastTopDisplayedPackage)) {
            return;
        }

        try {
            SystemProperties.set("bst.r259.last_pkg", packageName);
            Slog.w(TAG, "R259 onActivityDisplayed package=" + packageName
                    + " activity=" + activityName);
            SystemProperties.set("bst.config.top_displayed_pkg", packageName);
            SystemProperties.set("bst.config.show_mouse_ptr", "false");
            String callingPackage = SystemProperties.get("bst.config.calling_package", "");
            int rval = hostCall.onActivityDisplayed(packageName, activityName, callingPackage);
            if (rval != 0) {
                Slog.w(TAG, "R259 onActivityDisplayed rval=" + rval);
            }
        } catch (Exception ex) {
            Slog.w(TAG, "R259 bstNotifyActivityDisplayed failed: " + ex);
        }
    }

'''


def patch_wms() -> None:
    text = WMS.read_text()
    if "R259 onActivityDisplayed" in text and "bstNotifyActivityDisplayed" in text:
        print(f"WMS already patched: {WMS}")
        return
    start = text.find("    void bstSendTopDisplayedOnFocusChange(WindowState newFocus) {")
    if start < 0:
        raise SystemExit("WMS method not found")
    # include preceding R255 comment if present
    c = text.rfind("    // R255", 0, start)
    if c > 0 and start - c < 300:
        start = c
    c2 = text.rfind("    // R259", 0, start)
    if c2 > 0 and start - c2 < 300:
        start = c2
    end = text.find("    boolean updateFocusedWindowLocked(int mode, boolean updateInputWindows) {", start)
    if end < 0:
        raise SystemExit("WMS end not found")
    WMS.write_text(text[:start] + WMS_METHOD + text[end:])
    print(f"patched WMS: {WMS}")


def patch_activity_record() -> None:
    text = AR.read_text()
    if "R259 bstNotifyActivityDisplayed" in text:
        print(f"ActivityRecord already patched: {AR}")
        return
    needle = """            case RESUMED:
                mAtmService.updateBatteryStats(this, true);
                mAtmService.updateActivityUsageStats(this, Event.ACTIVITY_RESUMED);
                // Fall through.
"""
    if needle not in text:
        raise SystemExit("RESUMED case not found")
    repl = """            case RESUMED:
                mAtmService.updateBatteryStats(this, true);
                mAtmService.updateActivityUsageStats(this, Event.ACTIVITY_RESUMED);
                // R259 bstNotifyActivityDisplayed: focus may stay on SystemUI;
                // notify host when a real activity becomes RESUMED.
                try {
                    mWmService.bstNotifyActivityDisplayed(this);
                } catch (Exception e) {
                    Slog.w(TAG, "R259 bstNotifyActivityDisplayed failed: " + e);
                }
                // Fall through.
"""
    AR.write_text(text.replace(needle, repl, 1))
    print(f"patched ActivityRecord: {AR}")


def main() -> None:
    patch_wms()
    patch_activity_record()
    print("R259_PATCH_OK")


if __name__ == "__main__":
    main()
