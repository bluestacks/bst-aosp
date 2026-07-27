#!/bin/bash
# Extract a13 BST hunks for FW-WM subgroup (ActivityStarter/ATM/DisplayContent/…).
set +u
A13=~/app-player/android-13/frameworks/base
A16=~/aosp16/frameworks/base
TAG=android-13.0.0_r49
OD=~/p2_fw_wm_extract
mkdir -p "$OD"
exec > >(tee ~/p2_fw_wm_extract.log) 2>&1
echo "A16DBG:P2:FW-WM extract $(date -Is)"

cd "$A13" || exit 1
for f in \
  services/core/java/com/android/server/wm/ActivityStarter.java \
  services/core/java/com/android/server/wm/ActivityTaskManagerService.java \
  services/core/java/com/android/server/wm/ActivityTaskSupervisor.java \
  services/core/java/com/android/server/wm/DisplayContent.java \
  services/core/java/com/android/server/wm/RecentsAnimationController.java \
  services/core/java/com/android/server/wm/WindowAnimator.java
 do
  echo "===== $f ====="
  # show only lines with BST markers +/- 5 from a13 working tree vs tag is huge;
  # instead dump marker contexts from a13 file
  if [ -f "$f" ]; then
    rg -n -C3 'BstHostCall|BstUtils|isAppLaunchAllowed|bluestacks|BlueStacks|sendOrientation|ActivityDisplayed|setAppConfig|GRM|FilterApps' "$f" | head -120
    echo "--- a16 presence ---"
    if [ -f "$A16/$f" ]; then
      rg -n 'BstHostCall|BstUtils|isAppLaunchAllowed|ActivityDisplayed|sendOrientation' "$A16/$f" | head -40 || echo '(no markers)'
    else
      echo 'MISSING_IN_A16_PATH'
    fi
  fi
done

# Also dump a13-only helper methods sizes
echo '=== a13 BstHostCallService public API sample ==='
rg -n 'public static|native |void |boolean |int ' \
  "$A13/services/java/com/bluestacks/server/BstHostCallService.java" 2>/dev/null | head -60

echo EXTRACT_DONE
