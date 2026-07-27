#!/bin/bash
# P2 Batch D: BstUtils full + pagefusion + small android_api / wm diffs that 3way clean
set -euo pipefail
LOG=~/p2_batchD.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:batchD start $(date -Is)"
A13=~/app-player/android-13/frameworks/base
A16=~/aosp16/frameworks/base

# 1) BstUtils — replace with a13 (previous crash was combo; BatchC alone green)
cp -a "$A13/core/java/android/util/BstUtils.java" "$A16/core/java/android/util/BstUtils.java"
# ensure @hide on class if not present
if ! grep -q '@hide' "$A16/core/java/android/util/BstUtils.java"; then
  sed -i 's/^public class BstUtils/\/\*\* @hide \*\/\npublic class BstUtils/' "$A16/core/java/android/util/BstUtils.java" || true
fi
echo "COPIED BstUtils.java ($(wc -l < "$A16/core/java/android/util/BstUtils.java") lines)"

# 2) pagefusion cmds (separate binary — low boot risk)
mkdir -p "$A16/cmds/pagefusion"
cp -a "$A13/cmds/pagefusion/." "$A16/cmds/pagefusion/"
echo "COPIED pagefusion"

# 3) Try clean 3way applies for smaller files
ok=0; skip=0
while IFS= read -r f; do
  case "$f" in
    services/core/java/com/android/server/wm/WindowManagerService.java) continue ;; # already BatchC
    services/core/java/com/android/server/wm/DisplayRotation.java) continue ;; # policy-heavy
    services/core/java/com/android/server/wm/ActivityStarter.java) continue ;; # GRM risk
    core/java/android/util/BstUtils.java) continue ;;
    core/java/android/util/Features.java) continue ;;
    cmds/pagefusion/*) continue ;;
    core/java/com/bluestacks/internal/*) continue ;;
  esac
  # only small-ish files (<80 lines changed)
  ns=$(cd "$A13" && git diff --numstat android-13.0.0_r49..HEAD -- "$f" | awk '{print $1+$2}')
  [ -z "$ns" ] && continue
  [ "$ns" -gt 80 ] && continue
  [ ! -f "$A16/$f" ] && continue
  (cd "$A13" && git diff android-13.0.0_r49..HEAD -- "$f") > /tmp/fw_one.patch
  if (cd "$A16" && git apply --3way --check /tmp/fw_one.patch 2>/dev/null); then
    (cd "$A16" && git apply --3way /tmp/fw_one.patch && echo OK_$f && ok=$((ok+1))) || true
  else
    skip=$((skip+1))
  fi
done < ~/bst-aosp/patches/android-16/patches/p2-fw-classify/a13_base_files.txt
echo "small 3way ok=$ok skip_or_large=$skip"

echo "=== status ==="
git -C "$A16" status --short | head -40
echo "A16DBG:P2:batchD DONE $(date -Is)"
