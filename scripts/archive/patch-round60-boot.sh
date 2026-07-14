#!/bin/bash
# Round 60: KeyMint HAL (henry 7R layer 3) + keystore2 kmsg + build.prop remount fix + scratch props
set -e
AOSP=~/aosp16
BOOT=~/app-player/hd/guest/BootImage
PRODUCT_OUT=$AOSP/out_nxt_Baklava64/target/product/generic_x86_64
SG=~/app-player/scratch-gaurav/misc_x86_64/baklava

# Henry 7P/7Q at image source (offline path; runtime patch remains fallback)
for f in "$SG"/baklava.bluestacks.prop.us "$SG"/additional_system_props/*; do
    [ -f "$f" ] || continue
    /bin/sed -i '/^ro\.vndk\.version=/d' "$f" 2>/dev/null || true
    if ! grep -q '^ro\.apex\.updatable=' "$f" 2>/dev/null; then
        echo 'ro.apex.updatable=true' >> "$f"
    fi
done
echo "scratch-gaurav: stripped ro.vndk.version, added ro.apex.updatable"

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh" 2>/dev/null || \
    cp "$(dirname "$0")/stage2-good-vhd.sh" "$BOOT/stage2.sh"

# Ensure keymint HAL built
cd "$AOSP"
source build/envsetup.sh
lunch aosp_x86_64-trunk_staging-eng >/dev/null 2>&1
export OUT_DIR=out_nxt_Baklava64
m android.hardware.security.keymint-service 2>&1 | tail -5

mkdir -p "$BOOT/initrd/boot/vendor_hw" "$BOOT/initrd/boot/vendor_lib64"
cp "$PRODUCT_OUT/vendor/bin/hw/android.hardware.security.keymint-service" "$BOOT/initrd/boot/vendor_hw/"
chmod 755 "$BOOT/initrd/boot/vendor_hw/android.hardware.security.keymint-service"
cp "$PRODUCT_OUT/vendor/lib64/libkeymint.so" "$PRODUCT_OUT/vendor/lib64/libpuresoftkeymasterdevice.so" \
    "$BOOT/initrd/boot/vendor_lib64/" 2>/dev/null || true
cp "$AOSP/hardware/interfaces/security/keymint/aidl/default/android.hardware.security.keymint-service.xml" \
    "$BOOT/initrd/boot/vendor_hw/"

python3 - <<'PY'
from pathlib import Path
mk = Path.home() / "app-player/hd/guest/BootImage/Makefile"
text = mk.read_text()
block = """
\tmkdir -p initrd/boot/vendor_hw initrd/boot/vendor_lib64
\tcp -a initrd/boot/vendor_hw initrd/boot/vendor_hw 2>/dev/null || true"""
# idempotent: add vendor_hw copy lines after adbkey if missing
vendor_lines = """
\tmkdir -p initrd/boot/vendor_hw initrd/boot/vendor_lib64
\t@test -f /home/clouddev/bst/workspace/markxu/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/vendor/bin/hw/android.hardware.security.keymint-service && \\
\t\tcp /home/clouddev/bst/workspace/markxu/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/vendor/bin/hw/android.hardware.security.keymint-service initrd/boot/vendor_hw/ && \\
\t\tchmod 755 initrd/boot/vendor_hw/android.hardware.security.keymint-service || true
\t@test -f /home/clouddev/bst/workspace/markxu/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/vendor/lib64/libkeymint.so && \\
\t\tcp /home/clouddev/bst/workspace/markxu/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/vendor/lib64/libkeymint.so initrd/boot/vendor_lib64/ || true
\t@test -f /home/clouddev/bst/workspace/markxu/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/vendor/lib64/libpuresoftkeymasterdevice.so && \\
\t\tcp /home/clouddev/bst/workspace/markxu/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/vendor/lib64/libpuresoftkeymasterdevice.so initrd/boot/vendor_lib64/ || true
\t@test -f /home/clouddev/bst/workspace/markxu/aosp16/hardware/interfaces/security/keymint/aidl/default/android.hardware.security.keymint-service.xml && \\
\t\tcp /home/clouddev/bst/workspace/markxu/aosp16/hardware/interfaces/security/keymint/aidl/default/android.hardware.security.keymint-service.xml initrd/boot/vendor_hw/ || true"""
if "initrd/boot/vendor_hw/android.hardware.security.keymint-service" not in text:
    anchor = "\tcp adbkey.pub initrd/boot/adbkey.pub"
    if anchor not in text:
        raise SystemExit("Makefile adbkey anchor missing")
    text = text.replace(anchor, anchor + vendor_lines, 1)
    mk.write_text(text)
    print("Makefile: keymint HAL in initrd")
else:
    print("Makefile: keymint HAL already present")
PY

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -5
ls -la initrd/boot/vendor_hw/ initrd/boot/vendor_lib64/ 2>/dev/null | head -10
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND60_DONE
