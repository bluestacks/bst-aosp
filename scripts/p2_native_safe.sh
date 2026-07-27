#!/bin/bash
# P2 native: inputflinger + installd only (skip binder cpp / SF API-breakers)
set -euo pipefail
LOG=~/p2_native_safe.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:native safe start $(date -Is)"
A13=~/app-player/android-13/frameworks/native
A16=~/aosp16/frameworks/native

for f in \
  services/inputflinger/reader/EventHub.cpp \
  services/inputflinger/reader/mapper/CursorInputMapper.cpp \
  services/inputflinger/reader/mapper/CursorInputMapper.h \
  cmds/installd/globals.cpp \
  cmds/installd/globals.h \
  cmds/installd/utils.cpp \
  cmds/servicemanager/ServiceManager.cpp \
  cmds/servicemanager/servicemanager.rc
 do
  (cd "$A13" && git diff android-13.0.0_r49..HEAD -- "$f") > /tmp/fn_one.patch
  if [ ! -s /tmp/fn_one.patch ]; then echo EMPTY_$f; continue; fi
  if (cd "$A16" && git apply --3way --check /tmp/fn_one.patch 2>/tmp/fn_check.err); then
    (cd "$A16" && git apply --3way /tmp/fn_one.patch && echo OK_$f)
  else
    echo SKIP_$f
    head -15 /tmp/fn_check.err || true
  fi
 done

echo "=== status ==="
git -C "$A16" status --short | head -30
echo "A16DBG:P2:native safe DONE $(date -Is)"
