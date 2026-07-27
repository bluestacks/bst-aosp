#!/bin/bash
# Apply frameworks/native BST fork-diff overlay (win) surgically where possible
set -euo pipefail
LOG=~/p2_native_overlay.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:native overlay start $(date -Is)"
A13=~/app-player/android-13/frameworks/native
A16=~/aosp16/frameworks/native
OUT=~/bst-aosp/patches/android-16/patches/p2-framework-rest
mkdir -p "$OUT"

cd "$A13"
TAG=$(git tag --list 'android-13.0.0_r*' --sort=version:refname | tail -1)
echo "TAG=$TAG"
git diff "$TAG"..HEAD > "$OUT/p2_fw_native_full_a13.patch"
wc -l "$OUT/p2_fw_native_full_a13.patch"
git diff --name-only "$TAG"..HEAD

# Prefer apply with 3way; record rejects
cd "$A16"
git status --short | head
set +e
git apply --3way --check "$OUT/p2_fw_native_full_a13.patch" 2>"$OUT/p2_fw_native_check.err"
check_rc=$?
echo "check_rc=$check_rc"
if [ $check_rc -eq 0 ]; then
  git apply --3way "$OUT/p2_fw_native_full_a13.patch"
  echo "APPLY_OK"
else
  echo "FULL_APPLY_FAIL — try per-file for BST-only paths"
  cat "$OUT/p2_fw_native_check.err" | head -40
  # Apply file-by-file for paths that exist
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    git diff "$TAG"..HEAD -- "$f" > /tmp/one.patch 2>/dev/null || continue
    # regenerate from a13 tree
    (cd "$A13" && git diff "$TAG"..HEAD -- "$f") > /tmp/one.patch
    if [ ! -s /tmp/one.patch ]; then continue; fi
    if git apply --3way --check /tmp/one.patch 2>/dev/null; then
      git apply --3way /tmp/one.patch && echo "OK $f"
    else
      echo "FAIL $f"
      # If new file only in a13
      if [ ! -f "$A16/$f" ] && [ -f "$A13/$f" ]; then
        mkdir -p "$(dirname "$A16/$f")"
        cp -a "$A13/$f" "$A16/$f"
        echo "COPIED_NEW $f"
      fi
    fi
  done < <(cd "$A13" && git diff --name-only "$TAG"..HEAD)
fi
set -e

# Save current a16 diff
cd "$A16"
git diff > "$OUT/aosp16__frameworks_native__P2-overlay.diff" || true
git status --short | head -40
echo "A16DBG:P2:native overlay DONE $(date -Is)"
