#!/bin/bash
set -euo pipefail
echo "A16DBG:P2:cleanup native $(date -Is)"
# kill leftover soong
pkill -f 'soong_ui --build-mode' || true
sleep 2
FN=~/aosp16/frameworks/native
git -C "$FN" checkout -f -- \
  services/surfaceflinger/SurfaceFlinger.cpp \
  cmds/dumpstate/DumpstateUtil.cpp \
  cmds/dumpstate/dumpstate.h \
  cmds/installd/globals.cpp \
  cmds/installd/globals.h \
  cmds/installd/utils.cpp \
  cmds/servicemanager/ServiceManager.cpp
rm -f "$FN"/libs/binder/Bst*.cpp "$FN"/libs/binder/IBst*.cpp
rm -f "$FN"/libs/binder/include/binder/BstUtilsManager.h \
      "$FN"/libs/binder/include/binder/IBstFilterAppsService.h \
      "$FN"/libs/binder/include/binder/IBstUtilsService.h \
      "$FN"/include/binder/IBstFilterAppsService.h \
      "$FN"/include/binder/IBstUtilsService.h
python3 ~/bst-aosp/scripts/p2_strip_binder_bp.py
echo "=== native ==="
git -C "$FN" status --short | head
echo "=== bionic ==="
git -C ~/aosp16/bionic status --short | head
echo "=== art ==="
git -C ~/aosp16/art status --short | head
echo "=== icu ==="
git -C ~/aosp16/external/icu status --short | head
echo DONE
