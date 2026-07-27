#!/bin/bash
# Inventory BST customization gaps: a13 frameworks/base fork-diff vs a16 tree presence.
set +u
A13=~/app-player/android-13/frameworks/base
A16=~/aosp16/frameworks/base
OUT=~/p2_fw_gap_inventory.txt
exec > >(tee "$OUT") 2>&1
echo "A16DBG:P2: fw gap inventory $(date -Is)"

# Upstream a13 tag used as base for fork-diff (best-effort)
cd "$A13" || exit 1
BASE=$(git describe --tags --match 'android-13*' 2>/dev/null | head -1)
echo "a13 HEAD=$(git rev-parse --short HEAD) describe=$BASE"
# Prefer android-13.0.0_r82 or similar if present
TAG=$(git tag -l 'android-13.0.0_r*' | sort -V | tail -1)
echo "a13 nearest tag=$TAG"
if [ -n "$TAG" ]; then
  git diff --stat "$TAG"..HEAD -- . | tail -30
  echo '=== top changed paths (depth2) ==='
  git diff --name-only "$TAG"..HEAD -- . | awk -F/ '{print $1"/"$2}' | sort | uniq -c | sort -rn | head -40
  echo '=== services/core/java/com/android/server/wm (files with BST signals) ==='
  git diff --name-only "$TAG"..HEAD -- services/core/java/com/android/server/wm | head -80
  echo '=== SystemUI files ==='
  git diff --name-only "$TAG"..HEAD -- packages/SystemUI | head -40
  echo '=== AM/PM/ATM ==='
  git diff --name-only "$TAG"..HEAD -- services/core/java/com/android/server/am services/core/java/com/android/server/pm | head -40
fi

echo '=== a16 BST markers sample ==='
rg -l 'BstHostCall|BstUtils|A16DBG:P2|bluestacks|BlueStacks' "$A16" --glob '*.{java,kt,cpp,h}' 2>/dev/null | head -60
echo '=== a16 count BstHostCall ==='
rg -c 'BstHostCall' "$A16" --glob '*.{java,kt}' 2>/dev/null | head -40
echo '=== a13 count BstHostCall ==='
rg -c 'BstHostCall' "$A13" --glob '*.{java,kt}' 2>/dev/null | head -40

echo DONE
