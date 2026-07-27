#!/usr/bin/env python3
# P2-FW-SERVICES-1a: ClipboardService host sync only (isolated from Location batch).
import os
import sys

A16 = os.path.expanduser("~/aosp16/frameworks/base")
MARKER = "A16DBG:P2:FW-SERVICES-1a"
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


CLIPBOARD = "services/core/java/com/android/server/clipboard/ClipboardService.java"

patch(
    CLIPBOARD,
    [
        (
            "import com.android.server.wm.WindowManagerInternal;\n\nimport java.util.HashSet;",
            "import com.android.server.wm.WindowManagerInternal;\n\n"
            "import com.bluestacks.os.BstHostCallManager;\n\n"
            "import java.util.HashSet;",
        ),
        (
            "    private final SparseArrayMap<Integer, Clipboard> mClipboards = new SparseArrayMap<>();\n",
            "    private final SparseArrayMap<Integer, Clipboard> mClipboards = new SparseArrayMap<>();\n"
            "    private BstHostCallManager mBstHostCallManagerService;\n",
        ),
        (
            "        mAppOps = (AppOpsManager) getContext().getSystemService(Context.APP_OPS_SERVICE);\n"
            "        mContentCaptureInternal = LocalServices.getService("
            "ContentCaptureManagerInternal.class);\n",
            "        mAppOps = (AppOpsManager) getContext().getSystemService(Context.APP_OPS_SERVICE);\n"
            "        mContentCaptureInternal = LocalServices.getService("
            "ContentCaptureManagerInternal.class);\n",
        ),
        (
            "        setPrimaryClipInternalLocked(clipboard, clip, uid, sourcePackage);\n\n"
            "        // Update related users\n",
            "        setPrimaryClipInternalLocked(clipboard, clip, uid, sourcePackage);\n\n"
            "        // A16DBG:P2:FW-SERVICES-1a ClipboardService — host clipboard sync (a13)\n"
            "        if (mBstHostCallManagerService == null) {\n"
            "            mBstHostCallManagerService = (BstHostCallManager) getContext().getSystemService(\n"
            "                    Context.BST_HOST_CALL);\n"
            "        }\n"
            "        if (mBstHostCallManagerService != null && clip != null\n"
            "                && (clip.getDescription() == null\n"
            "                || clip.getDescription().getLabel() == null\n"
            "                || !clip.getDescription().getLabel().toString().equals(\"simpleText\"))) {\n"
            "            ClipData.Item clippedItem = clip.getItemAt(clip.getItemCount() - 1);\n"
            "            if (clippedItem != null && clippedItem.getText() != null\n"
            "                    && clippedItem.getText().length() > 0) {\n"
            "                int rval = mBstHostCallManagerService.setClipboardText(\n"
            "                        clippedItem.getText().toString());\n"
            "                Slog.d(TAG, \"A16DBG:P2:FW-SERVICES-1a setClipboardText rval=\" + rval);\n"
            "                if (rval != 0) {\n"
            "                    Slog.w(TAG, \"A16DBG:P2:FW-SERVICES-1a setClipboardText error rval=\"\n"
            "                            + rval);\n"
            "                }\n"
            "            }\n"
            "        }\n\n"
            "        // Update related users\n",
        ),
    ],
    "ClipboardService",
)

if ERRS:
    for e in ERRS:
        print(f"ERROR {e}", file=sys.stderr)
    sys.exit(1)

print(f"VERIFY {MARKER} present:", MARKER in open(os.path.join(A16, CLIPBOARD)).read())
