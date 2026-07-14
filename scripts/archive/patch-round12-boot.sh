#!/bin/bash
# Round 12: vendor init override for patched sm/hwsm + canAddService bypass
set -e
AOSP=~/aosp16

python3 - <<'PY'
from pathlib import Path

# canAddService always allow (belt-and-suspenders if stock sm somehow runs)
p = Path.home() / "aosp16/frameworks/native/cmds/servicemanager/ServiceManager.cpp"
text = p.read_text()
old = """Status ServiceManager::canAddService(const Access::CallingContext& ctx, const std::string& name,
                                     std::optional<std::string>* accessor) {
    if (!mAccess->canAdd(ctx, name)) {
        return Status::fromExceptionCode(Status::EX_SECURITY, "SELinux denied for service.");
    }"""
new = """Status ServiceManager::canAddService(const Access::CallingContext& ctx, const std::string& name,
                                     std::optional<std::string>* accessor) {
    (void)ctx; (void)name;
    accessor->reset();
    return Status::ok(); /* BS bringup: skip SELinux/VINTF accessor gate */
    if (!mAccess->canAdd(ctx, name)) {
        return Status::fromExceptionCode(Status::EX_SECURITY, "SELinux denied for service.");
    }"""
if "BS bringup: skip SELinux/VINTF accessor gate" not in text:
    if old not in text:
        raise SystemExit("canAddService block not found")
    p.write_text(text.replace(old, new, 1))
    print("patched canAddService")
else:
    print("canAddService already patched")

# Log self-register failure reason
p = Path.home() / "aosp16/frameworks/native/cmds/servicemanager/main.cpp"
text = p.read_text()
old = """    if (!manager->addService("manager", manager, false /*allowIsolated*/, IServiceManager::DUMP_FLAG_PRIORITY_DEFAULT).isOk()) {
        LOG(ERROR) << "Could not self register servicemanager";
    }"""
new = """    {
        auto st = manager->addService("manager", manager, false /*allowIsolated*/,
                                      IServiceManager::DUMP_FLAG_PRIORITY_DEFAULT);
        if (!st.isOk()) {
            LOG(ERROR) << "Could not self register servicemanager: " << st.toString8();
        }
    }"""
if "Could not self register servicemanager:" not in text:
    if old not in text:
        raise SystemExit("main.cpp self-register block not found")
    p.write_text(text.replace(old, new, 1))
    print("patched main.cpp")
else:
    print("main.cpp already patched")
PY

cd "$AOSP"
source build/envsetup.sh
lunch aosp_x86_64-trunk_staging-eng >/dev/null 2>&1
export OUT_DIR=out_nxt_Baklava64
prebuilts/build-tools/linux_musl-x86/bin/ninja -f out_nxt_Baklava64/combined-aosp_x86_64.ninja servicemanager 2>&1 | tail -8

BOOT=~/app-player/hd/guest/BootImage
OUT=out_nxt_Baklava64/target/product/generic_x86_64
cp "$OUT/system/bin/servicemanager" "$BOOT/initrd/boot/bin/servicemanager"
cp "$OUT/system/system_ext/bin/hwservicemanager" "$BOOT/initrd/boot/bin/hwservicemanager"

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
python3 ~/fix-makefile-initrd.py 2>/dev/null || true

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
ls -la fastboot/fastboot.vdi initrd/boot/bin/servicemanager
echo ROUND12_DONE
