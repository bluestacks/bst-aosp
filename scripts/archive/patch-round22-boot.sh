#!/bin/bash
# Round 22: henry-aligned ADB (adbd_rooted_tiramisu) + bs_bootlog; drop apex-adbd initrd hack
set -e
AOSP=~/aosp16
BOOT=~/app-player/hd/guest/BootImage
OUT=~/aosp16/out_nxt_Baklava64/target/product/generic_x86_64
APEXD="$OUT/system/bin/apexd"
ADBD_ROOTED=~/app-player/tools/tiramisu/adbd_rooted_tiramisu
LOGCAT="$OUT/system/bin/logcat"

test -f "$ADBD_ROOTED" || { echo "missing $ADBD_ROOTED"; exit 1; }
test -f "$LOGCAT" || { echo "missing $LOGCAT"; exit 1; }

cp "$ADBD_ROOTED" "$BOOT/adbd-rooted"
chmod 755 "$BOOT/adbd-rooted"
cp ~/bs_bootlog.sh "$BOOT/bs_bootlog.sh"
chmod 755 "$BOOT/bs_bootlog.sh"

cp "$APEXD" "$BOOT/apexd-patched"
cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"

python3 - <<'PY'
from pathlib import Path
mk = Path.home() / "app-player/hd/guest/BootImage/Makefile"
text = mk.read_text()
# Remove apex-adbd duplicate lines from round 21
text = text.replace("\tcp -a apex-adbd initrd/boot/apex-adbd\n", "")
text = text.replace("\tcp -a apex-adbd initrd/boot/apex-adbd", "")
anchor = "\tcp adbkey.pub initrd/boot/adbkey.pub"
insert = anchor + """
\tcp adbd-rooted initrd/boot/bin/adbd
\tchmod 755 initrd/boot/bin/adbd
\tcp bs_bootlog.sh initrd/boot/bin/bs_bootlog.sh
\tchmod 755 initrd/boot/bin/bs_bootlog.sh
\tcp /home/clouddev/bst/workspace/markxu/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/system/bin/logcat initrd/boot/bin/logcat
\tchmod 755 initrd/boot/bin/logcat"""
if "initrd/boot/bin/adbd" not in text:
    if anchor not in text:
        raise SystemExit("Makefile adbkey anchor missing")
    text = text.replace(anchor, insert, 1)
    mk.write_text(text)
    print("Makefile: adbd-rooted + bs_bootlog + logcat")
else:
    mk.write_text(text)
    print("Makefile: adbd already present, cleaned apex-adbd")
PY

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -5
ls -la initrd/boot/bin/adbd initrd/boot/bin/bs_bootlog.sh initrd/boot/bin/logcat
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
echo ROUND22_DONE
