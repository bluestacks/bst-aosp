#!/bin/bash
set +u
A16=~/aosp16/frameworks/base
A13=~/app-player/android-13/frameworks/base
AMS=services/core/java/com/android/server/am/ActivityManagerService.java
AS=services/core/java/com/android/server/am/ActiveServices.java

echo '=== a16 getMemoryInfo ==='
rg -n 'void getMemoryInfo|getMemoryInfo\(' "$A16/$AMS" | head -15
rg -n -A35 'public void getMemoryInfo' "$A16/$AMS" | head -50

echo '=== a13 getMemoryInfo full BST block ==='
rg -n -B5 -A55 'fakeTotalMem|getMemorySize' "$A13/$AMS" | head -80

echo '=== a16 getRunningServiceInfo / getServices ==='
rg -n 'getRunningServiceInfoLocked|RunningServiceInfo' "$A16/$AS" | head -20

echo '=== a16 locale change host? ==='
rg -n 'onLocaleChanged|persist.sys.locale|ACTION_LOCALE' "$A16/$AMS" | head -20

echo '=== a13 locale block ==='
rg -n -B10 -A15 'onLocaleChanged' "$A13/$AMS" | head -50
