#!/bin/bash
# Generate boot-framework.{art,oat,vdex} as secondary boot image component (Round 99)
set -e
AOSP=~/aosp16
OUT="${1:-/tmp/boot-fw-only}"
ART_BOOT=$AOSP/out_nxt_Baklava64/host/linux-x86/apex/art_boot_images/javalib/x86_64
DEX2OAT=$AOSP/out_nxt_Baklava64/host/linux-x86/bin/dex2oat
FW=$AOSP/out_nxt_Baklava64/target/product/generic_x86_64/system/framework/framework.jar
PROF=$AOSP/out_nxt_Baklava64/target/product/generic_x86_64/system/etc/boot-image.prof
DIRTY=$AOSP/out_nxt_Baklava64/target/product/generic_x86_64/system/etc/dirty-image-objects
ART_PAYLOAD=~/app-player/hd/guest/BootImage/art-payload.img
MP=/tmp/art-mount-fw

sudo umount "$MP" 2>/dev/null || true
mkdir -p "$MP" "$OUT/x86_64"
sudo mount -o loop,ro "$ART_PAYLOAD" "$MP"

BI="$ART_BOOT/boot.art"
for comp in boot-apache-xml boot-bouncycastle boot-conscrypt boot-core-icu4j boot-core-libart boot-okhttp; do
    BI="$BI:$ART_BOOT/${comp}.art"
done

echo "Boot image chain: $BI"

"$DEX2OAT" \
  --dex-file="$FW" \
  --dex-location=/system/framework/framework.jar \
  --instruction-set=x86_64 \
  --compiler-filter=speed-profile \
  --profile-file="$PROF" \
  --boot-image="$BI" \
  --runtime-arg "-Xbootclasspath:/apex/com.android.art/javalib/core-oj.jar:/system/framework/framework.jar" \
  --runtime-arg "-Xbootclasspath-locations:/apex/com.android.art/javalib/core-oj.jar:/system/framework/framework.jar" \
  --dirty-image-objects="$DIRTY" \
  --avoid-storing-invocation \
  --generate-debug-info \
  --image-format=lz4hc \
  --android-root=out/empty \
  --image="$OUT/x86_64/boot-framework.art" \
  --oat-file="$OUT/x86_64/boot-framework.oat" \
  --oat-location=/system/framework/x86_64/boot-framework.oat

sudo umount "$MP"
ls -la "$OUT/x86_64/"
echo GEN_BOOT_FW_ONLY_DONE
