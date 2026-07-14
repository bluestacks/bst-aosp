#!/bin/bash
# Round 23: apexd getfilecon skip (CAPEX decompress) + initrd/fastboot
set -e
AOSP=~/aosp16
BOOT=~/app-player/hd/guest/BootImage
APEXD=~/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/system/bin/apexd

python3 - <<'PY'
from pathlib import Path
p = Path.home() / "aosp16/system/apex/apexd/apexd.cpp"
text = p.read_text()
old = """  auto ctx = GetfileconPath(apex_path);
  if (!ctx.ok()) {
    return ctx.error();
  }
  if (!StartsWith(*ctx, gConfig->active_apex_selinux_ctx)) {
    return Error() << apex_path << " has wrong SELinux context " << *ctx;
  }
  return std::move(*apex);"""
new = """  auto ctx = GetfileconPath(apex_path);
  if (!ctx.ok()) {
    LOG(WARNING) << "BS bringup skip getfilecon " << apex_path;
    return std::move(*apex);
  }
  if (!StartsWith(*ctx, gConfig->active_apex_selinux_ctx)) {
    LOG(WARNING) << "BS bringup skip apex context check " << apex_path << " ctx=" << *ctx;
    return std::move(*apex);
  }
  return std::move(*apex);"""
if "BS bringup skip getfilecon" not in text:
    if old not in text:
        raise SystemExit("OpenAndValidateDecompressedApex anchor not found")
    p.write_text(text.replace(old, new, 1))
    print("patched apexd.cpp getfilecon skip")
else:
    print("apexd getfilecon already patched")
PY

cd "$AOSP"
source build/envsetup.sh
lunch aosp_x86_64-trunk_staging-eng >/dev/null 2>&1
export OUT_DIR=out_nxt_Baklava64
prebuilts/build-tools/linux_musl-x86/bin/ninja -f out_nxt_Baklava64/combined-aosp_x86_64.ninja apexd 2>&1 | tail -5

cp "$APEXD" "$BOOT/apexd-patched"
cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
echo ROUND23_DONE
