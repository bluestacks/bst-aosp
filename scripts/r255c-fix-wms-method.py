#!/usr/bin/env python3
"""R255c: replace bstSendTopDisplayedOnFocusChange with owningPackage fallback."""
from pathlib import Path

WMS = Path.home() / "aosp16/frameworks/base/services/core/java/com/android/server/wm/WindowManagerService.java"
text = WMS.read_text()
start = text.find("    void bstSendTopDisplayedOnFocusChange(WindowState newFocus) {")
if start < 0:
    raise SystemExit("method not found")
# include preceding R255 comment block
c = text.rfind("    // R255", 0, start)
if c > 0:
    start = c
end = text.find("    boolean updateFocusedWindowLocked(int mode, boolean updateInputWindows) {", start)
if end < 0:
    raise SystemExit("end not found")

body = r'''    // R255 / Henry bstSendTopDisplayedOnFocusChange — notify host of top activity
    // Fallback to WindowState.getOwningPackage when mActivityRecord is null.
    void bstSendTopDisplayedOnFocusChange(WindowState newFocus) {
        if (newFocus == null) {
            return;
        }
        BstHostCallManager hostCall = mBstHostCallManagerService;
        if (hostCall == null) {
            try {
                hostCall = (BstHostCallManager) mContext.getSystemService(Context.BST_HOST_CALL);
            } catch (Exception e) {
                Slog.w(TAG, "R255: BST_HOST_CALL unavailable: " + e);
                return;
            }
            if (hostCall == null) {
                Slog.w(TAG, "R255: BstHostCallManager is null");
                return;
            }
        }

        String packageName = null;
        String activityName = null;
        final ActivityRecord activityRecord = newFocus.mActivityRecord;
        if (activityRecord != null) {
            packageName = activityRecord.packageName;
            if (activityRecord.mActivityComponent != null) {
                activityName = activityRecord.mActivityComponent.getClassName();
            } else if (activityRecord.intent != null
                    && activityRecord.intent.getComponent() != null) {
                activityName = activityRecord.intent.getComponent().getClassName();
            }
        }
        if (packageName == null || packageName.isEmpty()) {
            packageName = newFocus.getOwningPackage();
        }
        if (packageName == null || packageName.isEmpty()) {
            return;
        }
        if (activityName == null || activityName.isEmpty()) {
            activityName = packageName + "/.R255Focus";
        }
        if (activityName.equalsIgnoreCase("com.android.settings.FallbackHome")) {
            return;
        }

        final String lastTopDisplayedPackage =
                SystemProperties.get("bst.config.top_displayed_pkg", "");
        if (packageName.equalsIgnoreCase(lastTopDisplayedPackage)) {
            return;
        }

        try {
            SystemProperties.set("bst.r255.last_pkg", packageName);
            Slog.w(TAG, "R255 onActivityDisplayed package=" + packageName
                    + " activity=" + activityName);
            SystemProperties.set("bst.config.top_displayed_pkg", packageName);
            SystemProperties.set("bst.config.show_mouse_ptr", "false");
            String callingPackage = SystemProperties.get("bst.config.calling_package", "");
            int rval = hostCall.onActivityDisplayed(packageName, activityName, callingPackage);
            if (rval != 0) {
                Slog.w(TAG, "R255 onActivityDisplayed rval=" + rval);
            }
        } catch (Exception ex) {
            Slog.w(TAG, "R255 bstSendTopDisplayedOnFocusChange failed: " + ex);
        }
    }

'''
WMS.write_text(text[:start] + body + text[end:])
# sanity
t = WMS.read_text()
assert '\\ R255' not in t
assert 'packageName + "/.R255Focus"' in t
print("R255C_SOURCE_OK")
