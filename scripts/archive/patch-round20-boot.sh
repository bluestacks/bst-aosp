#!/bin/bash
# Round 20: zygote — init.environ, linkerconfig golden fallback, art_boot/odsign skip
set -e
AOSP=~/aosp16
BOOT=~/app-player/hd/guest/BootImage
LC_SRC="$AOSP/system/linkerconfig/testdata/golden_output/stage1"

# --- patch service.cpp ---
python3 - <<'PY'
from pathlib import Path
p = Path.home() / "aosp16/system/core/init/service.cpp"
text = p.read_text()

exec_needle = """Result<void> Service::ExecStart() {
    if (name_.find("keymaster earlyBootEnded") != std::string::npos) {
        LOG(WARNING) << "BS bringup skip exec: " << name_;
        flags_ |= SVC_ONESHOT;
        was_last_exit_ok_ = true;
        return {};
    }
"""
exec_repl = """Result<void> Service::ExecStart() {
    if (name_.find("keymaster earlyBootEnded") != std::string::npos ||
        name_ == "art_boot") {
        LOG(WARNING) << "BS bringup skip exec: " << name_;
        flags_ |= SVC_ONESHOT;
        was_last_exit_ok_ = true;
        return {};
    }
"""
if exec_needle in text:
    text = text.replace(exec_needle, exec_repl, 1)
elif "name_ == \"art_boot\"" not in text:
    raise SystemExit("ExecStart patch anchor not found")

start_needle = """Result<void> Service::Start() {
    auto reboot_on_failure = make_scope_guard([this] {
        if (on_failure_reboot_target_) {
            LOG(WARNING) << "ExecStart reboot_on_failure ignored for " << name_ << " (BS bringup)";
        }
    });

    if (is_updatable() && !IsDefaultMountNamespaceReady()) {
"""
start_insert = """Result<void> Service::Start() {
    if (name_ == "odsign" && GetProperty("odsign.key.done", "") == "1") {
        LOG(WARNING) << "BS bringup skip odsign start (already stubbed)";
        return {};
    }

    auto reboot_on_failure = make_scope_guard([this] {
        if (on_failure_reboot_target_) {
            LOG(WARNING) << "ExecStart reboot_on_failure ignored for " << name_ << " (BS bringup)";
        }
    });

    if (is_updatable() && !IsDefaultMountNamespaceReady()) {
"""
if "BS bringup skip odsign start" not in text:
    if start_needle not in text:
        raise SystemExit("Start() patch anchor not found")
    text = text.replace(start_needle, start_insert, 1)

p.write_text(text)
print("patched service.cpp")
PY

# --- patch builtins.cpp linkerconfig fallback ---
python3 - <<'PY'
from pathlib import Path
p = Path.home() / "aosp16/system/core/init/builtins.cpp"
text = p.read_text()

helper = """
static void InstallBootstrapLinkerConfigFromBoot() {
    auto copy_one = [](const char* src, const char* dst) {
        int sfd = open(src, O_RDONLY);
        if (sfd < 0) return;
        int dfd = open(dst, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (dfd < 0) {
            close(sfd);
            return;
        }
        char buf[4096];
        ssize_t n;
        while ((n = read(sfd, buf, sizeof(buf))) > 0) {
            write(dfd, buf, n);
        }
        close(sfd);
        close(dfd);
    };
    mkdir("/linkerconfig/bootstrap", 0755);
    mkdir("/linkerconfig/default", 0755);
    mkdir("/linkerconfig/com.android.runtime", 0755);
    mkdir("/linkerconfig/com.android.art", 0755);
    copy_one("/boot/linkerconfig/ld.config.txt", "/linkerconfig/bootstrap/ld.config.txt");
    copy_one("/boot/linkerconfig/ld.config.txt", "/linkerconfig/default/ld.config.txt");
    copy_one("/boot/linkerconfig/ld.config.txt", "/linkerconfig/ld.config.txt");
    copy_one("/boot/linkerconfig/com.android.runtime/ld.config.txt",
             "/linkerconfig/com.android.runtime/ld.config.txt");
    copy_one("/boot/linkerconfig/com.android.art/ld.config.txt",
             "/linkerconfig/com.android.art/ld.config.txt");
    int fd = open("/linkerconfig/bootstrap/ld.config.txt", O_RDONLY);
    if (fd < 0) {
        fd = open("/linkerconfig/default/ld.config.txt", O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (fd >= 0) {
            const char stub[] = "# BS bringup stub\\n";
            write(fd, stub, sizeof(stub) - 1);
            close(fd);
            copy_one("/linkerconfig/default/ld.config.txt", "/linkerconfig/bootstrap/ld.config.txt");
        }
    } else {
        close(fd);
    }
}

"""

