#!/bin/bash
set +u
A16=~/aosp16/frameworks/base
A13=~/app-player/android-13/frameworks/base
echo '=== a16 RecentsAnimation ==='
find "$A16/services/core/java/com/android/server/wm" -name '*Recents*' 2>/dev/null
echo '=== a16 WMS BST markers ==='
rg -n 'BstHostCall|sendOrientation|setAppConfig|ActivityDisplayed|A16DBG:P2' \
  "$A16/services/core/java/com/android/server/wm/WindowManagerService.java" | head -40
echo '=== a16 DisplayContent BST ==='
rg -n 'BstFilter|sendOrientation|A16DBG' \
  "$A16/services/core/java/com/android/server/wm/DisplayContent.java" | head -20
echo '=== a16 ActivityStarter execute path anchors ==='
rg -n 'executeRequest|START_SUCCESS|resolveActivity|mLastStartReason' \
  "$A16/services/core/java/com/android/server/wm/ActivityStarter.java" | head -30
echo '=== a13 hideBlueStacksPkg full block ==='
rg -n -A25 'hideBlueStacksPkg' "$A13/services/core/java/com/android/server/wm/ActivityStarter.java" | head -40
echo '=== BstUtils.hideBlueStacksPkg in a16 ==='
rg -n 'hideBlueStacksPkg|bstIsCallingAppPrivileged|getAppNameFromPid' \
  "$A16/core/java/android/util/BstUtils.java" | head -20
echo '=== ATM getConfiguration / updateConfiguration anchors a16 ==='
rg -n 'getConfiguration|updateConfigurationLocked|reqGlEsVersion' \
  "$A16/services/core/java/com/android/server/wm/ActivityTaskManagerService.java" | head -30
