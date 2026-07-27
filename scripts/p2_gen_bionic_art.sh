#!/bin/bash
# Generate (do not apply) a13 fork-diffs for bionic + art while systemimage runs
set -euo pipefail
LOG=~/p2_gen_bionic_art.log
exec > >(tee "$LOG") 2>&1
OUT=~/bst-aosp/patches/android-16/patches/p2-bionic-art
mkdir -p "$OUT"
echo "A16DBG:P2:gen bionic/art start $(date -Is)"
for proj in bionic art; do
  cd ~/app-player/android-13/$proj
  TAG=$(git tag --list 'android-13.0.0_r*' --sort=version:refname | tail -1)
  echo "=== $proj tag=$TAG ==="
  git diff --stat "$TAG"..HEAD | tail -8
  git diff "$TAG"..HEAD > "$OUT/a13__${proj}__bst_full.patch"
  git diff --name-only "$TAG"..HEAD > "$OUT/a13__${proj}__files.txt"
  wc -l "$OUT/a13__${proj}__bst_full.patch"
  cat "$OUT/a13__${proj}__files.txt"
done
echo "A16DBG:P2:gen bionic/art DONE $(date -Is)"
