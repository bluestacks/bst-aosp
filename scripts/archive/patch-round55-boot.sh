#!/bin/bash
# Round 55: skip linkerconfig in init-patched when golden ld.config in initrd; scratch-gaurav 7Q vndk strip
set -e
AOSP=~/aosp16
BOOT=~/app-player/hd/guest/BootImage
BC="$AOSP/system/core/init/builtins.cpp"

python3 - <<'PY'
from pathlib import Path
p = Path.home() / "aosp16/system/core/init/builtins.cpp"
text = p.read_text()
needle = "static Result<void> GenerateLinkerConfiguration() {"
skip = """
static Result<void> GenerateLinkerConfiguration() {
    if (access("/boot/linkerconfig/ld.config.txt", R_OK) == 0) {
        LOG(WARNING) << "BS bringup: skip linkerconfig binary, install golden from initrd";
        InstallBootstrapLinkerConfigFromBoot();
        return {};
    }
"""
if "skip linkerconfig binary" in text:
    print("builtins.cpp: skip already present")
elif needle in text:
    text = text.replace(needle, skip, 1)
    p.write_text(text)
    print("builtins.cpp: skip linkerconfig when golden present")
else:
    raise SystemExit("GenerateLinkerConfiguration anchor missing")
PY

# Henry 7Q: comment ro.vndk.version in scratch-gaurav baklava props (source fix for rebuild)
SG=~/app-player/scratch-gaurav/misc_x86_64/baklava
if [ -d "$SG" ]; then
    find "$SG" -type f -exec grep -l '^ro\.vndk\.version=' {} \; 2>/dev/null | while read f; do
        sed -i 's/^ro\.vndk\.version=/#ro.vndk.version=/' "$f"
    done
    echo "scratch-gaurav: ro.vndk.version commented"
fi

cd "$AOSP"
source build/envsetup.sh
lunch aosp_x86_64-trunk_staging-eng >/dev/null 2>&1
export OUT_DIR=out_nxt_Baklava64
prebuilts/build-tools/linux_musl-x86/bin/ninja -f out_nxt_Baklava64/combined-aosp_x86_64.ninja init 2>&1 | tail -5

cp out_nxt_Baklava64/target/product/generic_x86_64/system/bin/init "$BOOT/init-patched"
cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -4
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND55_DONE
