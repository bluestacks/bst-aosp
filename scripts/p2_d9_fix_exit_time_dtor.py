#!/usr/bin/env python3
# P2-D9 fix #3: a16 libbinder builds with -Werror,-Wexit-time-destructors.
# Global/static String16 service-name objects have destructors that run at exit -> flagged.
# Fix: drop the global decl, construct String16 at the single checkService() call-site
# (temporary binds to const String16& param; not a hot path — only when service lookup misses).
import os, sys
A16 = os.path.expanduser("~/aosp16")
ERRS = []
def patch(rel, replacements, label):
    full = os.path.join(A16, rel)
    with open(full) as f: src = f.read()
    orig = src
    for old, new in replacements:
        if old not in src: ERRS.append(f"{label}: ANCHOR NOT FOUND: {old.strip()[:70]!r}"); return
        if src.count(old) > 1: ERRS.append(f"{label}: ANCHOR NOT UNIQUE ({src.count(old)}): {old.strip()[:70]!r}"); return
        src = src.replace(old, new, 1)
    if src == orig: ERRS.append(f"{label}: no change"); return
    with open(full, "w") as f: f.write(src)
    print(f"OK   {label}")

# BstUtilsManager.cpp: drop `String16 _bstutils("bstutils");` global, inline at call-site
patch("frameworks/native/libs/binder/BstUtilsManager.cpp", [
    ('    String16 _bstutils("bstutils");\n\n', ''),
    ('defaultServiceManager()->checkService(_bstutils)',
     'defaultServiceManager()->checkService(String16("bstutils"))'),  # A16DBG:P2:D9 exit-time-dtor fix
], "BstUtilsManager.cpp drop global String16")

# BstFilterAppsManager.cpp: drop `static String16 _bstfilterapps("bstfilterapps");`, inline at call-site
patch("frameworks/native/libs/binder/BstFilterAppsManager.cpp", [
    ('    static String16 _bstfilterapps("bstfilterapps");\n\n', ''),
    ('defaultServiceManager()->checkService(_bstfilterapps)',
     'defaultServiceManager()->checkService(String16("bstfilterapps"))'),  # A16DBG:P2:D9 exit-time-dtor fix
], "BstFilterAppsManager.cpp drop static String16")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
