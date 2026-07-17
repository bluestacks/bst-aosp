#!/bin/bash
# Save G1 hardware/bst HAL A16 compile fixes to tarball for local archive
set -euo pipefail
OUT=~/g1_hal_fixes.tar.gz
cd ~/aosp16/hardware/bst
tar czf "$OUT" \
  camera/3.0/ImageProcess.h \
  camera/3.0/CameraMetadata.cpp \
  memtrack/Android.mk \
  lights/Android.mk \
  power/Android.mk \
  audio/Android.mk
ls -la "$OUT"
echo G1_HAL_TAR_DONE
