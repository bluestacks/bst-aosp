#!/bin/bash
# Round 13: fix /data mount order + task_profiles.json in initrd
set -e
AOSP=~/aosp16
BOOT=~/app-player/hd/guest/BootImage
OUT=out_nxt_Baklava64/target/product/generic_x86_64

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
mkdir -p "$BOOT/initrd/boot/etc"
cp "$AOSP/$OUT/system/etc/task_profiles.json" "$BOOT/initrd/boot/etc/task_profiles.json"

python3 ~/fix-makefile-initrd.py 2>/dev/null || python3 - <<'PY'
from pathlib import Path
p = Path.home() / "app-player/hd/guest/BootImage/Makefile"
text = p.read_text()
if "task_profiles.json" not in text:
    text = text.replace(
        "cp /home/clouddev/bst/workspace/markxu/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/system/etc/cgroups.json initrd/boot/etc/cgroups.json",
        "cp /home/clouddev/bst/workspace/markxu/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/system/etc/cgroups.json initrd/boot/etc/cgroups.json\n"
        "\tcp /home/clouddev/bst/workspace/markxu/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/system/etc/task_profiles.json initrd/boot/etc/task_profiles.json",
    )
    p.write_text(text)
    print("Makefile patched for task_profiles.json")
PY

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
ls -la initrd/boot/etc/task_profiles.json fastboot/fastboot.vdi
echo ROUND13_DONE
