#!/usr/bin/env python3
# P2-MECH-10: frameworks/av camera BST sensor rotation (CameraService + CameraProviderManager).
# Per-app camera sensor rotation override. Uses BstUtilsManager.h + BstFilterAppsManager.h stubs
# (fail-open: empty app name → rotation 0 → no override). Unblocked by MECH-9 BstUtilsManager.h stub.
# Robust exact-string replace.
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

INCLUDES = (
    "#include <binder/IPCThreadState.h>\n"
    "#include <binder/BstFilterAppsManager.h>\n"
    "#include <binder/BstUtilsManager.h>\n"
)

BST_OVERRIDE = (
    "            // A16DBG:P2:MECH BST camera sensor rotation per-app (a13; stub fail-open)\n"
    "            int bstPid = android::IPCThreadState::self()->getCallingPid();\n"
    "            android::BstUtilsManager bstUtil;\n"
    "            android::String16 bstPkg = bstUtil.getAppNameFromPid(bstPid);\n"
    "            android::BstFilterAppsManager bstFilter;\n"
    "            int32_t bstAngle = bstFilter.getCameraSensorRotation(bstPkg);\n"
    "            if (bstAngle > 0) {\n"
    "                *orientation = bstAngle % 1000 % 360;\n"
    "            }\n"
)

# CameraService.cpp
patch("frameworks/av/services/camera/libcameraservice/CameraService.cpp", [
    # includes: add after an existing include
    ("#include <camera/CameraUtils.h>\n", "#include <camera/CameraUtils.h>\n" + INCLUDES),
    # BST override after orientation assignment
    ("            *orientation = info.orientation;\n        }\n",
     "            *orientation = info.orientation;\n" + BST_OVERRIDE + "        }\n"),
], "CameraService camera rotation")

# CameraProviderManager.cpp — same BST override pattern (info->orientation)
BST_OVERRIDE_PMGR = BST_OVERRIDE.replace("*orientation", "info->orientation")
patch("frameworks/av/services/camera/libcameraservice/common/CameraProviderManager.cpp", [
    ("#include <camera/CameraUtils.h>\n", "#include <camera/CameraUtils.h>\n" + INCLUDES)
    if "#include <camera/CameraUtils.h>\n" in open(os.path.join(A16, "frameworks/av/services/camera/libcameraservice/common/CameraProviderManager.cpp")).read()
    else ("#include <utils/String16.h>\n", "#include <utils/String16.h>\n" + INCLUDES),
    ("        info->orientation = orientation.data.i32[0];\n    }\n",
     "        info->orientation = orientation.data.i32[0];\n" + BST_OVERRIDE_PMGR + "    }\n"),
], "CameraProviderManager camera rotation")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
