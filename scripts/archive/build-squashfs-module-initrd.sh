#!/bin/bash
# Build squashfs.ko module and pack into initrd for system.sfs mount (avoid full kernel rebuild).
set -euo pipefail
KDIR=~/aosp16/kernel-a16
CFG="$KDIR/.config"
BOOT=~/app-player/hd/guest/BootImage
MODDIR="$BOOT/initrd/boot/kmodules"

cd "$KDIR"
sed -i 's/^CONFIG_SQUASHFS=y/CONFIG_SQUASHFS=m/' "$CFG"
sed -i 's/# CONFIG_SQUASHFS is not set/CONFIG_SQUASHFS=m/' "$CFG"
grep -q '^CONFIG_SQUASHFS=m' "$CFG" || echo 'CONFIG_SQUASHFS=m' >> "$CFG"
for opt in CONFIG_SQUASHFS_XATTR CONFIG_SQUASHFS_ZLIB CONFIG_SQUASHFS_DECOMP_SINGLE; do
    sed -i "s/^# $opt is not set/$opt=y/" "$CFG" 2>/dev/null || true
    grep -q "^$opt=y" "$CFG" || echo "$opt=y" >> "$CFG"
done
make olddefconfig

echo "Building squashfs.ko..."
make M=fs/squashfs modules 2>&1 | tail -15
KO=fs/squashfs/squashfs.ko
[ -f "$KO" ] || { echo "squashfs.ko missing" >&2; exit 1; }
ls -la "$KO"

mkdir -p "$MODDIR"
cp -a "$KO" "$MODDIR/squashfs.ko"
# zlib deps if built as modules
for dep in zlib_deflate zlib_inflate; do
    [ -f "lib/$dep.ko" ] && cp -a "lib/$dep.ko" "$MODDIR/" || true
done
ls -la "$MODDIR/"

# init.sh: insmod squashfs before system.sfs mount
python3 - <<'PY'
from pathlib import Path
p = Path.home() / "app-player/hd/guest/BootImage/init.sh"
t = p.read_text()
needle = 'if [ -e /boot/android/android/system.sfs ]; then'
ins = """# Load squashfs for henry system.sfs path (kernel built without CONFIG_SQUASHFS=y)
if [ -f /boot/kmodules/squashfs.ko ]; then
\tlog_echo "Loading squashfs.ko"
\tinsmod /boot/kmodules/squashfs.ko 2>/dev/null || insmod /boot/kmodules/zlib_inflate.ko 2>/dev/null; insmod /boot/kmodules/zlib_deflate.ko 2>/dev/null; insmod /boot/kmodules/squashfs.ko
\techo "<0>A16DBG: squashfs.ko loaded" > /dev/kmsg
fi

if [ -e /boot/android/android/system.sfs ]; then"""
if "squashfs.ko loaded" in t:
    print("init.sh squashfs insmod already present")
else:
    if needle not in t:
        raise SystemExit("system.sfs anchor missing")
    t = t.replace(needle, ins, 1)
    p.write_text(t)
    print("init.sh: insmod squashfs.ko before system.sfs")
PY

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
cd "$BOOT"
make initrd.img KDIR="$KDIR" 2>&1 | tail -8
make build_fastboot KDIR="$KDIR" 2>&1 | tail -5
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
echo SQUASHFS_MODULE_INITRD_DONE
