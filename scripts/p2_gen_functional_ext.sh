#!/bin/bash
# Generate boringssl + icu patches (do not apply while systemimage runs)
set -euo pipefail
OUT=~/bst-aosp/patches/android-16/patches/p2-external
mkdir -p "$OUT"
LOG=~/p2_gen_functional_ext.log
exec > >(tee "$LOG") 2>&1
echo "A16DBG:P2:gen functional external start $(date -Is)"

cd ~/app-player/android-13/external/boringssl
TAG=$(git tag --list 'android-13.0.0_r*' --sort=version:refname | tail -1)
git diff "$TAG"..HEAD > "$OUT/a13__boringssl__bst.patch"
git diff --stat "$TAG"..HEAD

cd ~/app-player/android-13/external/icu
TAG=$(git tag --list 'android-13.0.0_r*' --sort=version:refname | tail -1)
git diff "$TAG"..HEAD -- \
  android_icu4j/libcore_bridge/src/java/com/android/i18n/timezone/ZoneInfoData.java \
  android_icu4j/src/main/java/android/icu/impl/OlsonTimeZone.java \
  > "$OUT/a13__icu__ROB14898-iran-tz.patch"
git diff --stat "$TAG"..HEAD -- \
  android_icu4j/libcore_bridge/src/java/com/android/i18n/timezone/ZoneInfoData.java \
  android_icu4j/src/main/java/android/icu/impl/OlsonTimeZone.java

ls -la "$OUT"
echo "A16DBG:P2:gen functional external DONE $(date -Is)"
