#!/bin/bash
# Generate boot.art + boot-framework.* via host dex2oat (incremental bringup)
set -e
AOSP=~/aosp16
OUT="${1:-/tmp/boot-fw-gen}"
DEX2OAT=$AOSP/out_nxt_Baklava64/host/linux-x86/bin/dex2oat
PROF=$AOSP/out_nxt_Baklava64/target/product/generic_x86_64/system/etc/boot-image.prof
FW=$AOSP/out_nxt_Baklava64/target/product/generic_x86_64/system/framework/framework.jar
ART_PAYLOAD=~/app-player/hd/guest/BootImage/art-payload.img
MP=/tmp/art-mount-gen
sudo umount "$MP" 2>/dev/null || true
mkdir -p "$MP"
sudo mount -o loop,ro "$ART_PAYLOAD" "$MP"
CORE="$MP/javalib/core-oj.jar"
rm -rf "$OUT"
mkdir -p "$OUT/x86_64"
DIRTY=$AOSP/out_nxt_Baklava64/target/product/generic_x86_64/system/etc/dirty-image-objects
PRELOAD=$AOSP/out_nxt_Baklava64/target/product/generic_x86_64/system/etc/preloaded-classes
"$DEX2OAT" \
  --single-image \
  --force-allow-oj-inlines \
  --dex-file="$CORE" \
  --dex-location=/apex/com.android.art/javalib/core-oj.jar \
  --dex-file="$FW" \
  --dex-location=/system/framework/framework.jar \
  --instruction-set=x86_64 \
  --base=0x70000000 \
  --compiler-filter=speed-profile \
  --profile-file="$PROF" \
  --runtime-arg "-Xbootclasspath:/apex/com.android.art/javalib/core-oj.jar:/system/framework/framework.jar" \
  --runtime-arg "-Xbootclasspath-locations:/apex/com.android.art/javalib/core-oj.jar:/system/framework/framework.jar" \
  --dirty-image-objects="$DIRTY" \
  --avoid-storing-invocation \
  --generate-debug-info \
  --image-format=lz4hc \
  --android-root=out/empty \
  --image="$OUT/x86_64/boot.art" \
  --oat-file="$OUT/x86_64/boot.oat" \
  --oat-location="$OUT/x86_64/boot.oat"
sudo umount "$MP"
ls -la "$OUT/x86_64/"
echo GEN_BOOT_FRAMEWORK_DONE
