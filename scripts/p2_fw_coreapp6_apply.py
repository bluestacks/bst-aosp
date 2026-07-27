#!/usr/bin/env python3
# P2-FW-CORE-APP-6: Editor cursor hostcall + TextView Google IAP hack (a13->a16).
import os, sys

A16 = os.path.expanduser("~/aosp16/frameworks/base")
ERRS = []


def patch(rel, replacements, label):
    full = os.path.join(A16, rel)
    with open(full) as f:
        src = f.read()
    orig = src
    for old, new in replacements:
        if old not in src:
            ERRS.append(f"{label}: ANCHOR NOT FOUND: {old.strip()[:70]!r}")
            return
        if src.count(old) > 1:
            ERRS.append(
                f"{label}: ANCHOR NOT UNIQUE ({src.count(old)}): {old.strip()[:70]!r}"
            )
            return
        src = src.replace(old, new, 1)
    if src == orig:
        ERRS.append(f"{label}: no change")
        return
    with open(full, "w") as f:
        f.write(src)
    print(f"OK   {label}")


BST_SEND_CURSOR = """
    // A16DBG:P2:FW-CORE-APP-6 send cursor position to host (a13 text_mode)
    void bstSendCursorLocation() {
        if (mBlink == null) {
            return;
        }
        Layout layout = mTextView.getLayout();
        boolean isTextEditModeEnabled = SystemProperties.getBoolean(
                "bst.config.text_mode_enabled", false);
        if (BST_DEBUG) {
            Log.d(TAG, "A16DBG:P2:FW-CORE-APP-6 text_mode=" + isTextEditModeEnabled
                    + " prev=(" + mBlink.mBstPrevCursorX + "," + mBlink.mBstPrevCursorY + ")");
        }
        if (mTextView != null && layout != null && mBlink.mBstIsBlinking && isTextEditModeEnabled
                && mBstHostCallManagerService != null) {
            int[] cursorXY = new int[2];
            mTextView.getLocationOnScreen(cursorXY);
            final int offset = mTextView.getSelectionStart();
            final int transformedOffset = mTextView.originalToTransformed(offset,
                    OffsetMapping.MAP_STRATEGY_CURSOR);
            final int line = layout.getLineForOffset(transformedOffset);
            final float insertionMarkerX = layout.getPrimaryHorizontal(transformedOffset,
                    layout.shouldClampCursor(line)) + mTextView.viewportToContentHorizontalOffset();
            final float insertionMarkerBottom = layout.getLineBottom(line,
                    /* includeLineSpacing= */ false) + mTextView.viewportToContentVerticalOffset();
            cursorXY[0] = cursorXY[0] + (int) Math.ceil(insertionMarkerX);
            cursorXY[1] = cursorXY[1] + (int) Math.ceil(insertionMarkerBottom);
            if (mBlink.mBstPrevCursorX != cursorXY[0] || mBlink.mBstPrevCursorY != cursorXY[1]) {
                mBstHostCallManagerService.onCursorLocationChanged(cursorXY[0], cursorXY[1]);
                mBlink.mBstPrevCursorX = cursorXY[0];
                mBlink.mBstPrevCursorY = cursorXY[1];
            }
        }
    }

"""

GIAP_METHOD = """
    // A16DBG:P2:FW-CORE-APP-6 Google IAP text capture for BstCommandProcessor (a13)
    private void performGoogleIAPHack(CharSequence text) {
        try {
            String currentActivity = SystemProperties.get("bst.config.top_activity_name", "");
            String giapActivityName = "com.google.android.finsky.billing.acquire.SheetUiBuilderHostActivity";
            String giapActivityName2 = SystemProperties.get("bst.config.giap_activity", giapActivityName);
            if (currentActivity != null && (currentActivity.contains(giapActivityName)
                    || currentActivity.contains(giapActivityName2))) {
                final int id = getId();
                final Resources r = getResources();
                if (id != NO_ID && id != 0 && r != null) {
                    String pkgname = r.getResourcePackageName(id);
                    String lastTopDisplayedPackage = SystemProperties.get(
                            "bst.config.last_displayed_pkg", "");
                    if (pkgname.startsWith("com.android.vending")
                            || pkgname.startsWith("com.google.android")) {
                        if (DEBUG_BST_IAP) {
                            Log.d(LOG_TAG_IAP, "setText IAP id=" + id + " text=" + text
                                    + " pkg=" + pkgname);
                        }
                        Intent intent = new Intent();
                        ComponentName cn = new ComponentName("com.bluestacks.BstCommandProcessor",
                                "com.bluestacks.BstCommandProcessor.BstCommandProcessorService");
                        intent.setAction("GIAPTextContent");
                        intent.setComponent(cn);
                        intent.putExtra("item_description", text.toString());
                        intent.putExtra("package", lastTopDisplayedPackage);
                        mContext.startService(intent);
                    }
                }
            }
        } catch (Exception e) {
            Log.w(LOG_TAG_IAP, "A16DBG:P2:FW-CORE-APP-6 GIAP: " + e.getMessage());
        }
    }

"""

