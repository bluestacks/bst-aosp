#!/bin/bash
# Reset conflicted overlay applies (keep frameworks/base Batch A/B + icu)
set -euo pipefail
LOG=~/p2_clean_conflicts.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:clean conflicts start $(date -Is)"
cd ~/aosp16

# bionic: abort merge / hard reset
if [ -d bionic ]; then
  cd bionic
  git merge --abort 2>/dev/null || true
  git reset --hard HEAD
  git clean -fd
  echo "bionic cleaned: $(git status --short | wc -l) dirty"
  cd ..
fi

# art: discard rejects + partial
if [ -d art ]; then
  cd art
  git checkout -- .
  git clean -fd
  echo "art cleaned: $(git status --short | wc -l) dirty"
  cd ..
fi

# frameworks/native: discard failed overlay (Batch B surgical was in frameworks/base only)
if [ -d frameworks/native ]; then
  cd frameworks/native
  git checkout -- .
  git clean -fd
  echo "native cleaned: $(git status --short | wc -l) dirty"
  cd ../..
fi

# boringssl: reset failed apply
if [ -d external/boringssl ]; then
  cd external/boringssl
  git checkout -- . 2>/dev/null || true
  rm -f selftest/Android.bp.rej
  echo "boringssl cleaned"
  cd ../..
fi

# icu: KEEP (clean apply of Iran TZ)
cd external/icu
echo "icu keep:"; git status --short | head
cd ../..

# frameworks/base: KEEP Batch A/B
cd frameworks/base
echo "frameworks/base keep (sample):"
git status --short | head -25
cd ../..

# restore known-good Root on remote for ops
if [ -f ~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd.bak-182606 ]; then
  cp -a ~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd.bak-182606 \
        ~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd
  md5sum ~/releases/Baklava64/bst-v5.22.210_Baklava64-local/Root.vhd
fi
echo "A16DBG:P2:clean conflicts DONE $(date -Is)"
