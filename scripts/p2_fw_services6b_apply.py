#!/usr/bin/env python3
# P2-FW-SERVICES-6b: IMMS text-edit-mode host sync (bstSendSetInputMapperStatusAsync) + show/hide wiring.
# Continues IMMS (6a did onImeChange). a16 IMMS lacks mCurAttribute, so the a13 password-detection
# block is omitted; the core text-edit-mode host sync (isIMEDisabled gate + onTextEditModeChange) is
# ported — the keyboard-mapping essential. Lazy-init mBstFilterAppsManager + mBstHostCallManagerService.
# system_server peripheral. Robust exact-string replace.
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

METHOD = '''
    // A16DBG:P2:FW-SERVICES-6b BST text-edit-mode host sync for keyboard mapping (a13; mCurAttribute
    // password-detect block omitted — field absent in a16; core isIMEDisabled gate + onTextEditModeChange kept)
    private void bstSendSetInputMapperStatusAsync(boolean ime_enabled) {
        String topActivityName = android.os.SystemProperties.get("bst.config.top_activity_name", null);
        if (topActivityName != null) {
            String[] parts = topActivityName.split("/");
            String packageName = parts[0];
            String activityName = parts.length > 1 ? parts[1] : null;
            if (mBstFilterAppsManager == null) {
                mBstFilterAppsManager = (BstFilterAppsManager)
                        mContext.getSystemService(Context.BST_FILTER_APPS);
            }
            if (mBstFilterAppsManager != null
                    && mBstFilterAppsManager.isIMEDisabled(packageName, activityName)) {
                ime_enabled = false;
            }
        }
        if (ime_enabled != bstWinKeyboardInputEnabled) {
            bstWinKeyboardInputEnabled = ime_enabled;
        } else {
            return;
        }
        if (mBstHostCallManagerService == null) {
            mBstHostCallManagerService = (BstHostCallManager)
                    mContext.getSystemService(Context.BST_HOST_CALL);
        }
        if (mBstHostCallManagerService != null) {
            mBstHostCallManagerService.onTextEditModeChange(bstWinKeyboardInputEnabled);
        }
    }

'''

patch("services/core/java/com/android/server/inputmethod/InputMethodManagerService.java", [
    # imports
    ("import com.android.server.utils.PriorityDump;\n",
     "import com.android.server.utils.PriorityDump;\n"
     "import com.bluestacks.os.BstFilterAppsManager;\n"),
    # fields (bstWinKeyboardInputEnabled + mBstFilterAppsManager lazy-init; mBstHostCallManagerService already from 6a)
    ('    private static final String PACKAGE_MONITOR_THREAD_NAME = "android.imms2";\n\n'
     '    // A16DBG:P2:FW-SERVICES-6 BST host IME-change notify (a13; lazy-init BstHostCallManager)\n'
     '    private BstHostCallManager mBstHostCallManagerService;\n',
     '    private static final String PACKAGE_MONITOR_THREAD_NAME = "android.imms2";\n\n'
     '    // A16DBG:P2:FW-SERVICES-6 BST host IME-change notify (a13; lazy-init BstHostCallManager)\n'
     '    private BstHostCallManager mBstHostCallManagerService;\n'
     '    // A16DBG:P2:FW-SERVICES-6b BST text-edit-mode (a13; lazy-init)\n'
     '    private static boolean bstWinKeyboardInputEnabled = true;\n'
     '    private BstFilterAppsManager mBstFilterAppsManager;\n'),
    # method definition before showCurrentInputLocked + show call site
    ("    private boolean showCurrentInputLocked(IBinder windowToken,\n"
     "            @NonNull ImeTracker.Token statsToken, @SoftInputShowHideReason int reason,\n"
     "            @UserIdInt int userId) {\n",
     METHOD +
     "    private boolean showCurrentInputLocked(IBinder windowToken,\n"
     "            @NonNull ImeTracker.Token statsToken, @SoftInputShowHideReason int reason,\n"
     "            @UserIdInt int userId) {\n"
     "        // A16DBG:P2:FW-SERVICES-6b BST enable text-edit-mode on show (a13)\n"
     "        bstSendSetInputMapperStatusAsync(true);\n"),
    # hide call site
    ("    private boolean hideCurrentInputLocked(IBinder windowToken,\n"
     "            @NonNull ImeTracker.Token statsToken, @SoftInputShowHideReason int reason,\n"
     "            @UserIdInt int userId) {\n",
     "    private boolean hideCurrentInputLocked(IBinder windowToken,\n"
     "            @NonNull ImeTracker.Token statsToken, @SoftInputShowHideReason int reason,\n"
     "            @UserIdInt int userId) {\n"
     "        // A16DBG:P2:FW-SERVICES-6b BST disable text-edit-mode on hide (a13)\n"
     "        bstSendSetInputMapperStatusAsync(false);\n"),
], "InputMethodManagerService text-edit-mode + show/hide")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
