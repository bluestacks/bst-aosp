#!/usr/bin/env python3
"""R260: Port Henry graceful-shutdown flow from A16-init-bringup-notes §关机.

P0+P1 from Henry A16 system/core (originally A13 BST commits):
  - rootdir/init.rc: bstshutdown_core + proper_shutdown (+ other BST services)
  - init/reboot.cpp: RemountRO + /data/.bstshutdown_sync marker
  - init/init.cpp: copy_cpuinfo_file + check_status_of_last_boot

Refs: references/A16-init-bringup-notes.md (关机闭环)
"""
from __future__ import annotations

import shutil
import sys
from pathlib import Path

AOSP = Path.home() / "aosp16"
INIT_CPP = AOSP / "system/core/init/init.cpp"
REBOOT_CPP = AOSP / "system/core/init/reboot.cpp"
INIT_RC = AOSP / "system/core/rootdir/init.rc"
RELEASE_RC = Path.home() / "releases/Baklava64/system/etc/init/hw/init.rc"

BST_FUNCS = r'''
// [BST] Copy the right cpuinfo_<cores> file to cpuinfo
static void copy_file(char* src, char* dest) {
    FILE *fptr1, *fptr2;
    char c;
    fptr1 = fopen(src, "r");
    if (fptr1 == NULL) {
        LOG(ERROR) << "Cannot open file " << src;
        return;
    }
    fptr2 = fopen(dest, "w");
    if (fptr2 == NULL) {
        LOG(ERROR) << "Cannot open file " << dest;
        fclose(fptr1);
        return;
    }
    c = fgetc(fptr1);
    while (c != EOF) {
        fputc(c, fptr2);
        c = fgetc(fptr1);
    }
    fclose(fptr1);
    fclose(fptr2);
}

static void copy_cpuinfo_file() {
    long nop = sysconf(_SC_NPROCESSORS_ONLN);
    char cpuinfo_path[1024];
    char cpuinfo_path_main[1024];
#if defined(__aarch64__) || defined(__x86_64__)
    char cpuinfo_path64[1024];
    char cpuinfo_path_main64[1024];
    snprintf(cpuinfo_path64, sizeof(cpuinfo_path64), "/data/downloads/.oh/cpuinfo/arm64/cpuinfo_%ld", nop);
    snprintf(cpuinfo_path_main64, sizeof(cpuinfo_path_main64), "/data/downloads/.oh/cpuinfo/arm64/cpuinfo");
    copy_file(cpuinfo_path64, cpuinfo_path_main64);
#endif
    snprintf(cpuinfo_path, sizeof(cpuinfo_path), "/data/downloads/.oh/cpuinfo/arm/cpuinfo_%ld", nop);
    snprintf(cpuinfo_path_main, sizeof(cpuinfo_path_main), "/data/downloads/.oh/cpuinfo/arm/cpuinfo");
    copy_file(cpuinfo_path, cpuinfo_path_main);
}

// [BST] Check if last shutdown was graceful. If not, trigger proper_shutdown to fix corrupt files
static void check_status_of_last_boot() {
    const char *fname = "/data/.bstshutdown_sync";
    const char *packagesxml = "/data/system/packages.xml";
    if (access(packagesxml, F_OK) == 0) {
        if (access(fname, F_OK) == 0) {
            if (remove(fname) != 0)
                LOG(INFO) << "Unable to delete : " << fname;
            return;
        } else {
            LOG(INFO) << "last shutdown was not graceful as file does not exist, setting prop fix_corruptfiles";
            SetProperty("bst.config.fix_corruptfiles", "1");
        }
    } else {
        LOG(INFO) << "No packages.xml looks like first boot! Don't run fixcorruptfiles";
    }
}

'''

BST_INIT_RC = r'''
# [BST] BlueStacks services and property triggers (R260 / Henry shutdown)

service bstshutdown_core /system/bin/logwrapper /system/bin/bstshutdown_core
    user root
    group root
    disabled
    oneshot

on property:bst.config.start_shutdown=1
    start bstshutdown_core

service proper_shutdown /system/bin/logwrapper /system/bin/proper_shutdown
    class main
    user root
    group root
    disabled
    oneshot

on property:bst.config.fix_corruptfiles=1
    start proper_shutdown

service mountsf /system/bin/logwrapper /system/bin/mountsf
    user root
    group root
    disabled
    oneshot

service imeservice /system/bin/logwrapper /system/bin/bstime
    class main
    user root
    group root readproc
    disabled
    oneshot

service logcat_redirect /system/bin/logwrapper /system/bin/logcat_redirection
    class core
    user root
    group log root
    disabled
    oneshot
    writepid /dev/cpuset/system-background/tasks

service bindmount /system/bin/logwrapper /system/bin/bindmount
    user root
    group root
    disabled
    oneshot

service airplane_mode /system/bin/logwrapper /system/bin/airplane_mode
    user root
    group root
    disabled
    oneshot

on property:bst.enable_logcat_redirection=1
    start logcat_redirect

on property:bst.config.mountsf=1
    start mountsf

on property:bst.config.ime_listenerport=*
    restart imeservice

on property:bst.config.ime_listenerport=0
    stop imeservice

on property:bst.config.bindmount=*
    start bindmount

on property:bst.airplane_mode_active=*
    start airplane_mode
'''

