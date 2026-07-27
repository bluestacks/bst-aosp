#!/bin/bash
# Triage P2 pending: generate fork-diff inventory for packages/system/external (win a13 vs a16)
set -euo pipefail
LOG=~/p2_triage_inventory.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:triage start $(date -Is)"
A13=~/app-player/android-13
A16=~/aosp16
OUT=~/bst-aosp/patches/android-16/patches/p2-inventory
mkdir -p "$OUT"

# For each project: count files differing (names only) under BST markers
triage_proj() {
  local rel="$1"
  local name="$2"
  if [ ! -d "$A13/$rel" ] || [ ! -d "$A16/$rel" ]; then
    echo "SKIP $name missing tree"
    return
  fi
  echo "=== $name ($rel) ==="
  # files containing BlueStacks / bst. markers in a13
  mapfile -t hits < <(rg -l -i "bluestacks|bst\.|/bst/" "$A13/$rel" -g '!*.o' -g '!*.so' -g '!*.a' -g '!*.jar' -g '!*.apk' 2>/dev/null | head -200 || true)
  echo "bst_marked_files=${#hits[@]}"
  local delta=0 same=0 missing=0
  local list="$OUT/${name}_delta.txt"
  : > "$list"
  for f in "${hits[@]}"; do
    relf="${f#$A13/}"
    if [ ! -f "$A16/$relf" ]; then
      echo "NEW $relf" >> "$list"
      missing=$((missing+1))
    elif ! diff -q "$f" "$A16/$relf" >/dev/null 2>&1; then
      echo "DELTA $relf" >> "$list"
      delta=$((delta+1))
    else
      same=$((same+1))
    fi
  done
  echo "SUMMARY $name delta=$delta same=$same new=$missing"
}

triage_proj packages/apps packages_apps
triage_proj packages/services packages_services
triage_proj packages/modules packages_modules
triage_proj system/core system_core
triage_proj system/sepolicy system_sepolicy
triage_proj system/vold system_vold
triage_proj frameworks/native frameworks_native
triage_proj bionic bionic
triage_proj art art

# Top external projects by bst commit count in a13 (quick)
echo "=== external top dirs with bst markers ==="
rg -l -i "bluestacks|BlueStacks" "$A13/external" -g '!*.o' -g '!*.a' 2>/dev/null | sed 's|.*/external/||;s|/.*||' | sort | uniq -c | sort -rn | head -40

echo "A16DBG:P2:triage DONE $(date -Is)"
ls -la "$OUT"
