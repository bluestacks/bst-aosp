#!/bin/bash
# Henry path: keep only gralloc.bst in vendor hw (remove AOSP ranchu/default duplicates).
# Reference: 10-aosp-repo-diff deletes hardware/libhardware/modules/gralloc;
# goldfish mmm installs gralloc.bst only.
set -euo pipefail
RELEASE="${1:-$HOME/releases/Baklava64}"
VENDOR_HW="$RELEASE/system/vendor/lib64/hw"
removed=0
for f in gralloc.android_x86_64.so gralloc.default.so; do
    if [ -f "$VENDOR_HW/$f" ]; then
        rm -f "$VENDOR_HW/$f"
        echo "removed $VENDOR_HW/$f"
        removed=$((removed + 1))
    fi
done
# 32-bit mirror if present
VENDOR_HW32="$RELEASE/system/vendor/lib/hw"
for f in gralloc.android_x86.so gralloc.default.so; do
    if [ -f "$VENDOR_HW32/$f" ]; then
        rm -f "$VENDOR_HW32/$f"
        echo "removed $VENDOR_HW32/$f"
        removed=$((removed + 1))
    fi
done
ls -la "$VENDOR_HW"/gralloc*.so 2>/dev/null || true
echo "PRUNE_GRALLOC_HW_DONE removed=$removed"
