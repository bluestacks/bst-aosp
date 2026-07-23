#!/usr/bin/env python3
# P2-FW-PERIPH-7: SettingsService — filter ENABLED_ACCESSIBILITY_SERVICES in bulk get-command path.
# Complementary to SettingsProvider (PERIPH-6, single-read) — this covers the shell/get-command path.
# a16 anchors match a13. BstUtils.filterHiddenServices(String, int). Robust exact-string replace.
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

patch("packages/SettingsProvider/src/com/android/providers/settings/SettingsService.java", [
    ("import android.util.Slog;\n",
     "import android.util.Slog;\nimport android.util.BstUtils;\n"),
    ('''                if (b != null) {
                    result = b.getPairValue();
                }
''',
     '''                if (b != null) {
                    result = b.getPairValue();
                    // A16DBG:P2:FW-PERIPH-7 BST filter a11y services for 3rd-party (a13)
                    if (result != null && "secure".equals(table)
                            && Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES.equals(key)) {
                        result = BstUtils.filterHiddenServices(result, Binder.getCallingUid());
                    }
                }
'''),
], "SettingsService bulk-read a11y filter")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
