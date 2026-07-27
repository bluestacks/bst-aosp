#!/bin/bash
set +u
cd ~/aosp16
echo "=== power aidl tree ==="
ls hardware/interfaces/power/
ls hardware/interfaces/power/aidl 2>/dev/null
ls hardware/interfaces/power/aidl/default 2>/dev/null | head -30
echo "=== Android.bp modules mentioning power-service / hint ==="
grep -l 'android.hardware.power' hardware/interfaces/power/aidl/default/*.bp 2>/dev/null
cat hardware/interfaces/power/aidl/default/Android.bp 2>/dev/null | head -80
echo "=== goldfish/generic power ==="
ls device/generic/goldfish/power 2>/dev/null
ls device/generic/goldfish/*/power 2>/dev/null
grep -rn 'android.hardware.power\|performance_hint\|power-service' device/generic/goldfish --include='*.mk' --include='*.bp' --include='*.xml' 2>/dev/null | head -25
grep -rn 'android.hardware.power\|power-service' device/bst/qvirt 2>/dev/null | head -20
echo "=== PRODUCT_PACKAGES power in bst ==="
grep -n 'power\|hint' device/bst/qvirt/*.mk 2>/dev/null | head -30
echo "=== service list name in frameworks ==="
grep -n 'PERFORMANCE_HINT\|performance_hint' frameworks/base/core/java/android/content/Context.java 2>/dev/null | head -10
grep -n 'nativeCreateSession\|getService' frameworks/base/core/java/android/os/PerformanceHintManager.java 2>/dev/null | head -20
