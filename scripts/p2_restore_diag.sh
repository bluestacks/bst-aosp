#!/bin/bash
# Restore DIAG bypass on service.cpp (Phase2 target-level=8 alone insufficient — verified).
set -e
SVC=~/aosp16/system/hwservicemanager/service.cpp
python3 - <<'PY'
from pathlib import Path
p = Path.home() / "aosp16/system/hwservicemanager/service.cpp"
t = p.read_text()
old = '''    auto transport = android::hardware::getTransport(ServiceManager::descriptor, serviceName);
    ALOGI("A16DBG:HWSM transport=%d (Phase2 formal: expect non-EMPTY when vendor manifest target-level=8)", (int)transport);
    if (transport == android::vintf::Transport::EMPTY) {
        ALOGI("A16DBG:HWSM-EMPTY transport==EMPTY -> disabling hwservicemanager (formal path; should not hit if target-level=8)");
        ALOGI("HIDL is not supported on this device so hwservicemanager is not needed");'''
new = '''    auto transport = android::hardware::getTransport(ServiceManager::descriptor, serviceName);
    ALOGI("A16DBG:HWSM transport=%d; DIAG bypass active (if(false) over EMPTY branch; Phase2 2026-07-20: target-level=8 alone INSUFFICIENT — disabled=1 still; keep DIAG temp_debt; next=device-side hidl.manager in device manifest)", (int)transport);
    if (false) /* BlueStacks DIAG temp_debt: force HIDL supported. Phase2 2026-07-20 readback: vendor manifest target-level=8 + DIAG removed still set hwservicemanager.disabled + HAL SIGABRT. Formal fix != target-level alone; try device-side android.hidl.manager in DEVICE manifest (getTransport checks device after framework). */ {
        ALOGI("A16DBG:HWSM-DIAG-BYPASS active");
        ALOGI("HIDL is not supported on this device so hwservicemanager is not needed");'''
if old not in t:
    if 'if (false)' in t and 'DIAG' in t:
        print('already DIAG')
    else:
        raise SystemExit('pattern mismatch')
else:
    p.write_text(t.replace(old, new, 1))
    print('DIAG restored')
PY
# restore staged vendor manifest to legacy to match DIAG working tree
sed -i 's/target-level="8"/target-level="legacy"/' ~/releases/Baklava64/system/vendor/etc/vintf/manifest.xml || true
grep target-level ~/releases/Baklava64/system/vendor/etc/vintf/manifest.xml | head -1
rg -n 'A16DBG:HWSM|if \(false\)|transport ==' "$SVC" | head -8
echo DONE
