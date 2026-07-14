#!/bin/bash
# Round 68: statsd libs in Makefile initrd + stage2 cat to /data/statsd-libs
set -e
AOSP=~/aosp16
BOOT=~/app-player/hd/guest/BootImage
PRODUCT_OUT=$AOSP/out_nxt_Baklava64/target/product/generic_x86_64

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
cp ~/init.sh.remote "$BOOT/init.sh" 2>/dev/null || true
sed -i 's/\r$//' "$BOOT/stage2.sh" "$BOOT/init.sh"

python3 - <<'PY'
from pathlib import Path
mk = Path.home() / "app-player/hd/guest/BootImage/Makefile"
text = mk.read_text()
statsd_block = """
\tmkdir -p initrd/boot/statsd-libs
\t@test -f /home/clouddev/bst/workspace/markxu/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/apex/com.android.os.statsd/lib64/libstatspull.so && \\
\t\tcp /home/clouddev/bst/workspace/markxu/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/apex/com.android.os.statsd/lib64/libstatspull.so initrd/boot/statsd-libs/ || true
\t@test -f /home/clouddev/bst/workspace/markxu/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/apex/com.android.os.statsd/lib64/libstatssocket.so && \\
\t\tcp /home/clouddev/bst/workspace/markxu/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/apex/com.android.os.statsd/lib64/libstatssocket.so initrd/boot/statsd-libs/ || true"""
if "initrd/boot/statsd-libs" not in text:
    anchor = "initrd/boot/vendor_hw/ || true"
    if anchor not in text:
        raise SystemExit("Makefile keymint xml anchor missing")
    text = text.replace(anchor, anchor + statsd_block, 1)
    mk.write_text(text)
    print("Makefile: added statsd-libs")
else:
    print("Makefile: statsd-libs already present")
PY

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -4
echo "--- cpio verify ---"
zcat initrd.img | cpio -t 2>/dev/null | grep statsd
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND68_DONE
