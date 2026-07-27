#!/bin/bash
# Extract a13 AMS BST hooks vs a16 for FW-AM-1 surgical port.
set +u
A13=~/app-player/android-13/frameworks/base
A16=~/aosp16/frameworks/base
AMS=services/core/java/com/android/server/am/ActivityManagerService.java
AS=services/core/java/com/android/server/am/ActiveServices.java
exec > >(tee ~/p2_fw_am_extract.log) 2>&1
echo "A16DBG:P2:FW-AM extract $(date -Is)"

echo '=== a13 AMS BST contexts ==='
rg -n -C4 'BstHostCall|BstUtils|BstFilter|bluestacks|BlueStacks|isAppLaunchAllowed|ActivityDisplayed|sendOrientation|onAppInstalled|onAppUninstalled|hideBlueStacks' \
  "$A13/$AMS" | head -200

echo '=== a16 AMS BST presence ==='
rg -n 'BstHostCall|BstUtils|BstFilter|A16DBG:P2' "$A16/$AMS" | head -40 || echo NONE

echo '=== a13 ActiveServices BST ==='
rg -n -C3 'BstHostCall|BstUtils|BstFilter|bluestacks' "$A13/$AS" | head -80

echo '=== a16 ActiveServices BST ==='
rg -n 'BstHostCall|BstUtils|BstFilter|A16DBG' "$A16/$AS" | head -20 || echo NONE

echo '=== hit counts ==='
echo -n "a13 AMS hits: "; rg -c 'BstHostCall|BstUtils|BstFilter' "$A13/$AMS" || echo 0
echo -n "a16 AMS hits: "; rg -c 'BstHostCall|BstUtils|BstFilter' "$A16/$AMS" || echo 0

echo EXTRACT_DONE
