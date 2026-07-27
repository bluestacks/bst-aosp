#!/bin/bash
set -euo pipefail
echo "A16DBG:P2:safe_reapply start $(date -Is)"

# Kill builds
pkill -f "bash .*/g1_build.sh" || true
pkill -f "soong_ui --build-mode" || true
pkill -f p2_await_g1 || true
pkill -f p2_full_pack || true
sleep 3
echo KILLED

FN=~/aosp16/frameworks/native
# Fully restore native to HEAD
git -C "$FN" restore --source=HEAD --staged --worktree . || git -C "$FN" checkout -f .
echo "native clean:"
git -C "$FN" status --short | head || echo clean

# Restore bionic map from HEAD then reapply safe files only
git -C ~/aosp16/bionic restore --source=HEAD --staged --worktree .
echo "bionic clean then reapply"
for f in \
  libc/dns/net/getaddrinfo.c \
  libc/bionic/fortify.cpp \
  libc/bionic/open.cpp \
  libc/bionic/poll.cpp \
  libc/private/bionic_fortify.h
 do
  (cd ~/app-player/android-13/bionic && git diff android-13.0.0_r49..HEAD -- "$f") > /tmp/bionic_one.patch
  if [ -s /tmp/bionic_one.patch ]; then
    (cd ~/aosp16/bionic && git apply --3way /tmp/bionic_one.patch && echo OK_$f) || echo SKIP_$f
  fi
 done

# art
git -C ~/aosp16/art restore --source=HEAD --staged --worktree . || true
(cd ~/app-player/android-13/art && git diff android-13.0.0_r49..HEAD -- libnativeloader/native_loader_namespace.cpp) > /tmp/art_one.patch
(cd ~/aosp16/art && git apply --3way /tmp/art_one.patch && echo OK_art) || echo SKIP_art

# ensure no iopl
rg -n "iopl|ioperm" ~/aosp16/bionic/libc/libc.map.txt && echo BAD_MAP || echo NO_IOPL_OK

echo "=== final status ==="
git -C ~/aosp16/bionic status --short | head
git -C ~/aosp16/art status --short | head
git -C ~/aosp16/frameworks/native status --short | head
git -C ~/aosp16/frameworks/base status --short | head
git -C ~/aosp16/external/icu status --short | head
echo "A16DBG:P2:safe_reapply DONE $(date -Is)"
