#!/usr/bin/env python3
# P2-D9 fix #5: BstFilterAppsManager.cpp includes <binder/PermissionController.h>, which has the
# same `#ifndef __ANDROID_VNDK__ / #error "not visible to vendors"` guard. libbinder is built with
# vendor_available:true -> the vendor variant hits #error + "unknown type 'PermissionController'".
# Only use is isHotFixAppByUid() (get packages-for-uid, then isHotFixApp).
# Fix: guard the include + that method body with #ifndef __ANDROID_VNDK__ -> system variant keeps
# full behavior; vendor variant fail-opens to `return false` (matches existing stub fail-open).
import os, sys
A16 = os.path.expanduser("~/aosp16")
F = "frameworks/native/libs/binder/BstFilterAppsManager.cpp"
full = os.path.join(A16, F)
with open(full) as f: src = f.read()
orig = src

# 1. Guard the include
old_inc = "#include <binder/PermissionController.h>\n"
new_inc = "#ifndef __ANDROID_VNDK__  // A16DBG:P2:D9 PermissionController not visible to vendor variant\n#include <binder/PermissionController.h>\n#endif\n"
if old_inc not in src: print("ERROR: include anchor not found"); sys.exit(1)
src = src.replace(old_inc, new_inc, 1)

# 2. Guard the isHotFixAppByUid body (keep `return false` fallthrough for vendor)
old_body = (
    "    bool BstFilterAppsManager::isHotFixAppByUid(const int32_t uid)\n"
    "    {\n"
    "        Vector<String16> packages;\n"
    "        PermissionController pc;\n"
    "        pc.getPackagesForUid(uid, packages);\n"
    "        if (packages.size() > 0) {\n"
    "            return isHotFixApp(packages[0]);\n"
    "        }\n"
    "        return false;\n"
    "    }\n"
)
new_body = (
    "    bool BstFilterAppsManager::isHotFixAppByUid(const int32_t uid)\n"
    "    {\n"
    "#ifndef __ANDROID_VNDK__  // A16DBG:P2:D9 PermissionController system-only; vendor fail-open\n"
    "        Vector<String16> packages;\n"
    "        PermissionController pc;\n"
    "        pc.getPackagesForUid(uid, packages);\n"
    "        if (packages.size() > 0) {\n"
    "            return isHotFixApp(packages[0]);\n"
    "        }\n"
    "#endif\n"
    "        return false;\n"
    "    }\n"
)
if old_body not in src: print("ERROR: isHotFixAppByUid body anchor not found"); sys.exit(1)
src = src.replace(old_body, new_body, 1)

if src == orig: print("ERROR: no change"); sys.exit(1)
with open(full, "w") as f: f.write(src)
print("OK   BstFilterAppsManager.cpp PermissionController vendor-guarded (system full / vendor fail-open)")
