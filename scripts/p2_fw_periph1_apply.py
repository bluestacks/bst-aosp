#!/usr/bin/env python3
# P2-FW-PERIPH-1: SystemVibrator + MediaCodecInfo — small clean peripheral BST hooks (a13->a16).
# SystemVibrator: hasVibrator() always reports present (bst_enable_vibrator) — games that check.
# MediaCodecInfo: ROB-10676 swap OMX.google.h264.encoder -> c2.android.avc.encoder for whatsapp.
# App-process, low boot risk. Robust exact-string replace.
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

patch("core/java/android/os/SystemVibrator.java", [
    # anchor includes @Override so the annotation stays on hasVibrator (not the new field)
    ("    @Override\n    public boolean hasVibrator() {\n",
     "    // A16DBG:P2:FW-PERIPH BST: always report vibrator present (a13 bst_enable_vibrator)\n"
     "    private static final boolean bst_enable_vibrator = true;\n\n"
     "    @Override\n    public boolean hasVibrator() {\n"),
    ("        return vibratorIds.length > 0;\n",
     "        return vibratorIds.length > 0 || bst_enable_vibrator;\n"),
], "SystemVibrator.hasVibrator bst_enable_vibrator")

patch("media/java/android/media/MediaCodecInfo.java", [
    ("""    public final String getName() {
        return mName;
    }
""",
     """    public final String getName() {
        // A16DBG:P2:FW-PERIPH ROB-10676 swap h264 encoder name for whatsapp (a13)
        if ("OMX.google.h264.encoder".equals(mName)) {
            String topPackageName = android.os.SystemProperties.get("bst.config.top_package_name", null);
            if (topPackageName != null && topPackageName.startsWith("com.whatsapp")) {
                return "c2.android.avc.encoder";
            }
        }
        return mName;
    }
"""),
], "MediaCodecInfo.ROB-10676 whatsapp h264 swap")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
