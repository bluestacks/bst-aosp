#!/bin/bash
# Round 31: /data sdb1 nodes + apexd tmpfs O_DIRECT fallback + runtime apex pre-mount
set -eo pipefail
AOSP=~/aosp16
BOOT=~/app-player/hd/guest/BootImage
APEXD_BIN=~/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/system/bin/apexd

python3 - <<'PY'
from pathlib import Path

# apexd: allow buffered I/O fallback on tmpfs (/data CAPEX decompress)
p = Path.home() / "aosp16/system/apex/apexd/apexd_loop.cpp"
text = p.read_text()
needle = """        (stbuf.f_type != EROFS_SUPER_MAGIC_V1 &&
         stbuf.f_type != SQUASHFS_MAGIC &&
         stbuf.f_type != OVERLAYFS_SUPER_MAGIC)) {"""
insert = """        (stbuf.f_type != EROFS_SUPER_MAGIC_V1 &&
         stbuf.f_type != SQUASHFS_MAGIC &&
         stbuf.f_type != OVERLAYFS_SUPER_MAGIC &&
         stbuf.f_type != 0x01021994)) {"""  # TMPFS_MAGIC
if "0x01021994" in text:
    print("apexd_loop tmpfs fallback already patched")
elif needle not in text:
    raise SystemExit("apexd_loop statfs anchor not found")
else:
    p.write_text(text.replace(needle, insert, 1))
    print("apexd_loop: tmpfs buffered-I/O fallback")

# init.sh: restore runtime apex pre-mount (linker64 before apexd-bootstrap)
p = Path.home() / "app-player/hd/guest/BootImage/init.sh"
t = p.read_text()
if "for apexname in com.android.runtime com.android.i18n" in t:
    print("init.sh runtime apex already pre-mounted")
elif "for apexname in com.android.runtime; do" not in t:
    raise SystemExit("init.sh apex loop block missing")
else:
  # only runtime — i18n left to apexd
    pass
if "# A16(baklava64): runtime/i18n owned by apexd-bootstrap" in t:
    # Re-insert apex pre-mount block before linkerconfig section
    old = """# A16(baklava64): runtime/i18n owned by apexd-bootstrap — do not pre-mount (LOOP_CONFIGURE EBUSY).
if [ "$bstandroid" == "baklava64" ]; then
\tif [ -f /boot/linkerconfig/ld.config.txt ]; then"""
    new = """# A16(baklava64): pre-mount runtime only (linker64); rest owned by apexd-bootstrap.
if [ "$bstandroid" == "baklava64" ]; then
\tAPEX_SRC=/system/apex
\tfind_free_loop()
\t{
\t\tn=0
\t\twhile [ $n -lt 48 ]; do
\t\t\tif [ ! -d /sys/block/loop$n/loop ]; then
\t\t\t\techo /dev/loop$n
\t\t\t\treturn 0
\t\t\tfi
\t\t\tn=`expr $n + 1`
\t\tdone
\t\treturn 1
\t}
\tfor apexname in com.android.runtime; do
\t\tapexfile=$APEX_SRC/$apexname.apex
\t\tif [ -f "$apexfile" ]; then
\t\t\tmkdir -p /apex/$apexname
\t\t\tloopdev=`find_free_loop`
\t\t\t/boot/bin/busybox losetup -o 4096 $loopdev "$apexfile"
\t\t\tif [ $? -ne 0 ]; then log_echo "WARNING: losetup apex $apexname failed"; continue; fi
\t\t\tmount -t erofs -o ro $loopdev /apex/$apexname || log_echo "WARNING: mount apex $apexname failed"
\t\t\techo "<0>A16DBG: mounted apex $apexname on $loopdev" > /dev/kmsg
\t\tfi
\tdone
\tif [ -f /boot/linkerconfig/ld.config.txt ]; then"""
    if old in t:
        p.write_text(t.replace(old, new, 1))
        print("init.sh: runtime apex pre-mount restored")
    else:
        print("init.sh: linkerconfig block pattern changed — skip apex restore")
PY

cd "$AOSP"
source build/envsetup.sh
lunch aosp_x86_64-trunk_staging-eng >/dev/null 2>&1
export OUT_DIR=out_nxt_Baklava64
prebuilts/build-tools/linux_musl-x86/bin/ninja -f out_nxt_Baklava64/combined-aosp_x86_64.ninja apexd 2>&1 | tail -5

cp "$APEXD_BIN" "$BOOT/apexd-patched"
cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh" 2>/dev/null || cp "$(dirname "$0")/stage2-good-vhd.sh" "$BOOT/stage2.sh"

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -2
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -2
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND31_DONE
