#!/usr/bin/env python3
"""R255: Port A13 WMS bstSendTopDisplayedOnFocusChange → A16.

Without this, guest never calls BstHostCallManager.onActivityDisplayed →
host never gets hcallOnActivityDisplayed → Player stays StartingAndroid
even after sys.boot_completed=1.
"""
from pathlib import Path
import sys

AOSP = Path.home() / "aosp16"
WMS = AOSP / "frameworks/base/services/core/java/com/android/server/wm/WindowManagerService.java"
DC = AOSP / "frameworks/base/services/core/java/com/android/server/wm/DisplayContent.java"
A13_WMS = Path.home() / "app-player/android-13/frameworks/base/services/core/java/com/android/server/wm/WindowManagerService.java"
# Henry tree may live under /home/henry
if not A13_WMS.exists():
    A13_WMS = Path("/home/henry/workspace/app-player/android-13/frameworks/base/services/core/java/com/android/server/wm/WindowManagerService.java")

MARKER = "R255 / Henry bstSendTopDisplayedOnFocusChange"


def patch_wms():
    text = WMS.read_text()
    if MARKER in text:
        print(f"WMS already patched: {WMS}")
        return

    if "bstSendTopDisplayedOnFocusChange" in text:
        print("WMS already has bstSendTopDisplayedOnFocusChange")
        return

    # --- imports ---
    if "import com.bluestacks.os.BstHostCallManager;" not in text:
        needle = "import java.util.function.Supplier;"
        insert = (
            "import java.util.function.Supplier;\n"
            "\n"
            "import android.accounts.Account;\n"
            "import android.accounts.AccountManager;\n"
            "\n"
            "import com.bluestacks.os.BstFilterAppsManager;\n"
            "import com.bluestacks.os.BstHostCallManager;\n"
        )
        if needle not in text:
            raise SystemExit("import needle missing")
        text = text.replace(needle, insert, 1)

    # --- fields ---
    if "mBstHostCallManagerService" not in text:
        needle = "    final ActivityTaskManagerService mAtmService;\n"
        insert = (
            "    final ActivityTaskManagerService mAtmService;\n"
            "    // R255 / Henry bstSendTopDisplayedOnFocusChange\n"
            "    final BstFilterAppsManager mBstFilterApps;\n"
            "    final BstHostCallManager mBstHostCallManagerService;\n"
        )
        if needle not in text:
            raise SystemExit("field needle missing")
        text = text.replace(needle, insert, 1)

    # --- ctor init ---
    if "mBstHostCallManagerService =" not in text:
        needle = (
            "        mTransaction = mTransactionFactory.get();\n"
            "\n"
            "        mPolicy = policy;\n"
        )
        insert = (
            "        mTransaction = mTransactionFactory.get();\n"
            "\n"
            "        // R255 / Henry bstSendTopDisplayedOnFocusChange\n"
            "        mBstFilterApps = (BstFilterAppsManager) context.getSystemService(Context.BST_FILTER_APPS);\n"
            "        mBstHostCallManagerService = (BstHostCallManager) context.getSystemService(Context.BST_HOST_CALL);\n"
            "\n"
            "        mPolicy = policy;\n"
        )
        if needle not in text:
            raise SystemExit("ctor needle missing")
        text = text.replace(needle, insert, 1)

    # --- method body from A13 ---
    a13 = A13_WMS.read_text()
    start = a13.find("    void bstSendTopDisplayedOnFocusChange(WindowState newFocus) {")
    end = a13.find("    boolean updateFocusedWindowLocked(int mode, boolean updateInputWindows) {", start)
    if start < 0 or end < 0:
        raise SystemExit("A13 method bounds not found")
    method = a13[start:end]
    # Annotate
    method = (
        "    // R255 / Henry bstSendTopDisplayedOnFocusChange — notify host of top activity\n"
        + method
    )

    needle = "    boolean updateFocusedWindowLocked(int mode, boolean updateInputWindows) {"
    if needle not in text:
        raise SystemExit("updateFocusedWindowLocked needle missing")
    text = text.replace(needle, method + needle, 1)

    WMS.write_text(text)
    print(f"patched WMS {WMS}")


def patch_dc():
    text = DC.read_text()
    if MARKER in text or "bstSendTopDisplayedOnFocusChange" in text:
        print(f"DisplayContent already patched: {DC}")
        return

    needle = (
        "        getDisplayPolicy().focusChangedLw(oldFocus, newFocus);\n"
        "        mAtmService.mBackNavigationController.onFocusChanged(newFocus);\n"
    )
    insert = (
        "        getDisplayPolicy().focusChangedLw(oldFocus, newFocus);\n"
        "        mAtmService.mBackNavigationController.onFocusChanged(newFocus);\n"
        "\n"
        "        // R255 / Henry bstSendTopDisplayedOnFocusChange\n"
        "        // Sending the top displayed activity info to host on Focus change.\n"
        "        if (newFocus != null) {\n"
        "            mWmService.bstSendTopDisplayedOnFocusChange(newFocus);\n"
        "        }\n"
    )
    if needle not in text:
        raise SystemExit("DisplayContent needle missing")
    DC.write_text(text.replace(needle, insert, 1))
    print(f"patched DisplayContent {DC}")


def main():
    patch_wms()
    patch_dc()
    # readback
    w = WMS.read_text()
    d = DC.read_text()
    assert "bstSendTopDisplayedOnFocusChange" in w
    assert "bstSendTopDisplayedOnFocusChange" in d
    assert "mBstHostCallManagerService" in w
    print("R255_PATCH_OK")


if __name__ == "__main__":
    main()
