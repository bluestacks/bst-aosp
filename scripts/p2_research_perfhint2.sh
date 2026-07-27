#!/bin/bash
set +u
# Narrow finds only — avoid full-tree rg under load
cd ~/aosp16 || exit 1
echo "=== find PerfHint* ==="
find frameworks/base/libs/WindowManager/Shell -name '*PerfHint*' 2>/dev/null
find frameworks/base/packages/SystemUI -name '*PerfHint*' 2>/dev/null | head
echo "=== find performance_hint service ==="
find hardware device system -name '*performance_hint*' 2>/dev/null | head -30
find hardware/interfaces -path '*power*' -name '*.aidl' 2>/dev/null | head -40
echo "=== VINTF / manifests mention ==="
grep -r 'performance_hint' device/bst device/generic/common hardware/interfaces/power 2>/dev/null | head -30
echo "=== ENABLE_SHELL_TRANSITIONS current ==="
grep -n 'ENABLE_SHELL_TRANSITIONS' frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell/transition/Transitions.java | head -5
echo "=== DisplayRotation BST marker ==="
grep -n 'BST_DEBUG_ORIENTATION\|FIXED_TO_USER_ROTATION_DISABLED' frameworks/base/services/core/java/com/android/server/wm/DisplayRotation.java | head -8
echo "=== done ==="
