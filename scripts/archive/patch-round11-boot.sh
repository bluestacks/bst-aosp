#!/bin/bash
# Round 11: linkerconfig non-fatal + servicemanager SELinux bypass + fstab fallback
set -e
AOSP=~/aosp16

python3 - <<'PY'
from pathlib import Path

# linkerconfig non-fatal
p = Path.home() / "aosp16/system/core/init/builtins.cpp"
text = p.read_text()
old = """    if (logwrap_fork_execvp(arraysize(arguments), arguments, nullptr, false, LOG_KLOG, false,
                            nullptr) != 0) {
        return ErrnoError() << "failed to execute linkerconfig";
    }"""
new = """    if (logwrap_fork_execvp(arraysize(arguments), arguments, nullptr, false, LOG_KLOG, false,
                            nullptr) != 0) {
        LOG(WARNING) << "linkerconfig failed (BS bringup), using bootstrap linker config";
        mkdir("/linkerconfig/bootstrap", 0755);
        mkdir("/linkerconfig/default", 0755);
        int fd = open("/linkerconfig/bootstrap/ld.config.txt", O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (fd >= 0) {
            const char stub[] = "# BS bringup stub\\n";
            write(fd, stub, sizeof(stub) - 1);
            close(fd);
        }
        fd = open("/linkerconfig/default/ld.config.txt", O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (fd >= 0) {
            const char stub[] = "# BS bringup stub\\n";
            write(fd, stub, sizeof(stub) - 1);
            close(fd);
        }
        return {};
    }"""
if "linkerconfig failed (BS bringup)" not in text:
    if old not in text:
        raise SystemExit("builtins.cpp linkerconfig block not found")
    text = text.replace(old, new, 1)
    p.write_text(text)
    print("patched builtins.cpp")
else:
    print("builtins.cpp already patched")

# servicemanager Access bypass
p = Path.home() / "aosp16/frameworks/native/cmds/servicemanager/Access.cpp"
text = p.read_text()
old = """    if (selabel_lookup(getSehandle(), &tctx, name.c_str(), SELABEL_CTX_ANDROID_SERVICE) != 0) {
        LOG(ERROR) << "SELinux: No match for " << name << " in service_contexts.\\n";
        return false;
    }"""
new = """    if (selabel_lookup(getSehandle(), &tctx, name.c_str(), SELABEL_CTX_ANDROID_SERVICE) != 0) {
        LOG(WARNING) << "SELinux: No match for " << name << " in service_contexts (BS bringup allow)";
        return true;
    }"""
if "BS bringup allow" not in text:
    if old not in text:
        raise SystemExit("Access.cpp selabel_lookup block not found")
    text = text.replace(old, new, 1)
old2 = """    return 0 == selinux_check_access(sctx.sid.c_str(), tctx, tclass, perm,
        reinterpret_cast<void*>(&data));"""
new2 = """    (void)sctx; (void)tctx; (void)tclass; (void)perm; (void)data;
    return true; /* BS bringup: no sepolicy */"""
if "BS bringup: no sepolicy" not in text:
    if old2 not in text:
        raise SystemExit("Access.cpp actionAllowed block not found")
    text = text.replace(old2, new2, 1)
    p.write_text(text)
    print("patched Access.cpp")
else:
    print("Access.cpp already patched")

# libfstab fallback for missing androidboot.hardware
p = Path.home() / "aosp16/system/core/fs_mgr/libfstab/fstab.cpp"
text = p.read_text()
fallback = """    // BS bringup: BlueStacks cmdline has bstandroid= not androidboot.hardware=
    for (const char* prefix : {"/vendor/etc/fstab.", "/system/etc/fstab.", "/fstab."}) {
        std::string fstab_path = std::string(prefix) + "ranchu";
        if (access(fstab_path.c_str(), F_OK) == 0) {
            return fstab_path;
        }
    }

    return "";"""
marker = "std::string GetFstabPath() {"
if "BS bringup: BlueStacks cmdline" not in text:
    idx = text.find(marker)
    if idx < 0:
        raise SystemExit("GetFstabPath not found")
    sub = text[idx:]
    old_end = """    }

    return "";
}"""
    pos = sub.rfind(old_end)
    if pos < 0:
        raise SystemExit("GetFstabPath end not found")
    sub = sub[:pos] + """    }

""" + fallback + "\n}"
    text = text[:idx] + sub
    p.write_text(text)
    print("patched fstab.cpp")
else:
    print("fstab.cpp already patched")
PY

cd "$AOSP"
source build/envsetup.sh
lunch aosp_x86_64-trunk_staging-eng >/dev/null 2>&1
export OUT_DIR=out_nxt_Baklava64
prebuilts/build-tools/linux_musl-x86/bin/ninja -f out_nxt_Baklava64/combined-aosp_x86_64.ninja init servicemanager libfstab 2>&1 | tail -10

BOOT=~/app-player/hd/guest/BootImage
OUT=out_nxt_Baklava64/target/product/generic_x86_64
cp "$OUT/system/bin/init" "$BOOT/init-patched"

cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
python3 ~/patch-stage2-round10.py 2>/dev/null || true
python3 ~/fix-makefile-initrd.py 2>/dev/null || true

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
ls -la fastboot/fastboot.vdi init-patched
echo ROUND11_DONE
