#!/bin/bash
# Round 63: keymint vendor lib_android_keymaster_keymint_utils + build.prop rm/cp
set -e
AOSP=~/aosp16
BOOT=~/app-player/hd/guest/BootImage
PRODUCT_OUT=$AOSP/out_nxt_Baklava64/target/product/generic_x86_64

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh" 2>/dev/null || \
    cp "$(dirname "$0")/stage2-good-vhd.sh" "$BOOT/stage2.sh"
# Windows scp may introduce CRLF → ash syntax error at line 24 (for/do)
sed -i 's/\r$//' "$BOOT/stage2.sh"
[ -f ~/stage2-good-vhd.sh ] && sed -i 's/\r$//' ~/stage2-good-vhd.sh

mkdir -p "$BOOT/initrd/boot/vendor_hw" "$BOOT/initrd/boot/vendor_lib64"
cp "$PRODUCT_OUT/vendor/bin/hw/android.hardware.security.keymint-service" "$BOOT/initrd/boot/vendor_hw/"
chmod 755 "$BOOT/initrd/boot/vendor_hw/android.hardware.security.keymint-service"
for lib in libkeymint.so libpuresoftkeymasterdevice.so lib_android_keymaster_keymint_utils.so; do
    [ -f "$PRODUCT_OUT/vendor/lib64/$lib" ] && \
        cp "$PRODUCT_OUT/vendor/lib64/$lib" "$BOOT/initrd/boot/vendor_lib64/"
done
cp "$AOSP/hardware/interfaces/security/keymint/aidl/default/android.hardware.security.keymint-service.xml" \
    "$BOOT/initrd/boot/vendor_hw/" 2>/dev/null || true
ls -la "$BOOT/initrd/boot/vendor_lib64/"

python3 - <<'PY'
from pathlib import Path
mk = Path.home() / "app-player/hd/guest/BootImage/Makefile"
text = mk.read_text()
utils_line = "\t@test -f /home/clouddev/bst/workspace/markxu/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/vendor/lib64/lib_android_keymaster_keymint_utils.so && \\\n\t\tcp /home/clouddev/bst/workspace/markxu/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/vendor/lib64/lib_android_keymaster_keymint_utils.so initrd/boot/vendor_lib64/ || true"
if "lib_android_keymaster_keymint_utils.so" not in text:
    anchor = "libpuresoftkeymasterdevice.so initrd/boot/vendor_lib64/ || true"
    if anchor not in text:
        raise SystemExit("Makefile puresoft anchor missing")
    text = text.replace(anchor, anchor + "\n" + utils_line, 1)
    mk.write_text(text)
    print("Makefile: added keymint_utils lib")
else:
    print("Makefile: keymint_utils already present")
PY

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -4
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND63_DONE
