#!/bin/bash
set -euo pipefail
echo "A16DBG:P2:native remainder start $(date -Is)"
A13=~/app-player/android-13/frameworks/native
A16=~/aosp16/frameworks/native
# ensure CursorInputMapper clean
git -C "$A16" restore --source=HEAD --staged --worktree \
  services/inputflinger/reader/mapper/CursorInputMapper.cpp \
  services/inputflinger/reader/mapper/CursorInputMapper.h 2>/dev/null || true
rm -f "$A16"/services/inputflinger/reader/mapper/*.orig \
      "$A16"/services/inputflinger/reader/mapper/*REVERT* 2>/dev/null || true

for f in \
  cmds/installd/globals.cpp \
  cmds/installd/globals.h \
  cmds/installd/utils.cpp \
  cmds/servicemanager/ServiceManager.cpp \
  cmds/servicemanager/servicemanager.rc
 do
  (cd "$A13" && git diff android-13.0.0_r49..HEAD -- "$f") > /tmp/fn_one.patch
  if [ ! -s /tmp/fn_one.patch ]; then echo EMPTY_$f; continue; fi
  if (cd "$A16" && git apply --3way --check /tmp/fn_one.patch 2>/tmp/e.err); then
    (cd "$A16" && git apply --3way /tmp/fn_one.patch && echo OK_$f)
  else
    echo SKIP_$f
    head -8 /tmp/e.err || true
  fi
 done

echo "=== status ==="
git -C "$A16" status --short | head -20
echo DONE
