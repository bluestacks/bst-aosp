#!/usr/bin/env python3
# P2-FW-CORE-APP-1: surgical BST hooks (a13 -> a16) for 3 app-framework files.
# Additive hooks depending only on already-present BST infra (BstUtils / BstFilterAppsManager /
# BstUtilsManager + Context.BST_* constants). Robust exact-string replacement (line# agnostic).
# Run on clouddev: python3 scripts/p2_fw_coreapp1_apply.py  (after scp)
# Restorable: resulting `git diff` captured into patches/android-16/patches/p2-framework-rest/.
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
        ERRS.append(f"{label}: no change applied"); return
    with open(full, "w") as f: f.write(src)
    print(f"OK   {label}")

# 1) AccessibilityManager — hide BST accessibility services from 3rd-party detection (a13).
patch("core/java/android/view/accessibility/AccessibilityManager.java", [
    ("import android.os.Binder;\n",
     "import android.os.Binder;\nimport android.util.BstUtils;\n"),
    ("""        if (mAccessibilityPolicy != null) {
            services = mAccessibilityPolicy.getEnabledAccessibilityServiceList(
                    feedbackTypeFlags, services);
        }
""",
     """        if (mAccessibilityPolicy != null) {
            services = mAccessibilityPolicy.getEnabledAccessibilityServiceList(
                    feedbackTypeFlags, services);
        }
        // A16DBG:P2:FW-CORE-APP hide BST accessibility svcs from 3rd-party detection (a13)
        services = BstUtils.filterHiddenServices(services, Binder.getCallingUid());
"""),
], "AccessibilityManager.filterHiddenServices")

# 2) EditText — ROB-11067 block setText while IME is composing (a13).
patch("core/java/android/widget/EditText.java", [
    ("import android.util.AttributeSet;\n",
     "import android.util.AttributeSet;\nimport android.util.BstUtils;\n"
     "import android.os.Binder;\n\nimport com.bluestacks.os.BstFilterAppsManager;\n"),
    ("""    @Override
    public void setText(CharSequence text, BufferType type) {
        super.setText(text, BufferType.EDITABLE);
    }
""",
     """    @Override
    public void setText(CharSequence text, BufferType type) {
        // A16DBG:P2:FW-CORE-APP ROB-11067 block setText while IME composing (a13)
        boolean isComposing = android.os.SystemProperties.getInt("bst.ime_is_composing", 0) == 1;
        if (isComposing) {
            int uid = Binder.getCallingUid();
            if (uid >= 10000) {
                String packageName = BstUtils.getAppNameFromPid(Binder.getCallingPid());
                BstFilterAppsManager bstfilter = BstFilterAppsManager.getInstance();
                if (bstfilter.isBlockEditWhenComposing(packageName)) {
                    return;
                }
            }
        }
        super.setText(text, BufferType.EDITABLE);
    }
"""),
], "EditText.ROB-11067 composing block")

# 3) InputMethodService — BST soft-keyboard toggle (a13). Defensive null-fallback to config.
patch("core/java/android/inputmethodservice/InputMethodService.java", [
    ("import java.util.concurrent.Executor;\n",
     "import java.util.concurrent.Executor;\nimport com.bluestacks.os.BstUtilsManager;\n"),
    ("""        Configuration config = getResources().getConfiguration();
        return config.keyboard == Configuration.KEYBOARD_NOKEYS
                || config.hardKeyboardHidden == Configuration.HARDKEYBOARDHIDDEN_YES;
    }
""",
     """        Configuration config = getResources().getConfiguration();
        // A16DBG:P2:FW-CORE-APP BST soft-keyboard toggle (a13); fall back to config if svc absent
        BstUtilsManager mBstUtils = (BstUtilsManager) getSystemService(Context.BST_UTILS);
        if (mBstUtils != null) {
            return mBstUtils.isBstSoftKeyboardEnabled();
        }
        return config.keyboard == Configuration.KEYBOARD_NOKEYS
                || config.hardKeyboardHidden == Configuration.HARDKEYBOARDHIDDEN_YES;
    }
"""),
], "InputMethodService.BstSoftKeyboardEnabled")

if ERRS:
    print("\n=== ERRORS (no files changed beyond first failure per file) ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m framework` next")