if "InstallBootstrapLinkerConfigFromBoot" not in text:
    anchor = "static Result<void> GenerateLinkerConfiguration() {"
    if anchor not in text:
        raise SystemExit("GenerateLinkerConfiguration not found")
    text = text.replace(anchor, helper + anchor, 1)

old_block = """        LOG(WARNING) << "linkerconfig failed (BS bringup), using bootstrap linker config";
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
        return {};"""

new_block = """        LOG(WARNING) << "linkerconfig failed (BS bringup), using bootstrap linker config";
        InstallBootstrapLinkerConfigFromBoot();
        return {};"""

if old_block in text:
    text = text.replace(old_block, new_block, 1)
elif "InstallBootstrapLinkerConfigFromBoot();" not in text:
    raise SystemExit("linkerconfig fallback block not found")

p.write_text(text)
print("patched builtins.cpp")
PY

# --- rebuild init ---
cd "$AOSP"
source build/envsetup.sh
lunch aosp_x86_64-trunk_staging-eng >/dev/null 2>&1
export OUT_DIR=out_nxt_Baklava64
prebuilts/build-tools/linux_musl-x86/bin/ninja -f out_nxt_Baklava64/combined-aosp_x86_64.ninja init 2>&1 | tail -5

cp out_nxt_Baklava64/target/product/generic_x86_64/system/bin/init "$BOOT/init-patched"
cp ~/stage2-good-vhd.sh "$BOOT/stage2.sh"
cp ~/init.environ.rc "$BOOT/init.environ.rc" 2>/dev/null || cp ~/scripts/init.environ.rc "$BOOT/init.environ.rc"

mkdir -p "$BOOT/linkerconfig/com.android.runtime" "$BOOT/linkerconfig/com.android.art"
cp "$LC_SRC/ld.config.txt" "$BOOT/linkerconfig/ld.config.txt"
cp "$LC_SRC/com.android.runtime/ld.config.txt" "$BOOT/linkerconfig/com.android.runtime/ld.config.txt"
cp "$LC_SRC/com.android.art/ld.config.txt" "$BOOT/linkerconfig/com.android.art/ld.config.txt"

# Patch Makefile to pack linkerconfig + init.environ.rc into initrd
python3 - <<'PY'
from pathlib import Path
mk = Path.home() / "app-player/hd/guest/BootImage/Makefile"
text = mk.read_text()
insert = """
\tmkdir -p initrd/boot/linkerconfig/com.android.runtime initrd/boot/linkerconfig/com.android.art
\tcp linkerconfig/ld.config.txt initrd/boot/linkerconfig/
\tcp linkerconfig/com.android.runtime/ld.config.txt initrd/boot/linkerconfig/com.android.runtime/
\tcp linkerconfig/com.android.art/ld.config.txt initrd/boot/linkerconfig/com.android.art/
\tcp init.environ.rc initrd/boot/init.environ.rc
"""
anchor_img = "\tcp stage2.sh initrd/boot/stage2.sh\n\tcp bstsetup.env initrd/boot/bstsetup.env"
text = mk.read_text()
if anchor_img in text and "initrd/boot/init.environ.rc" not in text:
    text = text.replace(anchor_img, anchor_img + insert, 1)
    mk.write_text(text)
    print("patched Makefile initrd.img")
elif "initrd/boot/init.environ.rc" in text:
    print("Makefile initrd.img already patched")
else:
    raise SystemExit("initrd.img Makefile anchor not found")
PY

cd "$BOOT"
make initrd.img KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
make build_fastboot KDIR=~/aosp16/kernel-a16 2>&1 | tail -3
VBoxManage internalcommands sethduuid fastboot/fastboot.vdi 91b80c95-aa7d-459d-93e4-c479f5babbb7
echo ROUND20_DONE
