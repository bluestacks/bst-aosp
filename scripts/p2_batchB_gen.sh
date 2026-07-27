#!/bin/bash
# P2-FRAMEWORK-REST Batch B: HostCall/gcall JNI bridge delta (fork vs a16)
set -euo pipefail
LOG=~/p2_batchB_gen.log
exec > >(tee "$LOG") 2>&1
A13=~/app-player/android-13/frameworks/base
A16=~/aosp16/frameworks/base
OUT=~/bst-aosp/patches/android-16/patches/p2-framework-rest
mkdir -p "$OUT"

echo "A16DBG:P2:batchB gen start $(date -Is)"
# Upstream tag for win fork
cd "$A13"
TAG=$(git tag --list 'android-13.0.0_r*' --sort=version:refname | tail -1)
echo "UPSTREAM_TAG=$TAG"

# Batch B path set: hostcall managers + JNI + SystemServiceRegistry hooks already partially in G5
PATHS=(
  core/java/com/bluestacks/os/BstHostCallCcCodes.java
  core/java/com/bluestacks/os/BstHostCallManager.java
  core/java/com/bluestacks/os/IBstHostCallService.aidl
  core/java/com/bluestacks/os/BstFilterAppsManager.java
  core/java/com/bluestacks/os/IBstFilterAppsService.aidl
  core/java/com/bluestacks/os/BstUtilsManager.java
  core/java/com/bluestacks/os/IBstUtilsService.aidl
)

# Diff each file fork HEAD vs a16 current (overlay style)
rm -f "$OUT/p2_fw_batchB_overlay.patch"
for rel in "${PATHS[@]}"; do
  if [ ! -f "$A13/$rel" ]; then echo "MISS_A13 $rel"; continue; fi
  if [ ! -f "$A16/$rel" ]; then
    echo "NEW_ON_A16 $rel"
    mkdir -p "$(dirname "$A16/$rel")"
    # generate as new file patch from /dev/null
    diff -u /dev/null "$A13/$rel" | sed "1s|.*|--- /dev/null|;2s|.*|+++ b/$rel|" >> "$OUT/p2_fw_batchB_overlay.patch" || true
  else
    if ! diff -q "$A13/$rel" "$A16/$rel" >/dev/null; then
      echo "DELTA $rel"
      diff -u "$A16/$rel" "$A13/$rel" | sed "1s|.*|--- a/$rel|;2s|.*|+++ b/$rel|" >> "$OUT/p2_fw_batchB_overlay.patch" || true
    else
      echo "SAME $rel"
    fi
  fi
done

# Also capture JNI / native hostcall if present
for rel in \
  core/jni/android_os_BstHostCall.cpp \
  core/jni/com_bluestacks_os_BstHostCall.cpp \
  services/core/jni/com_android_server_BstHostCall.cpp
 do
  [ -f "$A13/$rel" ] || continue
  echo "JNI_CANDIDATE $rel"
  if [ ! -f "$A16/$rel" ]; then
    diff -u /dev/null "$A13/$rel" | sed "1s|.*|--- /dev/null|;2s|.*|+++ b/$rel|" >> "$OUT/p2_fw_batchB_overlay.patch" || true
  elif ! diff -q "$A13/$rel" "$A16/$rel" >/dev/null; then
    diff -u "$A16/$rel" "$A13/$rel" | sed "1s|.*|--- a/$rel|;2s|.*|+++ b/$rel|" >> "$OUT/p2_fw_batchB_overlay.patch" || true
  fi
done

wc -l "$OUT/p2_fw_batchB_overlay.patch" || echo "empty patch"
echo "A16DBG:P2:batchB gen DONE $(date -Is)"
