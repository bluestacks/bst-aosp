#!/bin/bash
set -e
for f in memtrack power; do
  mk=~/aosp16/hardware/bst/$f/Android.mk
  if ! grep -q 'libsystem/include' "$mk"; then
    sed -i '/hardware\/libhardware\/include/a\    system/core/libsystem/include \' "$mk"
  fi
  echo "== $f =="; grep -A5 LOCAL_C_INCLUDES "$mk"
done
