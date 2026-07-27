#!/bin/bash
# P2-FRAMEWORK-REST Batch B expanded: hostcall hooks in framework (not just managers)
set -euo pipefail
LOG=~/p2_batchB_apply.log
exec > >(tee "$LOG") 2>&1
A13=~/app-player/android-13/frameworks/base
A16=~/aosp16/frameworks/base
OUT=~/bst-aosp/patches/android-16/patches/p2-framework-rest
mkdir -p "$OUT"
echo "A16DBG:P2:batchB expand start $(date -Is)"

# Files where a13 fork mentions BstHostCall / hostcall / gcall and likely differs from a16
mapfile -t CANDS < <(rg -l "BstHostCall|hcallOnActivity|IBstHostCall|bst\.hostcall|gcall" "$A13" --glob "*.java" --glob "*.cpp" --glob "*.h" 2>/dev/null | sed "s|^$A13/||" | grep -v '/tests/' | grep -v 'coretests' | sort -u)

PATCH="$OUT/p2_fw_batchB_hooks.patch"
: > "$PATCH"
changed=0
same=0
missing_a16=0
for rel in "${CANDS[@]}"; do
  [ -f "$A13/$rel" ] || continue
  if [ ! -f "$A16/$rel" ]; then
    echo "NEW $rel"
    missing_a16=$((missing_a16+1))
    diff -u /dev/null "$A13/$rel" | sed "1s|.*|--- /dev/null|;2s|.*|+++ b/$rel|" >> "$PATCH" || true
    changed=$((changed+1))
    continue
  fi
  if diff -q "$A13/$rel" "$A16/$rel" >/dev/null; then
    echo "SAME $rel"
    same=$((same+1))
  else
    echo "DELTA $rel"
    diff -u "$A16/$rel" "$A13/$rel" | sed "1s|.*|--- a/$rel|;2s|.*|+++ b/$rel|" >> "$PATCH" || true
    changed=$((changed+1))
  fi
done
echo "SUMMARY changed=$changed same=$same new_missing_a16=$missing_a16 patch_lines=$(wc -l < "$PATCH")"

# Do NOT blindly apply a13→a16 full-file replace (API drift). Extract only BST-marked hunks later.
# For now: apply only small files that are BST-only or already mostly ported; record DELTA list.
echo "$CANDS" > "$OUT/batchB_candidates.txt"
printf '%s\n' "${CANDS[@]}" > "$OUT/batchB_candidates.txt"

# Apply strategy: for DELTA files under com/bluestacks already SAME.
# For framework hooks, generate a "BST markers only" patch via git diff from a16 using 3-way is complex.
# Practical Batch B step1: copy any NEW files; for DELTA list write research note; apply ActivityDisplayed-related if missing.

rg -n "hcallOnActivityDisplayed|BstHostCallManager|ActivityDisplayed" "$A16/services/core/java/com/android/server/wm" "$A16/core/java/android/app/Activity.java" 2>/dev/null | head -40 || true
rg -n "hcallOnActivityDisplayed|BstHostCallManager" "$A13/services/core/java/com/android/server/wm" "$A13/core/java/android/app/Activity.java" 2>/dev/null | head -40 || true

echo "A16DBG:P2:batchB expand DONE $(date -Is)"
