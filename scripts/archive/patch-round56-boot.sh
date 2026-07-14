#!/bin/bash
# Round 56: henry 7R — restore earlyBootEnded + real odsign + ro.apex.updatable
set -e
AOSP=~/aosp16
BOOT=~/app-player/hd/guest/BootImage

python3 - <<'PY'
from pathlib import Path
p = Path.home() / "aosp16/system/core/init/service.cpp"
text = p.read_text()
# Remove earlyBootEnded skip (keep art_boot skip only)
old = """Result<void> Service::ExecStart() {
    if (name_.find("keymaster earlyBootEnded") != std::string::npos ||
        name_ == "art_boot") {
        LOG(WARNING) << "BS bringup skip exec: " << name_;
        flags_ |= SVC_ONESHOT;
        was_last_exit_ok_ = true;
        return {};
    }
"""
new = """Result<void> Service::ExecStart() {
    if (name_ == "art_boot") {
        LOG(WARNING) << "BS bringup skip exec: " << name_;
        flags_ |= SVC_ONESHOT;
        was_last_exit_ok_ = true;
        return {};
    }
"""
if old in text:
    text = text.replace(old, new, 1)
    print("service.cpp: restored earlyBootEnded exec")
elif "keymaster earlyBootEnded" not in text:
    print("service.cpp: earlyBootEnded skip already removed")
else:
    raise SystemExit("ExecStart block not found")

odsign_skip = """    if (name_ == "odsign" && GetProperty("odsign.key.done", "") == "1") {
        LOG(WARNING) << "BS bringup skip odsign start (already stubbed)";
        return {};
    }

"""
if odsign_skip in text:
    text = text.replace(odsign_skip, "", 1)
    print("service.cpp: removed odsign skip")
elif "BS bringup skip odsign start" not in text:
    print("service.cpp: odsign skip already removed")
else:
    raise SystemExit("odsign skip block not found")
p.write_text(text)
PY

SG=~/app-player/scratch-gaurav/misc_x86_64/baklava
if [ -d "$SG" ]; then
    find "$SG" -type f | while read f; do
        grep -q '^ro\.apex\.updatable=' "$f" 2>/dev/null || echo 'ro.apex.updatable=true' >> "$f"
    done
    echo "scratch-gaurav: ro.apex.updatable=true added"
fi

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"

cd "$AOSP"
source build/envsetup.sh
lunch aosp_x86_64-trunk_staging-eng >/dev/null 2>&1
export OUT_DIR=out_nxt_Baklava64
prebuilts/build-tools/linux_musl-x86/bin/ninja -f out_nxt_Baklava64/combined-aosp_x86_64.ninja init 2>&1 | tail -5
cp out_nxt_Baklava64/target/product/generic_x86_64/system/bin/init "$BOOT/init-patched"

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -4
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
md5sum fastboot/fastboot.vdi
echo ROUND56_DONE
