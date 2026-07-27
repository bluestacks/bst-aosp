#!/usr/bin/env python3
# P2-D9 fix #4: BST binder classes compiled with libbinder's -fvisibility=hidden and lack
# LIBBINDER_EXPORTED -> methods garbage-collected from libbinder.so -> libmedia link error
# (undefined symbol: BstUtilsManager::BstUtilsManager() / getAppNameFromPid(int)).
# Fix: class-level __visibility__("default") via LIBBINDER_EXPORTED (same macro libbinder uses
# for BBinder etc.) + include <binder/Common.h> where the macro is defined.
# Applies to the 4 classes external/native code instantiates: BstUtilsManager, BstFilterAppsManager,
# IBstUtilsService, IBstFilterAppsService (the Bp proxy objects need their vtables retained too).
import os, sys
A16 = os.path.expanduser("~/aosp16")
H = "frameworks/native/libs/binder/include/binder"
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

COMMON = "#include <binder/Common.h>\n"  # LIBBINDER_EXPORTED macro

# BstUtilsManager.h
patch(f"{H}/BstUtilsManager.h", [
    ("#include <binder/IBstUtilsService.h>\n", COMMON + "#include <binder/IBstUtilsService.h>\n"),
    ("    class BstUtilsManager\n", "    class LIBBINDER_EXPORTED BstUtilsManager\n"),
], "BstUtilsManager.h export")

# BstFilterAppsManager.h
patch(f"{H}/BstFilterAppsManager.h", [
    ("#include <binder/IBstFilterAppsService.h>\n", COMMON + "#include <binder/IBstFilterAppsService.h>\n"),
    ("    class BstFilterAppsManager\n", "    class LIBBINDER_EXPORTED BstFilterAppsManager\n"),
], "BstFilterAppsManager.h export")

# IBstUtilsService.h
patch(f"{H}/IBstUtilsService.h", [
    ("#include <binder/IInterface.h>\n", COMMON + "#include <binder/IInterface.h>\n"),
    ("    class IBstUtilsService : public IInterface\n",
     "    class LIBBINDER_EXPORTED IBstUtilsService : public IInterface\n"),
], "IBstUtilsService.h export")

# IBstFilterAppsService.h
patch(f"{H}/IBstFilterAppsService.h", [
    ("#include <binder/IInterface.h>\n", COMMON + "#include <binder/IInterface.h>\n"),
    ("    class IBstFilterAppsService : public IInterface\n",
     "    class LIBBINDER_EXPORTED IBstFilterAppsService : public IInterface\n"),
], "IBstFilterAppsService.h export")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