REMOUNT_RO = '''
    bool RemountRO() {
        int ret = mount(mnt_fsname_.c_str(), mnt_dir_.c_str(), mnt_type_.c_str(),
                        MS_REMOUNT | MS_RDONLY, NULL);
        return ret == 0;
    }

'''

SYNC_MARKER = '''    // logcat stopped here
    // [BST] Create marker file for graceful shutdown check on next boot
    int fd_bst = open("/data/.bstshutdown_sync", O_RDWR | O_CREAT | O_APPEND, 0660);
    if (fd_bst < 0)
        LOG(ERROR) << "error in creating .bstshutdown_sync file, errno: " << strerror(errno);
    else {
        close(fd_bst);
        LOG(INFO) << ".bstshutdown_sync file created";
    }
'''


def backup(path: Path) -> None:
    bak = path.with_suffix(path.suffix + ".bak-r260")
    if not bak.exists():
        shutil.copy2(path, bak)
        print(f"backup {bak}")


def patch_init_cpp() -> None:
    text = INIT_CPP.read_text()
    if "check_status_of_last_boot" in text:
        print("init.cpp: already patched")
        return
    backup(INIT_CPP)

    needle = "int SecondStageMain(int argc, char** argv) {"
    if needle not in text:
        raise SystemExit("init.cpp: SecondStageMain not found")
    text = text.replace(needle, BST_FUNCS + needle, 1)

    call_copy = (
        "    UmountSecondStageRes();\n\n"
        "    // [BST] Copying the right cpuinfo_<cores> file to cpuinfo\n"
        "    copy_cpuinfo_file();\n"
    )
    old_umount = "    UmountSecondStageRes();\n"
    if old_umount not in text:
        raise SystemExit("init.cpp: UmountSecondStageRes call not found")
    # Only replace the first occurrence in SecondStageMain (after PropertyInit)
    text = text.replace(old_umount, call_copy, 1)

    old_prio = (
        "    // Restore prio before main loop\n"
        "    setpriority(PRIO_PROCESS, 0, 0);\n"
        "    while (true) {"
    )
    new_prio = (
        "    // Restore prio before main loop\n"
        "    setpriority(PRIO_PROCESS, 0, 0);\n\n"
        "    // [BST] Check if last shutdown was graceful\n"
        "    check_status_of_last_boot();\n"
        "    while (true) {"
    )
    if old_prio not in text:
        raise SystemExit("init.cpp: setpriority/main loop anchor not found")
    text = text.replace(old_prio, new_prio, 1)

    INIT_CPP.write_text(text)
    print(f"patched {INIT_CPP}")


def patch_reboot_cpp() -> None:
    text = REBOOT_CPP.read_text()
    if ".bstshutdown_sync" in text and "RemountRO" in text:
        print("reboot.cpp: already patched")
        return
    backup(REBOOT_CPP)

    if "bool RemountRO()" not in text:
        anchor = "    static bool IsBlockDevice(const struct mntent& mntent) {"
        if anchor not in text:
            raise SystemExit("reboot.cpp: IsBlockDevice anchor not found")
        text = text.replace(anchor, REMOUNT_RO + anchor, 1)

    old_umount = "        if (!entry.Umount(force)) unmount_success = false;"
    new_umount = (
        "        if (!entry.RemountRO() && !entry.Umount(force)) unmount_success = false;"
    )
    if old_umount not in text:
        if new_umount in text:
            print("reboot.cpp: RemountRO umount already applied")
        else:
            raise SystemExit("reboot.cpp: TryUmountPartitions Umount(force) not found")
    else:
        text = text.replace(old_umount, new_umount, 1)

    old_marker = "    // logcat stopped here\n"
    if ".bstshutdown_sync" not in text:
        if old_marker not in text:
            raise SystemExit("reboot.cpp: logcat stopped here anchor not found")
        text = text.replace(old_marker, SYNC_MARKER + "\n", 1)

    REBOOT_CPP.write_text(text)
    print(f"patched {REBOOT_CPP}")


def patch_init_rc(path: Path) -> None:
    text = path.read_text()
    if "bst.config.start_shutdown=1" in text:
        print(f"{path}: already has start_shutdown trigger")
        return
    backup(path)
    if not text.endswith("\n"):
        text += "\n"
    path.write_text(text + BST_INIT_RC)
    print(f"appended BST services to {path}")


def main() -> int:
    for p in (INIT_CPP, REBOOT_CPP, INIT_RC):
        if not p.exists():
            print(f"MISSING {p}", file=sys.stderr)
            return 1
    patch_init_cpp()
    patch_reboot_cpp()
    patch_init_rc(INIT_RC)
    if RELEASE_RC.exists():
        patch_init_rc(RELEASE_RC)
    else:
        print(f"WARN: no release init.rc at {RELEASE_RC}")
    print("R260_PATCH_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
