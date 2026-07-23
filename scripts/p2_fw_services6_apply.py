#!/usr/bin/env python3
# P2-FW-SERVICES-6: InputMethodManagerService — BST host IME-change notify (bounded subset of a13 IMMS).
# a16 IMMS heavily refactored (bindingController/Lifecycle/deviceId); full 12-hunk a13 port needs
# dedicated per-hunk adaptation. This bounded subset ports the clean, functional onImeChange host-notify
# (host learns when active IME changes — needed for keyboard mapping). Lazy-init BstHostCallManager
# (same pattern as cont.45 ClipboardService / cont.48 AccountManagerService) avoids the restructured
# constructor init anchor. system_server peripheral. Robust exact-string replace.
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

patch("services/core/java/com/android/server/inputmethod/InputMethodManagerService.java", [
    # import BstHostCallManager (group with com.* after PriorityDump)
    ("import com.android.server.utils.PriorityDump;\n",
     "import com.android.server.utils.PriorityDump;\n"
     "import com.bluestacks.os.BstHostCallManager;\n"),
    # field (lazy-init, no constructor init — avoids restructured a16 ctor)
    ('    private static final String PACKAGE_MONITOR_THREAD_NAME = "android.imms2";\n',
     '    private static final String PACKAGE_MONITOR_THREAD_NAME = "android.imms2";\n\n'
     '    // A16DBG:P2:FW-SERVICES-6 BST host IME-change notify (a13; lazy-init BstHostCallManager)\n'
     '    private BstHostCallManager mBstHostCallManagerService;\n'),
    # onImeChange: lazy-init + notify host after the INPUT_METHOD_CHANGED broadcast
    ("                mContext.sendBroadcastAsUser(intent, UserHandle.CURRENT);\n",
     "                mContext.sendBroadcastAsUser(intent, UserHandle.CURRENT);\n"
     "                // A16DBG:P2:FW-SERVICES-6 BST notify host of active IME change (a13)\n"
     "                if (mBstHostCallManagerService == null) {\n"
     "                    mBstHostCallManagerService = (BstHostCallManager)\n"
     "                            mContext.getSystemService(Context.BST_HOST_CALL);\n"
     "                }\n"
     "                if (mBstHostCallManagerService != null) {\n"
     "                    mBstHostCallManagerService.onImeChange(id);\n"
     "                }\n"),
], "InputMethodManagerService.onImeChange host notify")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
