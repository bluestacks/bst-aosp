#!/bin/bash
# Inventory G8 hardware/bst presence a13 vs a16
set +u
exec > >(tee ~/p2_g8_inventory.log) 2>&1
echo "A16DBG:P2:G8 inventory $(date -Is)"
for d in audio camera lights memtrack power; do
  echo "=== hardware/bst/$d ==="
  echo -n "a13: "; ls -d ~/app-player/android-13/hardware/bst/$d 2>/dev/null || echo MISSING
  echo -n "a16: "; ls -d ~/aosp16/hardware/bst/$d 2>/dev/null || echo MISSING
  if [ -d ~/app-player/android-13/hardware/bst/$d ]; then
    find ~/app-player/android-13/hardware/bst/$d -type f | wc -l
    ls ~/app-player/android-13/hardware/bst/$d | head -20
  fi
done
echo '=== product packages referencing bst HALs ==='
rg -n 'hardware/bst|bst.audio|bst.power|bst.camera|bst.lights|bst.memtrack' \
  ~/aosp16/device/bst ~/app-player/android-13/device 2>/dev/null | head -40
echo '=== a13 treble/product ==='
rg -n 'bst/(audio|power|camera|lights|memtrack)|android.hardware.audio|PRODUCT_PACKAGES' \
  ~/app-player/android-13/device/bst 2>/dev/null | head -40
echo DONE
