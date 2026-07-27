#!/bin/bash
set +u
echo "=== load ==="
uptime
echo "=== PerfHintController / performance_hint in SystemUI ==="
rg -n 'PerfHintController|performance_hint|IHintManager|HintManager' \
  ~/aosp16/frameworks/base/packages/SystemUI/src \
  ~/aosp16/frameworks/base/libs/WindowManager/Shell \
  2>/dev/null | head -50
echo "=== HAL manifests / interfaces ==="
rg -n 'performance_hint|power\.hint|IPowerHint|android.hardware.power.hint' \
  ~/aosp16/hardware/interfaces \
  ~/aosp16/device/bst \
  ~/aosp16/device/generic \
  2>/dev/null | head -40
echo "=== PRODUCT packages hint ==="
rg -n 'performance_hint|powerhint|PowerHint' \
  ~/aosp16/device/bst/qvirt \
  ~/aosp16/device/generic/common \
  2>/dev/null | head -30
echo "=== r262 patch presence ==="
rg -n 'ENABLE_SHELL_TRANSITIONS|shell_transitions' \
  ~/aosp16/frameworks/base/core/java/com/android/internal/os/RoSystemProperties.java \
  ~/aosp16/frameworks/base/libs/WindowManager/Shell \
  2>/dev/null | head -20
ls ~/bst-aosp/patches/android-16/patches/*r262* 2>/dev/null
echo "=== a13 bst tree? ==="
ls -d ~/aosp13 ~/app-player/android-13 /home/clouddev/bst/workspace/*/android-13 2>/dev/null | head -10
