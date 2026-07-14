#!/bin/bash
# Round 64: VINTF keymint manifest + build.prop cat overwrite + vendor lib diag
set -e
BOOT=~/app-player/hd/guest/BootImage
PRODUCT_OUT=~/aosp16/out_nxt_Baklava64/target/product/generic_x86_64

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh" 2>/dev/null || \
    cp "$(dirname "$0")/stage2-good-vhd.sh" "$BOOT/stage2.sh"
sed -i 's/\r$//' "$BOOT/stage2.sh"

mkdir -p "$BOOT/initrd/boot/vendor_hw" "$BOOT/initrd/boot/vendor_lib64"
cp "$PRODUCT_OUT/vendor/bin/hw/android.hardware.security.keymint-service" "$BOOT/initrd/boot/vendor_hw/"
chmod 755 "$BOOT/initrd/boot/vendor_hw/android.hardware.security.keymint-service"
for lib in libkeymint.so libpuresoftkeymasterdevice.so lib_android_keymaster_keymint_utils.so; do
    [ -f "$PRODUCT_OUT/vendor/lib64/$lib" ] && \
        cp "$PRODUCT_OUT/vendor/lib64/$lib" "$BOOT/initrd/boot/vendor_lib64/"
done

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -4
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND64_DONE
