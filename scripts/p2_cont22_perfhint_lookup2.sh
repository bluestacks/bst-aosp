#!/bin/bash
set +u
ls ~/aosp16/frameworks/base/services/core/java/com/android/server/power/hint/ 2>/dev/null
echo '=== HintManagerService ==='
rg -n 'SERVICE_NAME|performance_hint|addService|publishBinder' \
  ~/aosp16/frameworks/base/services/core/java/com/android/server/power/hint/HintManagerService.java 2>/dev/null | head -40
echo '=== jni ==='
rg -n 'performance_hint|IHintManager|ServiceManager' \
  ~/aosp16/frameworks/base/core/jni/android_os_PerformanceHintManager.cpp 2>/dev/null | head -30
echo '=== native tipc ==='
rg -n 'performance_hint' ~/aosp16/frameworks/native/libs/powerhintsession 2>/dev/null | head -20
rg -n 'performance_hint' ~/aosp16/system/libhwbinder ~/aosp16/frameworks/native/libs/binder 2>/dev/null | head -10
echo '=== SystemServer start ==='
rg -n 'HintManager|performance_hint' \
  ~/aosp16/frameworks/base/services/java/com/android/server/SystemServer.java 2>/dev/null | head -20
echo '=== PerfHintController ==='
rg -n 'PerformanceHint|createHintSession|onInit' \
  ~/aosp16/frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell/performance/PerfHintController.kt 2>/dev/null | head -40
