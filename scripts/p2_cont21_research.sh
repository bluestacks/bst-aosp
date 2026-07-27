#!/bin/bash
set -uo pipefail
echo "=== a13 device trees ==="
ls ~/app-player/android-13/device/generic/common/ | head -40
ls ~/app-player-mac/android-mac/device/bst/qvirt/ 2>/dev/null | head -40 || echo "no mac qvirt"
echo "=== a16 do_exec vdc ==="
rg -n "vdc|/vdc|do_exec" ~/aosp16/system/core/init/builtins.cpp | head -40
echo "=== CheckMacPerms / IsEnforcing ==="
rg -n "CheckMacPerms|IsEnforcing|return true|permissive|A16DBG|TEMP|skip" ~/aosp16/system/core/init/property_service.cpp ~/aosp16/system/core/init/selinux.cpp ~/aosp16/system/core/init/builtins.cpp 2>/dev/null | head -50
echo "=== a13 selinux enabled.c diff ==="
git -C ~/app-player/android-13/external/selinux diff android-13.0.0_r49..HEAD -- libselinux/src/enabled.c || true
echo "=== goldfish presentFence ==="
rg -n "presentFence|PresentFence|getPresentFence" ~/ggl/goldfish-opengl-pie/system/hwc2 -g "*.cpp" 2>/dev/null | head -25 || true
echo "=== a13 DisplayRotation ==="
git -C ~/app-player/android-13/frameworks/base diff --numstat android-13.0.0_r49..HEAD -- services/core/java/com/android/server/wm/DisplayRotation.java
echo "=== a13 fstab.x86 head ==="
head -40 ~/app-player/android-13/device/generic/common/fstab.x86 2>/dev/null || true
echo "=== a16 fstab.baklava / fstab ==="
ls ~/aosp16/device/generic/common/fstab* 2>/dev/null
head -40 ~/aosp16/device/generic/common/fstab.baklava 2>/dev/null || head -40 ~/aosp16/device/generic/common/fstab.x86 2>/dev/null || true
echo "DONE_RESEARCH"