patch(
    "core/java/android/widget/Editor.java",
    [
        (
            "import android.os.SystemClock;\n",
            "import android.os.SystemClock;\nimport android.os.SystemProperties;\n",
        ),
        (
            "import java.util.Objects;\n\n/**\n * Helper class used by TextView",
            "import java.util.Objects;\n\nimport com.bluestacks.os.BstHostCallManager;\n\n"
            "/**\n * Helper class used by TextView",
        ),
        (
            '    private static final String TAG = "Editor";\n    private static final boolean DEBUG_UNDO = false;\n',
            '    private static final String TAG = "Editor";\n'
            '    private static final boolean BST_DEBUG = SystemProperties.getInt("bst.debug.editor", 0) > 0;\n'
            "    private static final boolean DEBUG_UNDO = false;\n",
        ),
        (
            "    private final boolean mHapticTextHandleEnabled;\n    /** Handles OnBackInvokedCallback back dispatch */\n",
            "    private final boolean mHapticTextHandleEnabled;\n"
            "    private BstHostCallManager mBstHostCallManagerService;\n"
            "    /** Handles OnBackInvokedCallback back dispatch */\n",
        ),
        (
            "    public Editor(TextView textView) {\n        mTextView = textView;\n        // Synchronize the filter list",
            "    public Editor(TextView textView) {\n        mTextView = textView;\n"
            "        mBstHostCallManagerService = (BstHostCallManager) mTextView.getContext()\n"
            "                .getSystemService(Context.BST_HOST_CALL);\n        // Synchronize the filter list",
        ),
        (
            """        updateCursorPosition(top, bottom, layout.getPrimaryHorizontal(transformedOffset, clamped));
    }

    void refreshTextActionMode() {
""",
            """        updateCursorPosition(top, bottom, layout.getPrimaryHorizontal(transformedOffset, clamped));
        // A16DBG:P2:FW-CORE-APP-6
        bstSendCursorLocation();
    }

    void refreshTextActionMode() {
""",
        ),
        (
            """        mDrawableForCursor.setBounds(left, top - mTempRect.top, left + width,
                bottom + mTempRect.bottom);
    }

    /**
     * Return clamped position for the drawable. If the drawable is within the boundaries of the
""",
            """        mDrawableForCursor.setBounds(left, top - mTempRect.top, left + width,
                bottom + mTempRect.bottom);
    }
"""
            + BST_SEND_CURSOR
            + """
    /**
     * Return clamped position for the drawable. If the drawable is within the boundaries of the
""",
        ),
        (
            """    private class Blink implements Runnable {
        private boolean mCancelled;

        public void run() {
            if (mCancelled) {
                return;
            }

            mTextView.removeCallbacks(this);

            if (shouldBlink()) {
                if (mTextView.getLayout() != null) {
                    mTextView.invalidateCursorPath();
                }

                mTextView.postDelayed(this, mBlinkInterval);
            }
        }

        void cancel() {
            if (!mCancelled) {
                mTextView.removeCallbacks(this);
                mCancelled = true;
            }
        }

        void uncancel() {
            mCancelled = false;
        }
    }
""",
            """    private class Blink implements Runnable {
        private boolean mCancelled;
        private boolean mBstIsBlinking = false;
        private int mBstPrevCursorX = -1;
        private int mBstPrevCursorY = -1;

        public void run() {
            if (mCancelled) {
                return;
            }

            mTextView.removeCallbacks(this);

            if (shouldBlink()) {
                if (mTextView.getLayout() != null) {
                    mBstIsBlinking = true;
                    bstSendCursorLocation();
                    mTextView.invalidateCursorPath();
                }

                mTextView.postDelayed(this, mBlinkInterval);
            }
        }

        void cancel() {
            if (!mCancelled) {
                mTextView.removeCallbacks(this);
                mCancelled = true;
                mBstIsBlinking = false;
            }
        }

        void uncancel() {
            mCancelled = false;
        }
    }
""",
        ),
    ],
    "Editor cursor hostcall",
)

patch(
    "core/java/android/widget/TextView.java",
    [
        (
            "import android.content.ClipboardManager;\n",
            "import android.content.ClipboardManager;\nimport android.content.ComponentName;\n",
        ),
        (
            "import android.os.Process;\n",
            "import android.os.Process;\nimport android.os.SystemProperties;\n",
        ),
        (
            '    static final String LOG_TAG = "TextView";\n    static final boolean DEBUG_EXTRACT = false;\n',
            '    static final String LOG_TAG = "TextView";\n    static final String LOG_TAG_IAP = "TextView-GIAP";\n'
            '    static final boolean DEBUG_EXTRACT = false;\n'
            "    private static final boolean DEBUG_BST_IAP =\n"
            '            SystemProperties.getInt("bst.debug.iap", 0) > 0;\n',
        ),
        (
            """        mCharWrapper = null;
    }

    @UnsupportedAppUsage
    private void setText(CharSequence text, BufferType type,
                         boolean notifyBefore, int oldlen) {
        if (mEditor != null) {
            mEditor.beforeSetText();
        }
""",
            """        mCharWrapper = null;
    }

"""
            + GIAP_METHOD
            + """
    @UnsupportedAppUsage
    private void setText(CharSequence text, BufferType type,
                         boolean notifyBefore, int oldlen) {
        if (text != null && text.toString().trim().length() > 0) {
            performGoogleIAPHack(text);
        }
        if (mEditor != null) {
            mEditor.beforeSetText();
        }
""",
        ),
    ],
    "TextView GIAP hack",
)

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS:
        print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
