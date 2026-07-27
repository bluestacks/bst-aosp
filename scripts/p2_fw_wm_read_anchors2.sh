#!/bin/bash
set +u
A16=~/aosp16/frameworks/base
A13=~/app-player/android-13/frameworks/base
echo '=== a16 executeRequest early section ==='
sed -n '1028,1220p' "$A16/services/core/java/com/android/server/wm/ActivityStarter.java"
echo '=== a13 GRM+hide context line numbers ==='
rg -n 'bstCheckGrm|hideBlueStacksPkg|mBstHostCallManagerService|Show grm' \
  "$A13/services/core/java/com/android/server/wm/ActivityStarter.java"
echo '=== a16 ATM around reqGlEsVersion ==='
sed -n '1160,1210p' "$A16/services/core/java/com/android/server/wm/ActivityTaskManagerService.java"
echo '=== a13 ATM gl block full ==='
rg -n -B5 -A40 'getGlVersion' \
  "$A13/services/core/java/com/android/server/wm/ActivityTaskManagerService.java" | head -60
