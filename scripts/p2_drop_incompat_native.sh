#!/bin/bash
# Drop a13→a16 incompatible native ports; keep bionic/art/icu + clean cmd hunks.
set -euo pipefail
LOG=~/p2_drop_incompat_native.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:drop incompat native start $(date -Is)"
FN=~/aosp16/frameworks/native
BP=$FN/libs/binder/Android.bp

# Revert Android.bp BST srcs insert
python3 - <<'PY'
from pathlib import Path
p = Path.home()/"aosp16/frameworks/native/libs/binder/Android.bp"
t = p.read_text()
bad = (
    '        "BpBinder.cpp",\n'
    '        "BstFilterAppsManager.cpp",\n'
    '        "BstUtilsManager.cpp",\n'
    '        "IBstFilterAppsService.cpp",\n'
    '        "IBstUtilsService.cpp",\n'
)
good = '        "BpBinder.cpp",\n'
if bad in t:
    p.write_text(t.replace(bad, good, 1))
    print("Android.bp: removed BST srcs")
else:
    print("Android.bp: no BST srcs block")
PY

# Remove copied a13 cpp/headers that conflict with a16
rm -f \
  "$FN/libs/binder/BstFilterAppsManager.cpp" \
  "$FN/libs/binder/BstUtilsManager.cpp" \
  "$FN/libs/binder/IBstFilterAppsService.cpp" \
  "$FN/libs/binder/IBstUtilsService.cpp" \
  "$FN/libs/binder/include/binder/BstUtilsManager.h" \
  "$FN/libs/binder/include/binder/IBstFilterAppsService.h" \
  "$FN/libs/binder/include/binder/IBstUtilsService.h" \
  "$FN/include/binder/IBstFilterAppsService.h" \
  "$FN/include/binder/IBstUtilsService.h"
# keep existing a16 BstFilterAppsManager.h if it was already there from G1

# Revert SF + any cmd that fails — revert SF for sure
git -C "$FN" checkout -- services/surfaceflinger/SurfaceFlinger.cpp

# Keep dumpstate/installd/servicemanager for now; if build fails, revert those too
echo "=== remaining native status ==="
git -C "$FN" status --short | head -40
echo "A16DBG:P2:drop incompat native DONE $(date -Is)"
