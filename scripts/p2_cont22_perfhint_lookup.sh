#!/bin/bash
set +u
echo '=== PerfHintManager ==='
rg -n 'performance_hint|IPower|HintManager' ~/aosp16/frameworks/base/core/java/android/os/PerformanceHintManager.java 2>/dev/null | head -30
echo '=== HintManagerService ==='
rg -n 'performance_hint|addService|SERVICE_NAME' ~/aosp16/frameworks/base/services/core/java/com/android/server/power/hint/ 2>/dev/null | head -40
echo '=== who looks up aidl/performance_hint ==='
rg -n 'performance_hint' ~/aosp16/frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell/performance/ 2>/dev/null | head -30
echo '=== servicemanager / AIDL name ==='
rg -n '"performance_hint"' ~/aosp16/frameworks ~/aosp16/hardware/interfaces/power 2>/dev/null | head -40
echo '=== a13 power packages ==='
rg -n 'performance_hint|power-service|IPower' ~/app-player/android-13/device/bst 2>/dev/null | head -20
