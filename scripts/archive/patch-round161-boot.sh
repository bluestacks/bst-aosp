#!/bin/bash
# Round 161: henry-7AJ crash_dump64 staging + henry-7j boringssl rc disable
set -e
AOSP=~/aosp16
BOOT=~/app-player/hd/guest/BootImage
CDMP="$AOSP/out_nxt_Baklava64/target/product/generic_x86_64/apex/com.android.runtime/bin/crash_dump64"

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
sed -i 's/\r$//' "$BOOT/stage2.sh"
cp "$CDMP" "$BOOT/crash_dump64-patched"
chmod 755 "$BOOT/crash_dump64-patched"

MK="$BOOT/Makefile"
if ! grep -q 'crash_dump64-patched initrd/boot/bin/crash_dump64' "$MK"; then
  sed -i '/cp linker64-runtime initrd\/boot\/bin\/linker64/a\\tcp crash_dump64-patched initrd/boot/bin/crash_dump64\n\tchmod 755 initrd/boot/bin/crash_dump64' "$MK"
fi

cd "$BOOT"
echo "7AJ=$(grep -c 'henry-7AJ' stage2.sh || true)"
echo "7j=$(grep -c 'henry-7j' stage2.sh || true)"
echo "crash_dump64 bytes=$(wc -c < crash_dump64-patched)"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -1
zcat initrd.img | cpio -t 2>/dev/null | grep crash_dump64
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND161_DONE
