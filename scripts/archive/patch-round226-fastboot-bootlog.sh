#!/bin/bash
# R226: Henry-path fastboot rebuild with correct KDIR + logcat + bs_bootlog initrd.
# No boot bypasses — diagnostic tooling only.
set -euo pipefail

KDIR=~/aosp16/kernel-a16
BOOT=~/app-player/hd/guest/BootImage
OUT=~/aosp16/out_nxt_Baklava64/target/product/generic_x86_64
RELEASE=~/releases/Baklava64
FASTBOOT_UUID=91b80c95-aa7d-459d-93e4-c479f5babbb7

test -f "$KDIR/arch/x86/boot/bzImage" || { echo "missing $KDIR/arch/x86/boot/bzImage"; exit 1; }
test -f "$KDIR/drivers/media/v4l2-core/videobuf-core.ko" || {
    echo "building videobuf-core.ko"
    make -C "$KDIR" M=drivers/media/v4l2-core modules
}
test -f "$KDIR/drivers/media/v4l2-core/videobuf-core.ko" || { echo "videobuf-core.ko still missing"; exit 1; }

LOGCAT="$OUT/system/bin/logcat"
RELEASE_LOGCAT=~/releases/Baklava64/system/bin/logcat
if [ ! -x "$LOGCAT" ] && [ -x "$RELEASE_LOGCAT" ]; then
    LOGCAT="$RELEASE_LOGCAT"
fi
if [ ! -x "$LOGCAT" ]; then
    LOGCAT=$(find ~/aosp16/out_nxt_Baklava64 -path "*/system/bin/logcat" -type f 2>/dev/null | head -1)
fi
if [ -z "${LOGCAT:-}" ] || [ ! -x "$LOGCAT" ]; then
    echo "building logcat module (may fail if soong regen blocked)"
    cd ~/aosp16
    # shellcheck disable=SC1091
    source build/envsetup.sh
    lunch aosp_x86_64-trunk_staging-eng
    ALLOW_MISSING_DEPENDENCIES=true OUT_DIR=out_nxt_Baklava64 m logcat || true
    LOGCAT="$OUT/system/bin/logcat"
    [ -x "$LOGCAT" ] || LOGCAT="$RELEASE_LOGCAT"
fi
if [ ! -x "$LOGCAT" ]; then
    echo "missing logcat at $LOGCAT" >&2
    exit 1
fi
echo "using logcat=$LOGCAT"
export LOGCAT

cp ~/bs_bootlog.sh "$BOOT/bs_bootlog.sh"
chmod 755 "$BOOT/bs_bootlog.sh"
sed -i 's/\r$//' "$BOOT/bs_bootlog.sh"

# R225 probe must run before exec /init (dead code after exec otherwise)
python3 - <<'PY'
from pathlib import Path
p = Path.home() / "app-player/hd/guest/BootImage/stage2.sh"
text = p.read_text()
probe = '''
# R225/R226: HST device probe for graphics bringup (before exec /init)
if [ -c /dev/bstpgaipc ]; then
  echo "<0>A16DBG: R226 /dev/bstpgaipc present $(ls -l /dev/bstpgaipc)" > /dev/kmsg
else
  echo "<3>A16DBG: R226 /dev/bstpgaipc MISSING" > /dev/kmsg
fi
'''
# Remove dead probe after exec /init if present
import re
text = re.sub(
    r"\n# R225: HST device probe.*?(?=\n*$|\Z)",
    "\n",
    text,
    flags=re.S,
)
anchor = 'echo "<0>A16DBG: stage2 about to exec /init'
if "R226 /dev/bstpgaipc" not in text:
    idx = text.find(anchor)
    if idx < 0:
        raise SystemExit("stage2 anchor missing")
    text = text[:idx] + probe + "\n" + text[idx:]
    p.write_text(text)
    print("stage2.sh: moved bstpgaipc probe before exec /init")
else:
    p.write_text(text)
    print("stage2.sh: probe already before exec /init")
PY

python3 - <<'PY'
from pathlib import Path
import os
mk = Path.home() / "app-player/hd/guest/BootImage/Makefile"
text = mk.read_text()
logcat = os.environ["LOGCAT"]
logcat_lines = (
    f"\tcp {logcat} initrd/boot/bin/logcat\n"
    f"\tchmod 755 initrd/boot/bin/logcat\n"
)
# Patch main initrd.img target (not initrd-hyperv.img)
anchor = "initrd.img: clean-initrd.img"
idx = text.find(anchor)
if idx < 0:
    raise SystemExit("initrd.img target missing")
section = text[idx:]
stage_anchor = "\tcp stage2.sh initrd/boot/stage2.sh\n"
sidx = section.find(stage_anchor)
if sidx < 0:
    raise SystemExit("stage2 anchor missing in initrd.img")
insert_at = idx + sidx + len(stage_anchor)
if "initrd/boot/bin/logcat" not in text[idx:idx + 800]:
    text = text[:insert_at] + logcat_lines + text[insert_at:]
    mk.write_text(text)
    print(f"Makefile initrd.img: added logcat from {logcat}")
else:
    import re
    # fix within initrd.img section only
    end = text.find("\n\n", idx + 100)
    chunk = text[idx:end if end > 0 else idx + 2000]
    new_chunk = re.sub(
        r"\tcp .* initrd/boot/bin/logcat\n\tchmod 755 initrd/boot/bin/logcat\n",
        logcat_lines,
        chunk,
        count=1,
    )
    if new_chunk != chunk:
        text = text[:idx] + new_chunk + text[idx + len(chunk):]
        mk.write_text(text)
        print(f"Makefile initrd.img: updated logcat path to {logcat}")
    else:
        print("Makefile initrd.img: logcat already present")
PY

cd "$BOOT"
make initrd.img KDIR="$KDIR" 2>&1 | tail -8
ls -la initrd/boot/bin/bs_bootlog.sh initrd/boot/bin/logcat
ls -la initrd/boot/bstmods/videobuf-core.ko
zcat initrd.img 2>/dev/null | cpio -t 2>/dev/null | grep -E 'bs_bootlog|logcat|videobuf' || true

make build_fastboot KDIR="$KDIR" 2>&1 | tail -8
test -f fastboot/fastboot.vdi || { echo "fastboot.vdi missing" >&2; exit 1; }
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi "$FASTBOOT_UUID"
md5sum fastboot/fastboot.vdi initrd.img
ls -la fastboot/fastboot.vdi

# Copy to release package
PKG=~/releases/Baklava64/bst-v5.22.210_Baklava64-local
mkdir -p "$PKG"
cp fastboot/fastboot.vdi "$PKG/fastboot.vdi"
echo "ROUND226_FASTBOOT_DONE"
