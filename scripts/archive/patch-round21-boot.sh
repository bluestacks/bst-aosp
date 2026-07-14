#!/bin/bash
# Round 21: ADB (tcp:5555 / host NAT 5556) + apexd restorecon skip for apex mount
set -e
AOSP=~/aosp16
BOOT=~/app-player/hd/guest/BootImage
OUT=~/aosp16/out_nxt_Baklava64/target/product/generic_x86_64
APEXD=~/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/system/bin/apexd
ADBD_APEX=~/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/apex/com.android.adbd

# --- apexd: skip restorecon when SELinux policy missing (permissive bringup) ---
python3 - <<'PY'
from pathlib import Path
p = Path.home() / "aosp16/system/apex/apexd/apexd_utils.h"
text = p.read_text()
old = """inline android::base::Result<void> RestoreconPath(const std::string& path) {
  unsigned int seflags = SELINUX_ANDROID_RESTORECON_RECURSE;
  if (selinux_android_restorecon(path.c_str(), seflags) < 0) {
    return android::base::ErrnoError() << "Failed to restorecon " << path;
  }
  return {};
}"""
new = """inline android::base::Result<void> RestoreconPath(const std::string& path) {
  unsigned int seflags = SELINUX_ANDROID_RESTORECON_RECURSE;
  if (selinux_android_restorecon(path.c_str(), seflags) < 0) {
    LOG(WARNING) << "BS bringup skip restorecon " << path;
    return {};
  }
  return {};
}"""
partial_old = """  if (selinux_android_restorecon(path.c_str(), seflags) < 0) {
    if (errno == ENODATA || errno == ENOENT || errno == EOPNOTSUPP) {
      LOG(WARNING) << "BS bringup skip restorecon " << path;
      return {};
    }
    return android::base::ErrnoError() << "Failed to restorecon " << path;
  }"""
partial_new = """  if (selinux_android_restorecon(path.c_str(), seflags) < 0) {
    LOG(WARNING) << "BS bringup skip restorecon " << path;
    return {};
  }"""
if partial_old in text:
    text = text.replace(partial_old, partial_new, 1)
    p.write_text(text)
    print("upgraded apexd restorecon to unconditional skip")
elif "BS bringup skip restorecon" not in text:
    if old not in text:
        raise SystemExit("RestoreconPath anchor not found")
    text = text.replace(old, new, 1)
    p.write_text(text)
    print("patched apexd_utils.h")
else:
    print("apexd already patched")
PY

cd "$AOSP"
source build/envsetup.sh
lunch aosp_x86_64-trunk_staging-eng >/dev/null 2>&1
export OUT_DIR=out_nxt_Baklava64
prebuilts/build-tools/linux_musl-x86/bin/ninja -f out_nxt_Baklava64/combined-aosp_x86_64.ninja apexd 2>&1 | tail -5

cp "$APEXD" "$BOOT/apexd-patched"
rm -rf "$BOOT/apex-adbd"
cp -a "$ADBD_APEX" "$BOOT/apex-adbd"

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"

# Ensure adbkey.pub + patched apexd in initrd.img Makefile
python3 - <<'PY'
from pathlib import Path
mk = Path.home() / "app-player/hd/guest/BootImage/Makefile"
text = mk.read_text()
anchor = "\tcp init.environ.rc initrd/boot/init.environ.rc\n\tcp 4-dpi initrd/boot/4-dpi"
insert = "\tcp init.environ.rc initrd/boot/init.environ.rc\n\tcp adbkey.pub initrd/boot/adbkey.pub\n\tcp 4-dpi initrd/boot/4-dpi"
text = mk.read_text()
if "initrd/boot/adbkey.pub" not in text:
    if anchor not in text:
        raise SystemExit("Makefile anchor not found for adbkey")
    text = text.replace(anchor, insert, 1)
    mk.write_text(text)
    print("patched Makefile adbkey")
else:
    print("Makefile adbkey already present")
# Use patched apexd in initrd if line exists
old = "\tcp /home/clouddev/bst/workspace/markxu/aosp16/out_nxt_Baklava64/target/product/generic_x86_64/system/bin/apexd initrd/boot/bin/apexd"
if old in text:
    text = mk.read_text()
    text = text.replace(old, "\tcp apexd-patched initrd/boot/bin/apexd", 1)
    mk.write_text(text)
    print("Makefile uses apexd-patched")
anchor_adbd = "\tcp adbkey.pub initrd/boot/adbkey.pub"
if "initrd/boot/apex-adbd/bin/adbd" not in text:
    if anchor_adbd not in text:
        raise SystemExit("adbkey anchor missing for apex-adbd insert")
    text = text.replace(anchor_adbd,
        anchor_adbd + "\n\tcp -a apex-adbd initrd/boot/apex-adbd", 1)
    mk.write_text(text)
    print("patched Makefile apex-adbd")
PY

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
echo ROUND21_DONE
