#!/usr/bin/env python3
# P2-MECH-6: packages/modules/adb — BST path access + ADB command whitelist (a13->a16).
# 1. file_sync_service.cpp: allow /sdcard/ + /mnt/windows/ via ADB (BST shared folder access).
# 2. adb.cpp: _bst_allow_adb_cmd function (reads /data/downloads/.adbcmd for allowed commands).
# 3. adb.h: declaration.
# ADB is host-tool/device-daemon, not boot-critical. Mechanical. Robust exact-string replace.
import os, sys
A16 = os.path.expanduser("~/aosp16")
ERRS = []
def patch(rel, replacements, label):
    full = os.path.join(A16, rel)
    with open(full) as f: src = f.read()
    orig = src
    for old, new in replacements:
        if old not in src: ERRS.append(f"{label}: ANCHOR NOT FOUND: {old.strip()[:70]!r}"); return
        if src.count(old) > 1: ERRS.append(f"{label}: ANCHOR NOT UNIQUE ({src.count(old)}): {old.strip()[:70]!r}"); return
        src = src.replace(old, new, 1)
    if src == orig: ERRS.append(f"{label}: no change"); return
    with open(full, "w") as f: f.write(src)
    print(f"OK   {label}")

# file_sync_service.cpp: expand path access to /sdcard/ + /mnt/windows/
patch("packages/modules/adb/daemon/file_sync_service.cpp", [
    ('        return !android::base::StartsWith(path, "/data/");\n',
     '        // A16DBG:P2:MECH BST: allow /data/ + /sdcard/ + /mnt/windows/ (a13)\n'
     '        return !android::base::StartsWith(path, "/data/") &&\n'
     '               !android::base::StartsWith(path, "/sdcard/") &&\n'
     '               !android::base::StartsWith(path, "/mnt/windows/");\n'),
], "adb file_sync_service path access")

# adb.h: add _bst_allow_adb_cmd declaration
patch("packages/modules/adb/adb.h", [
    ("void usb_init();\n",
     "void usb_init();\n"
     "// A16DBG:P2:MECH BST ADB command whitelist (a13)\n"
     "int _bst_allow_adb_cmd(const char* cmd);\n"),
], "adb.h _bst_allow_adb_cmd declaration")

# adb.cpp: add _bst_allow_adb_cmd function in #if !ADB_HOST block
patch("packages/modules/adb/adb.cpp", [
    ("    std::vector<std::string> connection_properties;\n",
     """// A16DBG:P2:MECH BST ADB command whitelist (a13) — reads /data/downloads/.adbcmd
#if !ADB_HOST
#include <stdio.h>
#include <string.h>
#define BST_ADBCMD_FILE "/data/downloads/.adbcmd"
int _bst_allow_adb_cmd(const char* cmd) {
    FILE* f = fopen(BST_ADBCMD_FILE, "r");
    if (f == nullptr) return 1;  // no whitelist file = allow all
    char line[256];
    while (fgets(line, sizeof(line), f)) {
        line[strcspn(line, "\\r\\n")] = 0;
        if (strstr(cmd, line) != nullptr) { fclose(f); return 1; }
    }
    fclose(f);
    return 0;  // not in whitelist
}
#endif

    std::vector<std::string> connection_properties;
"""),
], "adb.cpp _bst_allow_adb_cmd function")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
