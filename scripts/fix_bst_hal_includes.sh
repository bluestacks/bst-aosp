#!/bin/bash
# Fix hardware/bst HAL Android.mk C_INCLUDES for A16
set -e
A=~/aosp16/hardware/bst/audio/Android.mk
if ! grep -q 'hardware/libhardware/include' "$A"; then
  sed -i '/external\/expat\/lib/a\	hardware/libhardware/include \' "$A"
fi
echo "audio:"; grep -A8 'LOCAL_C_INCLUDES' "$A" | head -9
