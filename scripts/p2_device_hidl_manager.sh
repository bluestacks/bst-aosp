#!/bin/bash
# Phase2 P0 cont.10: device-side android.hidl.manager + remove DIAG + rebuild hwsm
set -eo pipefail
AOSP=$HOME/aosp16
STAGE=$HOME/releases/Baklava64/system
LOG=$HOME/p2_dev_hidl_mgr_$(date +%Y%m%d-%H%M%S).log
exec > >(tee -a "$LOG") 2>&1
echo "A16DBG:P2: device-hidl-manager start $(date -Is) log=$LOG"

# --- 1) Source DEVICE manifest: add android.hidl.manager ---
SRC_MAN=$AOSP/device/generic/common/manifest.xml
python3 - <<'PY'
from pathlib import Path
p = Path.home() / "aosp16/device/generic/common/manifest.xml"
t = p.read_text()
block = '''    <hal format="hidl">
        <!-- Phase2 P0 formal 2026-07-20: device-side IServiceManager so
             hwservicemanager getTransport finds HWBINDER even when framework
             manifest entry is filtered/missing (cont.9: target-level=8 alone
             insufficient). getTransport checks framework then device. -->
        <name>android.hidl.manager</name>
        <transport>hwbinder</transport>
        <version>1.0</version>
        <interface>
            <name>IServiceManager</name>
            <instance>default</instance>
        </interface>
    </hal>
'''
if "android.hidl.manager" in t:
    print("source manifest already has hidl.manager")
else:
    if "</manifest>" not in t:
        raise SystemExit("no </manifest>")
    p.write_text(t.replace("</manifest>", block + "</manifest>", 1))
    print("source manifest: added hidl.manager")
print(p.read_text())
PY

# --- 2) Staged vendor manifest: add same HAL (fast path, no full rebuild) ---
ST_MAN=$STAGE/vendor/etc/vintf/manifest.xml
cp -a "$ST_MAN" "$ST_MAN.bak.p2dev.$(date +%H%M%S)"
python3 - <<'PY'
from pathlib import Path
p = Path.home() / "releases/Baklava64/system/vendor/etc/vintf/manifest.xml"
t = p.read_text()
block = '''    <hal format="hidl">
        <!-- Phase2 P0 formal: device-side IServiceManager (see device/generic/common/manifest.xml) -->
        <name>android.hidl.manager</name>
        <transport>hwbinder</transport>
        <fqname>@1.0::IServiceManager/default</fqname>
    </hal>
'''
if "android.hidl.manager" in t:
    print("staged vendor manifest already has hidl.manager")
else:
    # insert before </manifest> or before <sepolicy>
    if "<sepolicy>" in t:
        t = t.replace("<sepolicy>", block + "    <sepolicy>", 1)
    else:
        t = t.replace("</manifest>", block + "</manifest>", 1)
    p.write_text(t)
    print("staged vendor manifest: added hidl.manager")
print(p.read_text())
PY

# --- 3) Remove DIAG from service.cpp ---
python3 - <<'PY'
from pathlib import Path
p = Path.home() / "aosp16/system/hwservicemanager/service.cpp"
t = p.read_text()
# Match current DIAG block (cont.9 restore text)
import re
pat = re.compile(
    r'    auto transport = android::hardware::getTransport\(ServiceManager::descriptor, serviceName\);\n'
    r'    ALOGI\("A16DBG:HWSM.*?\n'
    r'    if \(false\).*?\{\n'
    r'        ALOGI\("A16DBG:HWSM-DIAG-BYPASS.*?\n'
    r'        ALOGI\("HIDL is not supported on this device so hwservicemanager is not needed"\);',
    re.S,
)
new = '''    auto transport = android::hardware::getTransport(ServiceManager::descriptor, serviceName);
    ALOGI("A16DBG:HWSM transport=%d (Phase2 device-side hidl.manager; expect non-EMPTY)", (int)transport);
    if (transport == android::vintf::Transport::EMPTY) {
        ALOGI("A16DBG:HWSM-EMPTY transport==EMPTY -> disabling hwservicemanager");
        ALOGI("HIDL is not supported on this device so hwservicemanager is not needed");'''
m = pat.search(t)
if not m:
    if "Phase2 device-side hidl.manager" in t and "transport == android::vintf::Transport::EMPTY" in t:
        print("service.cpp already formal (device-side path)")
    else:
        # show context for debug
        for i, line in enumerate(t.splitlines(), 1):
            if 145 <= i <= 160:
                print(f"{i}:{line}")
        raise SystemExit("DIAG pattern not found")
else:
    t2 = pat.sub(new, t, count=1)
    p.write_text(t2)
    print("service.cpp DIAG removed")
# verify
for i, line in enumerate(p.read_text().splitlines(), 1):
    if 148 <= i <= 158:
        print(f"{i}:{line}")
PY

# --- 4) Rebuild hwservicemanager ---
cd "$AOSP"
set +u
export OEM=nxt IMAGE=Baklava64 OUT_DIR=out_nxt_Baklava64 IS_64_BUILD=1
export APP_PLAYER_DIR=$HOME/app-player HD_SOURCE_TOP=$HOME/app-player/hd
export ALLOW_MISSING_DEPENDENCIES=true BST_BUILD_WITH_DEXPREOPT=true USE_OPENGL_RENDERER=true
source build/envsetup.sh
lunch bst_x86_64-trunk_staging-eng
set -u
touch system/hwservicemanager/service.cpp
mmm system/hwservicemanager -j24
echo "mmm_rc=$?"

HWSM=$AOSP/out_nxt_Baklava64/target/product/qvirt/system/bin/hwservicemanager
cp -av "$HWSM" "$STAGE/bin/hwservicemanager"
md5sum "$HWSM" "$STAGE/bin/hwservicemanager"
strings "$STAGE/bin/hwservicemanager" | grep -E 'A16DBG:HWSM|DIAG|HWSM-EMPTY|device-side' | head -10
grep -n 'hidl.manager' "$STAGE/vendor/etc/vintf/manifest.xml"

echo "A16DBG:P2: device-hidl-manager prep DONE $(date -Is) log=$LOG"
