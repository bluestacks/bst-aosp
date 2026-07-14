#!/bin/bash
# Round 77: odsign bypass (7W) + pre-staged boot.art + init odsign skip
set -e
AOSP=~/aosp16
BOOT=~/app-player/hd/guest/BootImage
DALVIK_SRC=~/releases/Tiramisu64/system/framework/x86_64

python3 - <<'PY'
from pathlib import Path
p = Path.home() / "aosp16/system/core/init/service.cpp"
text = p.read_text()
odsign_skip = """    if (name_ == "odsign" && GetProperty("odsign.key.done", "") == "1") {
        LOG(WARNING) << "BS bringup skip odsign start (already stubbed)";
        return {};
    }

"""
if "BS bringup skip odsign start" not in text:
    needle = "Result<void> Service::Start() {\n    auto reboot_on_failure"
    if needle not in text:
        raise SystemExit("Start() patch anchor not found")
    text = text.replace(needle, "Result<void> Service::Start() {\n" + odsign_skip + "    auto reboot_on_failure", 1)
    print("service.cpp: re-added odsign skip")
else:
    print("service.cpp: odsign skip already present")
p.write_text(text)
PY

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
sed -i 's/\r$//' "$BOOT/stage2.sh"

mkdir -p "$BOOT/dalvik-cache/x86_64"
for f in "$DALVIK_SRC"/*; do
    [ -e "$f" ] || continue
    base=$(basename "$f")
    if [ -L "$f" ]; then
        cp -L "$f" "$BOOT/dalvik-cache/x86_64/$base" 2>/dev/null || true
    elif [ -f "$f" ]; then
        cp "$f" "$BOOT/dalvik-cache/x86_64/$base"
    fi
done
ls -la "$BOOT/dalvik-cache/x86_64/boot.art" "$BOOT/dalvik-cache/x86_64/boot.oat"

python3 - <<'PY'
from pathlib import Path
mk = Path.home() / "app-player/hd/guest/BootImage/Makefile"
text = mk.read_text()
dalvik_block = """
\tmkdir -p initrd/boot/dalvik-cache/x86_64
\t@test -f dalvik-cache/x86_64/boot.art && cp -a dalvik-cache/x86_64/. initrd/boot/dalvik-cache/x86_64/ || (echo "missing dalvik-cache/x86_64/boot.art" && exit 1)"""
anchor = "\tcp art-payload.img initrd/boot/art-payload.img"
if "initrd/boot/dalvik-cache" not in text:
    if anchor not in text:
        raise SystemExit("Makefile anchor not found")
    text = text.replace(anchor, anchor + dalvik_block, 1)
    mk.write_text(text)
    print("Makefile: added dalvik-cache COPY")
else:
    print("Makefile: dalvik-cache already present")
PY

cd "$AOSP"
source build/envsetup.sh
lunch aosp_x86_64-trunk_staging-eng >/dev/null 2>&1
export OUT_DIR=out_nxt_Baklava64
prebuilts/build-tools/linux_musl-x86/bin/ninja -f out_nxt_Baklava64/combined-aosp_x86_64.ninja init 2>&1 | tail -5
cp out_nxt_Baklava64/target/product/generic_x86_64/system/bin/init "$BOOT/init-patched"

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -5
zcat initrd.img | cpio -t 2>/dev/null | grep 'dalvik-cache.*boot.art'
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND77_DONE
