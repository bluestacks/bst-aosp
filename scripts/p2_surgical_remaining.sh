#!/bin/bash
# Surgical P2 ports AFTER m droid Layer2 green — no full-file a13 overlays
set -euo pipefail
LOG=~/p2_surgical_remaining.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:surgical remaining start $(date -Is)"
A16=~/aosp16
A13=~/app-player/android-13
OUT=~/bst-aosp/patches/android-16/patches/p2-remaining
mkdir -p "$OUT"

# --- boringssl: only files that exist on a16 ---
echo "=== boringssl ==="
BS=$A16/external/boringssl
# selftest Android.bp: disable vendor self_test if present (boot time)
if [ -f "$BS/selftest/Android.bp" ]; then
  if grep -q 'stem: "boringssl_self_test"' "$BS/selftest/Android.bp"; then
    # a13 change was vendor:true tweak — inspect a16
    cp -a "$BS/selftest/Android.bp" "$OUT/boringssl_selftest.Android.bp.bak"
  fi
fi
# rsa padding — find a16 path
PAD=$(find "$BS" -name 'padding.c' -path '*/rsa/*' | head -1 || true)
echo "padding path=$PAD"
if [ -n "$PAD" ]; then
  # show a13 diff hunk for padding only
  (cd "$A13/external/boringssl" && git diff android-13.0.0_r49..HEAD -- src/crypto/fipsmodule/rsa/padding.c) > "$OUT/boringssl_padding.patch" || true
  if [ -s "$OUT/boringssl_padding.patch" ]; then
    # rewrite path in patch to a16 relative
    REL=${PAD#$BS/}
    sed -i "s|src/crypto/fipsmodule/rsa/padding.c|$REL|g" "$OUT/boringssl_padding.patch" || true
    (cd "$BS" && git apply --check "$OUT/boringssl_padding.patch" 2>"$OUT/boringssl_check.err" && git apply "$OUT/boringssl_padding.patch" && echo OK_padding) || {
      echo FAIL_padding; cat "$OUT/boringssl_check.err" | head -20
      # manual: show a13 added lines
      (cd "$A13/external/boringssl" && git show android-13.0.0_r49..HEAD:src/crypto/fipsmodule/rsa/padding.c 2>/dev/null | head -5) || true
    }
  fi
fi

# --- bionic: only clean-applyable files from prior attempt ---
echo "=== bionic (selective) ==="
# Prefer copying known-good small diffs: getaddrinfo, fortify, open, poll, libc.map
for f in \
  libc/dns/net/getaddrinfo.c \
  libc/bionic/fortify.cpp \
  libc/bionic/open.cpp \
  libc/bionic/poll.cpp \
  libc/libc.map.txt \
  libc/private/bionic_fortify.h
 do
  if [ -f "$A13/bionic/$f" ] && [ -f "$A16/bionic/$f" ]; then
    if ! diff -q "$A13/bionic/$f" "$A16/bionic/$f" >/dev/null; then
      (cd "$A13/bionic" && git diff android-13.0.0_r49..HEAD -- "$f") > "/tmp/bionic_one.patch"
      if [ -s /tmp/bionic_one.patch ]; then
        (cd "$A16/bionic" && git apply --3way --check /tmp/bionic_one.patch 2>/dev/null && git apply --3way /tmp/bionic_one.patch && echo OK_$f) || echo SKIP_$f
      fi
    else
      echo SAME_$f
    fi
  fi
 done

# --- art: only native_loader_namespace if applies ---
echo "=== art selective ==="
for f in libnativeloader/native_loader_namespace.cpp; do
  (cd "$A13/art" && git diff android-13.0.0_r49..HEAD -- "$f") > /tmp/art_one.patch
  if [ -s /tmp/art_one.patch ]; then
    (cd "$A16/art" && git apply --3way --check /tmp/art_one.patch 2>/dev/null && git apply --3way /tmp/art_one.patch && echo OK_$f) || echo SKIP_$f
  fi
done

# --- frameworks/native: copy NEW BST binder files only + small clean hunks ---
echo "=== frameworks/native new BST files ==="
for f in \
  libs/binder/BstFilterAppsManager.cpp \
  libs/binder/BstUtilsManager.cpp \
  libs/binder/IBstFilterAppsService.cpp \
  libs/binder/IBstUtilsService.cpp \
  libs/binder/include/binder/BstFilterAppsManager.h \
  libs/binder/include/binder/BstUtilsManager.h \
  libs/binder/include/binder/IBstFilterAppsService.h \
  libs/binder/include/binder/IBstUtilsService.h \
  include/binder/IBstFilterAppsService.h \
  include/binder/IBstUtilsService.h
 do
  if [ -f "$A13/frameworks/native/$f" ] && [ ! -f "$A16/frameworks/native/$f" ]; then
    mkdir -p "$(dirname "$A16/frameworks/native/$f")"
    cp -a "$A13/frameworks/native/$f" "$A16/frameworks/native/$f"
    echo COPIED_$f
  elif [ -f "$A16/frameworks/native/$f" ]; then
    echo EXISTS_$f
  else
    echo MISS_A13_$f
  fi
done

# dumpstate/installd/servicemanager — try 3way per file
for f in \
  cmds/dumpstate/DumpstateUtil.cpp \
  cmds/dumpstate/dumpstate.h \
  cmds/installd/globals.cpp \
  cmds/installd/globals.h \
  cmds/installd/utils.cpp \
  cmds/servicemanager/ServiceManager.cpp \
  services/surfaceflinger/SurfaceFlinger.cpp
 do
  (cd "$A13/frameworks/native" && git diff android-13.0.0_r49..HEAD -- "$f") > /tmp/fn_one.patch
  if [ ! -s /tmp/fn_one.patch ]; then echo EMPTY_$f; continue; fi
  (cd "$A16/frameworks/native" && git apply --3way --check /tmp/fn_one.patch 2>/dev/null && git apply --3way /tmp/fn_one.patch && echo OK_$f) || echo SKIP_$f
done

echo "A16DBG:P2:surgical remaining DONE $(date -Is)"
# status summary
git -C "$A16/external/icu" diff --stat HEAD | tail -3
git -C "$A16/bionic" status --short | head -20
git -C "$A16/art" status --short | head -10
git -C "$A16/frameworks/native" status --short | head -30
