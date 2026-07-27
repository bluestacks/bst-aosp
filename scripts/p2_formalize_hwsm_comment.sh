#!/bin/bash
set -e
SVC=~/aosp16/system/hwservicemanager/service.cpp
python3 - <<'PY'
from pathlib import Path
p = Path.home() / "aosp16/system/hwservicemanager/service.cpp"
t = p.read_text()
old = '''    ALOGI("A16DBG:HWSM transport=%d (Phase2 device-side hidl.manager; expect non-EMPTY)", (int)transport);
    if (transport == android::vintf::Transport::EMPTY) {
        ALOGI("A16DBG:HWSM-EMPTY transport==EMPTY -> disabling hwservicemanager");'''
new = '''    // Phase2 P0 formal (2026-07-20): EMPTY was caused by VINTF declaring
    // android.hidl.manager@1.0 while ServiceManager uses V1_2::descriptor (@1.2).
    // HalManifest minorAtLeast(1.2) fails against 1.0 -> getTransport EMPTY -> self-disable.
    // Fix: declare @1.2 (align frozen FCM8). Layer2 7/7 Root.vhd 503235fc, no DIAG bypass.
    ALOGI("A16DBG:HWSM transport=%d (formal manager@1.2)", (int)transport);
    if (transport == android::vintf::Transport::EMPTY) {
        ALOGI("A16DBG:HWSM-EMPTY unexpected with manager@1.2 — disabling hwservicemanager");'''
if old not in t:
    if "formal manager@1.2" in t:
        print("already updated")
    else:
        raise SystemExit("pattern miss")
else:
    p.write_text(t.replace(old, new, 1))
    print("service.cpp comment formalized")
# show
for i, line in enumerate(p.read_text().splitlines(), 1):
    if 148 <= i <= 162:
        print(f"{i}:{line}")
PY
