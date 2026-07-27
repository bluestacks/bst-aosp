#!/usr/bin/env python3
# P2-D9 fix: binder C++ BST headers fail to compile in a16 libbinder vendor variant.
# Two mechanical issues per header:
#   (1) `#ifndef __ANDROID_VNDK__ ... #else #error "not visible to vendors" #endif` guard.
#       libbinder is built as android_vendor_x86_64_shared (defines __ANDROID_VNDK__) -> #error fires.
#       These are OUR client headers consumed inside libbinder; the vendor-exclusion guard is wrong here.
#       Fix: drop the guard entirely (keep #pragma once).
#   (2) a16 IInterface.h no longer transitively pulls <utils/String16.h> (header hygiene).
#       Headers declare String16 params -> "unknown type name 'String16'".
#       Fix: explicitly #include <utils/String16.h>.
# BstUtilsManager.h / BstFilterAppsManager.h get String16 transitively via these IInterface headers.
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

TRAILING_GUARD = (
    '\n#else // __ANDROID_VNDK__\n'
    '#error "This header is not visible to vendors"\n'
    '#endif // __ANDROID_VNDK__'
)

# IBstFilterAppsService.h — guard has no blank line between #ifndef and #include
patch("frameworks/native/libs/binder/include/binder/IBstFilterAppsService.h", [
    ("#ifndef __ANDROID_VNDK__\n#include <binder/IInterface.h>\n",
     "#include <binder/IInterface.h>\n#include <utils/String16.h>\n"),
    (TRAILING_GUARD, ""),
], "IBstFilterAppsService.h drop guard + String16")

# IBstUtilsService.h — guard has a blank line between #ifndef and #include
patch("frameworks/native/libs/binder/include/binder/IBstUtilsService.h", [
    ("#ifndef __ANDROID_VNDK__\n\n#include <binder/IInterface.h>\n",
     "#include <binder/IInterface.h>\n#include <utils/String16.h>\n"),
    (TRAILING_GUARD, ""),
], "IBstUtilsService.h drop guard + String16")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
