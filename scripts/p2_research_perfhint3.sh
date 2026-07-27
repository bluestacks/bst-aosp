#!/bin/bash
set +u
cd ~/aosp16
# Direct path probes (no find/rg)
for p in \
  frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell/shared/bubbles \
  frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell \
  frameworks/base/core/java/android/os/PerformanceHintManager.java \
  frameworks/base/core/java/android/os/HintManager.java \
  hardware/interfaces/power \
  hardware/google/pixel/powerhint \
  hardware/interfaces/thermal \
  system/hardware/interfaces/power \
  packages/modules/PowerStats \
  device/google/cuttlefish/hal/power
 do
  if [ -e "$p" ]; then echo "EXISTS $p"; ls -la "$p" 2>/dev/null | head -5; else echo "MISS $p"; fi
done
echo "=== shell tree top ==="
ls frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell/ 2>/dev/null | head -40
echo "=== grep PerfHint in Transitions dir only ==="
grep -rn 'PerfHint\|performance_hint\|PerformanceHint' frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell/sysui 2>/dev/null | head -20
grep -rn 'PerfHint\|PerformanceHint' frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell --include='*.java' 2>/dev/null | head -40
echo DONE
