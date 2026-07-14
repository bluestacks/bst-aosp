#!/bin/bash
# Patch init to skip vdc keymaster earlyBootEnded (no KeyMint HAL on bringup)
set -e
AOSP=~/aosp16
p="$AOSP/system/core/init/service.cpp"
python3 - <<'PY'
from pathlib import Path
p = Path.home() / "aosp16/system/core/init/service.cpp"
text = p.read_text()
needle = "Result<void> Service::ExecStart() {"
insert = """Result<void> Service::ExecStart() {
    if (name_.find("keymaster earlyBootEnded") != std::string::npos) {
        LOG(WARNING) << "BS bringup skip exec: " << name_;
        flags_ |= SVC_ONESHOT;
        was_last_exit_ok_ = true;
        return {};
    }
"""
if "BS bringup skip exec:" not in text:
    if needle not in text:
        raise SystemExit("ExecStart not found")
    text = text.replace(needle, insert, 1)
    p.write_text(text)
    print("patched service.cpp")
else:
    print("already patched")
PY

cd "$AOSP"
source build/envsetup.sh
lunch aosp_x86_64-trunk_staging-eng >/dev/null 2>&1
export OUT_DIR=out_nxt_Baklava64
prebuilts/build-tools/linux_musl-x86/bin/ninja -f out_nxt_Baklava64/combined-aosp_x86_64.ninja init 2>&1 | tail -5

BOOT=~/app-player/hd/guest/BootImage
cp out_nxt_Baklava64/target/product/generic_x86_64/system/bin/init "$BOOT/init-patched"
cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -2
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -2
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
echo ROUND17_DONE
